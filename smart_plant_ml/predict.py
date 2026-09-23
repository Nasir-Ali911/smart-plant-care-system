import argparse
import json
import math
from pathlib import Path

import joblib
import pandas as pd

import firebase_admin
from firebase_admin import credentials, db


# ============================================================
# PATHS / FIREBASE CONFIGURATION
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

MODEL_PATH = (
    BASE_DIR
    / "model"
    / "smart_plant_soil_forecasting_model.joblib"
)

# Render Secret File:
#   /etc/secrets/firebase-service-account.json
#
# Local development:
#   smart_plant_ml/firebase-service-account.json
#
# The local credential file must NOT be committed to GitHub.
RENDER_SERVICE_ACCOUNT_PATH = Path(
    "/etc/secrets/firebase-service-account.json"
)

LOCAL_SERVICE_ACCOUNT_PATH = (
    BASE_DIR
    / "firebase-service-account.json"
)

if RENDER_SERVICE_ACCOUNT_PATH.exists():
    SERVICE_ACCOUNT_PATH = RENDER_SERVICE_ACCOUNT_PATH
else:
    SERVICE_ACCOUNT_PATH = LOCAL_SERVICE_ACCOUNT_PATH


DATABASE_URL = (
    "https://smart-plant-care-fyp-2026-default-rtdb.firebaseio.com"
)


# ============================================================
# API OUTPUT CONFIGURATION
# ============================================================

API_OUTPUT_PATH = (
    BASE_DIR
    / "ml_output.json"
)


# ============================================================
# TIMESTAMP HELPERS
# ============================================================

def parse_timestamp(value):
    """Convert Firebase timestamp formats to pandas Timestamp."""

    if value is None:
        return pd.Timestamp.now()

    if isinstance(value, (int, float)):

        if value < 10_000_000_000:
            return pd.to_datetime(
                value,
                unit="s",
            )

        return pd.to_datetime(
            value,
            unit="ms",
        )

    parsed = pd.to_datetime(
        value,
        errors="coerce",
    )

    if pd.isna(parsed):

        raise ValueError(
            f"Invalid timestamp: {value}"
        )

    return parsed


# ============================================================
# NUMERIC CONVERSION
# ============================================================

def to_float(value, field_name):
    """Convert a Firebase value to float."""

    try:

        return float(value)

    except (TypeError, ValueError):

        raise ValueError(
            f"Invalid value for {field_name}: {value}"
        )


# ============================================================
# SOIL STATE
# ============================================================

def normalize_soil_state(value):
    """
    Model convention:

        0 = WET
        1 = DRY
    """

    text = str(value).strip().upper()

    if "DRY" in text:
        return 1

    if (
        "WET" in text
        or "MOIST" in text
        or "NORMAL" in text
    ):
        return 0

    if text in {"0", "1"}:
        return int(text)

    raise ValueError(
        f"Cannot determine soil state from: {value}"
    )


# ============================================================
# SENSOR RECORD VALIDATION
# ============================================================

def is_valid_sensor_record(record):
    """Check whether a Firebase log contains required fields."""

    if not isinstance(record, dict):
        return False

    required = [
        "Timestamp",
        "Temperature",
        "Humidity",
        "LightIntensity",
        "SoilMoistureRaw",
        "SoilStatus",
    ]

    if any(
        record.get(field) is None
        for field in required
    ):
        return False

    try:

        temperature = float(
            record["Temperature"]
        )

        humidity = float(
            record["Humidity"]
        )

        light = float(
            record["LightIntensity"]
        )

        soil = float(
            record["SoilMoistureRaw"]
        )

        normalize_soil_state(
            record["SoilStatus"]
        )

        # Reject invalid zero temperature/humidity pair.
        if temperature == 0 and humidity == 0:
            return False

        # Model uses binary soil values.
        if soil not in (0, 1):
            return False

        timestamp = parse_timestamp(
            record["Timestamp"]
        )

        # Reject malformed historical records.
        if timestamp.year < 2026:
            return False

    except (TypeError, ValueError):
        return False

    return True


# ============================================================
# LOAD LOGS FROM EXPORTED JSON
# ============================================================

def load_valid_logs(path):
    """Load and chronologically sort valid Firebase logs."""

    with open(
        path,
        "r",
        encoding="utf-8-sig",
    ) as f:

        data = json.load(f)

    logs = data["SmartPlant"]["Logs"]

    valid = [
        record
        for record in logs.values()
        if is_valid_sensor_record(record)
    ]

    valid.sort(
        key=lambda record:
        parse_timestamp(
            record["Timestamp"]
        )
    )

    if not valid:

        raise ValueError(
            "No valid sensor records found."
        )

    return valid


# ============================================================
# LOAD LIVE LOGS FROM FIREBASE
# ============================================================

def load_live_logs():
    """
    Load sensor history directly from Firebase
    Realtime Database.

    Data source:

        /SmartPlant/Logs

    Historical logs are required because the model uses:

        TemperatureChange
        HumidityChange
        LightChange
        IntervalMin
        DryDurationHours
    """

    print()
    print("Connecting to Firebase...")

    if not SERVICE_ACCOUNT_PATH.exists():

        raise FileNotFoundError(
            "Firebase service-account file not found:\n"
            f"{SERVICE_ACCOUNT_PATH}"
        )

    print(
        f"Using Firebase credentials from: "
        f"{SERVICE_ACCOUNT_PATH}"
    )

    # Initialize Firebase only once.
    if not firebase_admin._apps:

        cred = credentials.Certificate(
            str(SERVICE_ACCOUNT_PATH)
        )

        firebase_admin.initialize_app(
            cred,
            {
                "databaseURL": DATABASE_URL,
            },
        )

    # Read complete sensor history.
    data = db.reference(
        "/SmartPlant/Logs"
    ).get()

    if not data:

        raise ValueError(
            "No sensor logs found at "
            "/SmartPlant/Logs."
        )

    if not isinstance(data, dict):

        raise ValueError(
            "Unexpected Firebase format at "
            "/SmartPlant/Logs."
        )

    valid = [
        record
        for record in data.values()
        if is_valid_sensor_record(record)
    ]

    valid.sort(
        key=lambda record:
        parse_timestamp(
            record["Timestamp"]
        )
    )

    if not valid:

        raise ValueError(
            "Firebase contains no valid "
            "sensor records."
        )

    print(
        f"Firebase connected. "
        f"Valid logs loaded: {len(valid)}"
    )

    return valid


# ============================================================
# DRY DURATION
# ============================================================

def calculate_dry_duration_hours(
    logs,
    current_index,
):
    """
    Calculate how long the plant has continuously
    remained DRY.

    Walk backward from the current record until
    the soil changes from DRY to WET.
    """

    current = logs[current_index]

    current_state = normalize_soil_state(
        current["SoilStatus"]
    )

    # If current state is WET, dry duration is zero.
    if current_state != 1:
        return 0.0

    current_time = parse_timestamp(
        current["Timestamp"]
    )

    start_time = current_time

    for index in range(
        current_index - 1,
        -1,
        -1,
    ):

        record = logs[index]

        state = normalize_soil_state(
            record["SoilStatus"]
        )

        timestamp = parse_timestamp(
            record["Timestamp"]
        )

        if state != 1:
            break

        start_time = timestamp

    duration_hours = (
        current_time - start_time
    ).total_seconds() / 3600.0

    return max(
        0.0,
        duration_hours,
    )


# ============================================================
# FEATURE CONSTRUCTION
# ============================================================

def build_features(
    logs,
    current_index,
):
    """
    Build the exact model features from Firebase history.
    """

    current = logs[current_index]

    current_time = parse_timestamp(
        current["Timestamp"]
    )

    temperature = to_float(
        current["Temperature"],
        "Temperature",
    )

    humidity = to_float(
        current["Humidity"],
        "Humidity",
    )

    light = to_float(
        current["LightIntensity"],
        "LightIntensity",
    )

    soil_state = normalize_soil_state(
        current["SoilStatus"]
    )

    # --------------------------------------------------------
    # Time-of-day features
    # --------------------------------------------------------

    hour = (
        current_time.hour
        + current_time.minute / 60.0
        + current_time.second / 3600.0
    )

    hour_sin = math.sin(
        2 * math.pi * hour / 24
    )

    hour_cos = math.cos(
        2 * math.pi * hour / 24
    )

    # --------------------------------------------------------
    # Default change features
    # --------------------------------------------------------

    temperature_change = 0.0
    humidity_change = 0.0
    light_change = 0.0
    interval_min = 1.0

    # --------------------------------------------------------
    # Previous valid sensor reading
    # --------------------------------------------------------

    if current_index > 0:

        previous = logs[
            current_index - 1
        ]

        previous_time = parse_timestamp(
            previous["Timestamp"]
        )

        previous_temperature = to_float(
            previous["Temperature"],
            "PreviousTemperature",
        )

        previous_humidity = to_float(
            previous["Humidity"],
            "PreviousHumidity",
        )

        previous_light = to_float(
            previous["LightIntensity"],
            "PreviousLightIntensity",
        )

        temperature_change = (
            temperature
            - previous_temperature
        )

        humidity_change = (
            humidity
            - previous_humidity
        )

        light_change = (
            light
            - previous_light
        )

        interval_min = (
            current_time
            - previous_time
        ).total_seconds() / 60.0

    # --------------------------------------------------------
    # Continuous dry duration
    # --------------------------------------------------------

    dry_duration_hours = (
        calculate_dry_duration_hours(
            logs,
            current_index,
        )
    )

    # --------------------------------------------------------
    # Exact trained feature set
    # --------------------------------------------------------

    features = {
        "Temperature": temperature,
        "Humidity": humidity,
        "LightIntensity": light,
        "CurrentSoilState": soil_state,
        "HourSin": hour_sin,
        "HourCos": hour_cos,
        "TemperatureChange": temperature_change,
        "HumidityChange": humidity_change,
        "LightChange": light_change,
        "IntervalMin": interval_min,
        "DryDurationHours": dry_duration_hours,
    }

    return (
        pd.DataFrame([features]),
        features,
    )


# ============================================================
# MODEL PREDICTION
# ============================================================

def predict_from_logs(logs):
    """
    Run prediction using the latest valid sensor record.
    """

    if not MODEL_PATH.exists():

        raise FileNotFoundError(
            f"Model not found:\n"
            f"{MODEL_PATH}\n\n"
            "Run train_model.py first."
        )

    # --------------------------------------------------------
    # Load model
    # --------------------------------------------------------

    bundle = joblib.load(
        MODEL_PATH
    )

    if not isinstance(bundle, dict):

        model = bundle
        expected_features = None

    else:

        model = bundle.get(
            "model"
        )

        if model is None:

            raise ValueError(
                "Model bundle does not "
                "contain 'model'."
            )

        expected_features = (
            bundle.get(
                "feature_columns"
            )
        )

    # --------------------------------------------------------
    # Latest sensor record
    # --------------------------------------------------------

    current_index = (
        len(logs) - 1
    )

    features, feature_values = (
        build_features(
            logs,
            current_index,
        )
    )

    # --------------------------------------------------------
    # Match trained feature order
    # --------------------------------------------------------

    if expected_features:

        missing = [
            feature
            for feature in expected_features
            if feature not in features.columns
        ]

        if missing:

            raise ValueError(
                f"Missing model features: "
                f"{missing}"
            )

        features = features[
            expected_features
        ]

    # --------------------------------------------------------
    # Probability prediction
    # --------------------------------------------------------

    probabilities = (
        model.predict_proba(
            features
        )[0]
    )

    classes = list(
        model.classes_
    )

    if 1 in classes:

        dry_index = classes.index(
            1
        )

        dry_probability = float(
            probabilities[
                dry_index
            ]
        )

    else:

        dry_probability = 0.0

    # --------------------------------------------------------
    # Current soil
    # --------------------------------------------------------

    current = logs[
        current_index
    ]

    current_soil = (
        "DRY"
        if normalize_soil_state(
            current["SoilStatus"]
        ) == 1
        else "WET"
    )

    # --------------------------------------------------------
    # Forecast
    # --------------------------------------------------------

    forecast = (
        "DRY"
        if dry_probability >= 0.50
        else "WET"
    )

    # --------------------------------------------------------
    # Result
    # --------------------------------------------------------

    result = {

        "current_soil": current_soil,

        "future_dry_probability": round(
            dry_probability,
            4,
        ),

        "future_wet_probability": round(
            1.0 - dry_probability,
            4,
        ),

        "forecast": forecast,

        "forecast_horizon_minutes": 15,

        "model": "Random Forest",

        "timestamp": str(
            current["Timestamp"]
        ),

        "features": feature_values,
    }

    return result


# ============================================================
# API / FLUTTER JSON OUTPUT
# ============================================================

def create_api_output(result):
    """
    Convert the ML prediction result into a stable
    JSON structure for the Flutter application.

    IMPORTANT:
        AI recommendation does NOT activate the pump.
    """

    dry_probability = float(
        result["future_dry_probability"]
    )

    wet_probability = float(
        result["future_wet_probability"]
    )

    # --------------------------------------------------------
    # AI recommendation
    # --------------------------------------------------------

    if dry_probability >= 0.70:

        recommendation = (
            "Watering may be required soon."
        )

    elif dry_probability >= 0.50:

        recommendation = (
            "Monitor soil moisture. "
            "Watering may be required."
        )

    else:

        recommendation = (
            "Soil moisture is expected "
            "to remain adequate."
        )

    # --------------------------------------------------------
    # Stable API structure
    # --------------------------------------------------------

    api_result = {

        "success": True,

        "timestamp": result["timestamp"],

        "current": {
            "soil_status": result["current_soil"]
        },

        "forecast": {
            "soil_status": result["forecast"],
            "dry_probability": dry_probability,
            "wet_probability": wet_probability,
            "horizon_minutes": result[
                "forecast_horizon_minutes"
            ]
        },

        "recommendation": {
            "message": recommendation,

            # AI recommendation NEVER directly
            # activates the physical pump.
            "pump_activation": False
        },

        "model": result["model"],

        "features": result["features"]
    }

    return api_result


# ============================================================
# SAVE API JSON
# ============================================================

def save_api_output(api_result):
    """
    Save the stable ML output to ml_output.json.
    """

    with open(
        API_OUTPUT_PATH,
        "w",
        encoding="utf-8",
    ) as f:

        json.dump(
            api_result,
            f,
            indent=2,
        )

    return API_OUTPUT_PATH


# ============================================================
# MAIN
# ============================================================

def main():

    parser = argparse.ArgumentParser(
        description=(
            "Smart Plant Care ML "
            "soil-state forecasting"
        )
    )

    # --------------------------------------------------------
    # Offline Firebase export
    # --------------------------------------------------------

    parser.add_argument(
        "--export",
        type=str,
        help=(
            "Firebase RTDB export JSON. "
            "Uses latest valid sensor record."
        ),
    )

    # --------------------------------------------------------
    # Single sensor record
    # --------------------------------------------------------

    parser.add_argument(
        "--file",
        type=str,
        help=(
            "Single Firebase sensor record "
            "JSON file."
        ),
    )

    # --------------------------------------------------------
    # LIVE Firebase mode
    # --------------------------------------------------------

    parser.add_argument(
        "--live",
        action="store_true",
        help=(
            "Read sensor history directly "
            "from Firebase Realtime Database."
        ),
    )

    args = parser.parse_args()

    # --------------------------------------------------------
    # Validate arguments
    # --------------------------------------------------------

    if (
        not args.export
        and not args.file
        and not args.live
    ):

        parser.error(
            "Provide either "
            "--export, --file, or --live."
        )

    # --------------------------------------------------------
    # Load data
    # --------------------------------------------------------

    if args.live:

        logs = load_live_logs()

    elif args.export:

        logs = load_valid_logs(
            args.export
        )

    else:

        with open(
            args.file,
            "r",
            encoding="utf-8-sig",
        ) as f:

            record = json.load(f)

        if not is_valid_sensor_record(
            record
        ):

            raise ValueError(
                "The supplied sensor "
                "record is not valid."
            )

        logs = [record]

    # --------------------------------------------------------
    # Run prediction
    # --------------------------------------------------------

    result = predict_from_logs(
        logs
    )

    # --------------------------------------------------------
    # Console output
    # --------------------------------------------------------

    print()

    if args.live:

        print(
            "SMART PLANT CARE - "
            "LIVE ML FORECAST"
        )

    else:

        print(
            "SMART PLANT CARE - "
            "ML FORECAST"
        )

    print(
        "--------------------------------"
    )

    print(
        f"Timestamp: "
        f"{result['timestamp']}"
    )

    print(
        f"Current Soil: "
        f"{result['current_soil']}"
    )

    print(
        f"Future Dry Probability: "
        f"{result['future_dry_probability']:.4f}"
    )

    print(
        f"Future Wet Probability: "
        f"{result['future_wet_probability']:.4f}"
    )

    print(
        f"Forecast: "
        f"{result['forecast']}"
    )

    print(
        "Forecast Horizon: "
        f"~{result['forecast_horizon_minutes']} "
        "minutes"
    )

    print(
        f"Model: "
        f"{result['model']}"
    )

    # --------------------------------------------------------
    # Features
    # --------------------------------------------------------

    print()

    print(
        "MODEL FEATURES"
    )

    print(
        "----------------"
    )

    for name, value in (
        result["features"].items()
    ):

        print(
            f"{name}: {value}"
        )

    # --------------------------------------------------------
    # Original JSON result
    # --------------------------------------------------------

    print()

    print(
        "JSON RESULT:"
    )

    print(
        json.dumps(
            result,
            indent=2,
        )
    )

    # --------------------------------------------------------
    # Create stable API result
    # --------------------------------------------------------

    api_result = create_api_output(
        result
    )

    # --------------------------------------------------------
    # Save API JSON
    # --------------------------------------------------------

    output_path = save_api_output(
        api_result
    )

    # --------------------------------------------------------
    # Display API result
    # --------------------------------------------------------

    print()

    print(
        "API JSON RESULT:"
    )

    print(
        json.dumps(
            api_result,
            indent=2,
        )
    )

    print()

    print(
        f"API JSON saved to: "
        f"{output_path}"
    )


# ============================================================
# ENTRY POINT
# ============================================================

if __name__ == "__main__":
    main()