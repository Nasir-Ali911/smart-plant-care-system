import json
import math
from pathlib import Path
from datetime import datetime, timedelta

import joblib
import numpy as np
import pandas as pd

from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    confusion_matrix,
    classification_report,
)


# ============================================================
# CONFIGURATION
# ============================================================

DATA_FILE = Path("data/firebase_export.json")
MODEL_DIR = Path("model")

MODEL_FILE = (
    MODEL_DIR /
    "smart_plant_soil_forecasting_model.joblib"
)

TARGET_MINUTES = 15
TARGET_TOLERANCE_MINUTES = 3

MIN_GAP_SECONDS = 1
MAX_GAP_SECONDS = 300

TRAIN_RATIO = 0.70
VALIDATION_RATIO = 0.15
TEST_RATIO = 0.15

RANDOM_STATE = 42


print("=" * 75)
print("SMART PLANT CARE — ML MODEL TRAINING")
print("=" * 75)


# ============================================================
# LOAD FIREBASE DATA
# ============================================================

print("\nLoading Firebase dataset...")

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)


logs = data["SmartPlant"]["Logs"]


# ============================================================
# TIMESTAMP PARSER
# ============================================================

def parse_timestamp(value):

    if not isinstance(value, str):
        return None

    try:
        return datetime.strptime(
            value,
            "%Y-%m-%d %H:%M:%S"
        )

    except ValueError:
        return None


# ============================================================
# LOAD AND CLEAN SENSOR RECORDS
# ============================================================

records = []


for key, log in logs.items():

    if not isinstance(log, dict):
        continue


    timestamp = parse_timestamp(
        log.get("Timestamp")
    )


    if timestamp is None:
        continue


    temperature = log.get("Temperature")
    humidity = log.get("Humidity")
    light = log.get("LightIntensity")
    soil = log.get("SoilMoistureRaw")


    # --------------------------------------------------------
    # Required numeric fields
    # --------------------------------------------------------

    if not isinstance(
        temperature,
        (int, float)
    ):
        continue


    if not isinstance(
        humidity,
        (int, float)
    ):
        continue


    if not isinstance(
        light,
        (int, float)
    ):
        continue


    if soil not in (0, 1):
        continue


    # --------------------------------------------------------
    # Remove known sensor failure
    # --------------------------------------------------------

    if temperature == 0 and humidity == 0:
        continue


    records.append({
        "timestamp": timestamp,
        "temperature": float(temperature),
        "humidity": float(humidity),
        "light": float(light),
        "soil": int(soil),
    })


# ============================================================
# SORT CHRONOLOGICALLY
# ============================================================

records.sort(
    key=lambda x: x["timestamp"]
)


print(
    f"Clean sensor records: {len(records):,}"
)


# ============================================================
# BUILD HISTORICAL FEATURES
# ============================================================

print("\nBuilding historical features...")


feature_records = []


previous = None

current_dry_start = None


for record in records:

    timestamp = record["timestamp"]


    # --------------------------------------------------------
    # Sampling interval
    # --------------------------------------------------------

    if previous is None:

        interval_min = 0.0

        temperature_change = 0.0
        humidity_change = 0.0
        light_change = 0.0

    else:

        interval_seconds = (
            timestamp -
            previous["timestamp"]
        ).total_seconds()


        if (
            interval_seconds < MIN_GAP_SECONDS
            or interval_seconds > MAX_GAP_SECONDS
        ):

            interval_min = 0.0

            temperature_change = 0.0
            humidity_change = 0.0
            light_change = 0.0

        else:

            interval_min = (
                interval_seconds / 60.0
            )

            temperature_change = (
                record["temperature"] -
                previous["temperature"]
            )

            humidity_change = (
                record["humidity"] -
                previous["humidity"]
            )

            light_change = (
                record["light"] -
                previous["light"]
            )


    # --------------------------------------------------------
    # Dry duration
    # --------------------------------------------------------

    if record["soil"] == 1:

        if (
            current_dry_start is None
            or previous is None
        ):

            current_dry_start = timestamp

        else:

            gap = (
                timestamp -
                previous["timestamp"]
            ).total_seconds()

            if gap > MAX_GAP_SECONDS:

                current_dry_start = timestamp

    else:

        current_dry_start = None


    if (
        record["soil"] == 1
        and current_dry_start is not None
    ):

        dry_duration_hours = (
            timestamp -
            current_dry_start
        ).total_seconds() / 3600.0

    else:

        dry_duration_hours = 0.0


    # --------------------------------------------------------
    # Time-of-day cyclic features
    # --------------------------------------------------------

    hour_decimal = (
        timestamp.hour
        + timestamp.minute / 60.0
        + timestamp.second / 3600.0
    )


    angle = (
        2.0 *
        math.pi *
        hour_decimal /
        24.0
    )


    hour_sin = math.sin(angle)
    hour_cos = math.cos(angle)


    feature_records.append({

        "timestamp": timestamp,

        "Temperature":
            record["temperature"],

        "Humidity":
            record["humidity"],

        "LightIntensity":
            record["light"],

        "CurrentSoilState":
            record["soil"],

        "HourSin":
            hour_sin,

        "HourCos":
            hour_cos,

        "TemperatureChange":
            temperature_change,

        "HumidityChange":
            humidity_change,

        "LightChange":
            light_change,

        "IntervalMin":
            interval_min,

        "DryDurationHours":
            dry_duration_hours,
    })


    previous = record


# ============================================================
# CREATE FUTURE TARGET
# ============================================================

print("Building 15-minute future targets...")


target_delta = timedelta(
    minutes=TARGET_MINUTES
)

minimum_delta = timedelta(
    minutes=(
        TARGET_MINUTES -
        TARGET_TOLERANCE_MINUTES
    )
)

maximum_delta = timedelta(
    minutes=(
        TARGET_MINUTES +
        TARGET_TOLERANCE_MINUTES
    )
)


samples = []


for i, current in enumerate(
    feature_records
):

    current_time = current["timestamp"]

    target_time = (
        current_time +
        target_delta
    )


    best_future = None
    best_difference = None


    for j in range(
        i + 1,
        len(feature_records)
    ):

        future = feature_records[j]


        difference = (
            future["timestamp"] -
            current_time
        )


        if difference < minimum_delta:
            continue


        if difference > maximum_delta:
            break


        # ----------------------------------------------------
        # Check that the future observation is not separated
        # by a large data gap.
        # ----------------------------------------------------

        previous_future = (
            feature_records[j - 1]
        )


        future_gap = (
            future["timestamp"] -
            previous_future["timestamp"]
        ).total_seconds()


        if future_gap > MAX_GAP_SECONDS:
            continue


        difference_from_target = abs(
            difference.total_seconds()
            - target_delta.total_seconds()
        )


        if (
            best_difference is None
            or
            difference_from_target
            < best_difference
        ):

            best_difference = (
                difference_from_target
            )

            best_future = future


    if best_future is None:
        continue


    sample = current.copy()


    sample["FutureSoilState"] = (
        best_future["CurrentSoilState"]
    )


    sample["FutureTimestamp"] = (
        best_future["timestamp"]
    )


    samples.append(sample)


# ============================================================
# DATAFRAME
# ============================================================

df = pd.DataFrame(samples)


print(
    f"\nUsable ML samples: {len(df):,}"
)


# ============================================================
# FEATURE COLUMNS
# ============================================================

FEATURE_COLUMNS = [

    "Temperature",

    "Humidity",

    "LightIntensity",

    "CurrentSoilState",

    "HourSin",

    "HourCos",

    "TemperatureChange",

    "HumidityChange",

    "LightChange",

    "IntervalMin",

    "DryDurationHours",
]


TARGET_COLUMN = "FutureSoilState"


# ============================================================
# REMOVE FIRST ROW / INVALID FEATURES
# ============================================================

df = df.dropna(
    subset=
        FEATURE_COLUMNS
        + [TARGET_COLUMN]
).copy()


df = df.sort_values(
    "timestamp"
).reset_index(
    drop=True
)


print(
    f"Final ML samples: {len(df):,}"
)


# ============================================================
# CHRONOLOGICAL SPLIT
# ============================================================

n = len(df)


train_end = int(
    n * TRAIN_RATIO
)

validation_end = int(
    n *
    (
        TRAIN_RATIO +
        VALIDATION_RATIO
    )
)


train_df = df.iloc[
    :train_end
].copy()


validation_df = df.iloc[
    train_end:validation_end
].copy()


test_df = df.iloc[
    validation_end:
].copy()


print("\n" + "=" * 75)
print("CHRONOLOGICAL SPLIT")
print("=" * 75)


print(
    f"\nTraining samples   : "
    f"{len(train_df):,}"
)

print(
    f"Validation samples : "
    f"{len(validation_df):,}"
)

print(
    f"Testing samples    : "
    f"{len(test_df):,}"
)


print(
    f"\nTraining period:")
print(
    f"  {train_df['timestamp'].min()}"
)
print(
    f"  → {train_df['timestamp'].max()}"
)


print(
    f"\nValidation period:"
)
print(
    f"  {validation_df['timestamp'].min()}"
)
print(
    f"  → {validation_df['timestamp'].max()}"
)


print(
    f"\nTesting period:"
)
print(
    f"  {test_df['timestamp'].min()}"
)
print(
    f"  → {test_df['timestamp'].max()}"
)


# ============================================================
# CLASS DISTRIBUTION
# ============================================================

print("\n" + "=" * 75)
print("CLASS DISTRIBUTION")
print("=" * 75)


for name, subset in [
    ("TRAIN", train_df),
    ("VALIDATION", validation_df),
    ("TEST", test_df),
]:

    counts = (
        subset[TARGET_COLUMN]
        .value_counts()
        .sort_index()
    )


    wet = counts.get(
        0,
        0
    )

    dry = counts.get(
        1,
        0
    )


    print(
        f"\n{name}"
    )

    print(
        f"  Future WET : {wet:,}"
    )

    print(
        f"  Future DRY : {dry:,}"
    )


# ============================================================
# PREPARE MATRICES
# ============================================================

X_train = train_df[
    FEATURE_COLUMNS
]

y_train = train_df[
    TARGET_COLUMN
]


X_validation = validation_df[
    FEATURE_COLUMNS
]

y_validation = validation_df[
    TARGET_COLUMN
]


X_test = test_df[
    FEATURE_COLUMNS
]

y_test = test_df[
    TARGET_COLUMN
]


# ============================================================
# MODEL
# ============================================================

print("\n" + "=" * 75)
print("TRAINING RANDOM FOREST")
print("=" * 75)


model = RandomForestClassifier(

    n_estimators=300,

    max_depth=10,

    min_samples_leaf=5,

    class_weight="balanced",

    random_state=RANDOM_STATE,

    n_jobs=-1,
)


model.fit(
    X_train,
    y_train
)


print(
    "\nModel training complete."
)


# ============================================================
# EVALUATION FUNCTION
# ============================================================

def evaluate_model(
    model,
    X,
    y,
    name
):

    predictions = model.predict(X)

    probabilities = (
        model.predict_proba(X)[:, 1]
    )


    print(
        "\n" + "-" * 75
    )

    print(
        f"{name} RESULTS"
    )

    print(
        "-" * 75
    )


    accuracy = accuracy_score(
        y,
        predictions
    )


    precision = precision_score(
        y,
        predictions,
        zero_division=0
    )


    recall = recall_score(
        y,
        predictions,
        zero_division=0
    )


    f1 = f1_score(
        y,
        predictions,
        zero_division=0
    )


    print(
        f"Accuracy  : {accuracy:.4f}"
    )

    print(
        f"Precision : {precision:.4f}"
    )

    print(
        f"Recall    : {recall:.4f}"
    )

    print(
        f"F1 Score  : {f1:.4f}"
    )


    if len(
        np.unique(y)
    ) == 2:

        roc_auc = roc_auc_score(
            y,
            probabilities
        )

        print(
            f"ROC-AUC   : {roc_auc:.4f}"
        )

    else:

        roc_auc = None

        print(
            "ROC-AUC   : unavailable "
            "(only one class)"
        )


    print(
        "\nConfusion Matrix:"
    )

    print(
        confusion_matrix(
            y,
            predictions
        )
    )


    print(
        "\nClassification Report:"
    )

    print(
        classification_report(
            y,
            predictions,
            target_names=[
                "WET",
                "DRY"
            ],
            zero_division=0
        )
    )


    return {
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "f1": f1,
        "roc_auc": roc_auc,
    }


# ============================================================
# VALIDATION
# ============================================================

validation_metrics = evaluate_model(

    model,

    X_validation,

    y_validation,

    "VALIDATION"
)


# ============================================================
# TEST
# ============================================================

test_metrics = evaluate_model(

    model,

    X_test,

    y_test,

    "TEST"
)


# ============================================================
# PERSISTENCE BASELINE
# ============================================================

print("\n" + "=" * 75)
print("PERSISTENCE BASELINE")
print("=" * 75)


baseline_predictions = (
    X_test["CurrentSoilState"]
    .astype(int)
    .values
)


baseline_accuracy = accuracy_score(
    y_test,
    baseline_predictions
)


baseline_precision = precision_score(
    y_test,
    baseline_predictions,
    zero_division=0
)


baseline_recall = recall_score(
    y_test,
    baseline_predictions,
    zero_division=0
)


baseline_f1 = f1_score(
    y_test,
    baseline_predictions,
    zero_division=0
)


print(
    f"\nBaseline Accuracy  : "
    f"{baseline_accuracy:.4f}"
)

print(
    f"Baseline Precision : "
    f"{baseline_precision:.4f}"
)

print(
    f"Baseline Recall    : "
    f"{baseline_recall:.4f}"
)

print(
    f"Baseline F1        : "
    f"{baseline_f1:.4f}"
)


# ============================================================
# FEATURE IMPORTANCE
# ============================================================

print("\n" + "=" * 75)
print("FEATURE IMPORTANCE")
print("=" * 75)


importance = pd.Series(

    model.feature_importances_,

    index=FEATURE_COLUMNS

).sort_values(
    ascending=False
)


for feature, value in importance.items():

    print(
        f"{feature:25s} "
        f"{value:.4f}"
    )


# ============================================================
# SAVE MODEL BUNDLE
# ============================================================

MODEL_DIR.mkdir(
    parents=True,
    exist_ok=True
)


model_bundle = {

    "model": model,

    "feature_columns":
        FEATURE_COLUMNS,

    "target":
        "FutureSoilState",

    "target_description":
        "Soil state approximately "
        "15 minutes in the future",

    "target_horizon_minutes":
        TARGET_MINUTES,

    "target_tolerance_minutes":
        TARGET_TOLERANCE_MINUTES,

    "random_state":
        RANDOM_STATE,

    "training_samples":
        len(train_df),

    "validation_samples":
        len(validation_df),

    "test_samples":
        len(test_df),

    "validation_metrics":
        validation_metrics,

    "test_metrics":
        test_metrics,

    "persistence_baseline": {

        "accuracy":
            baseline_accuracy,

        "precision":
            baseline_precision,

        "recall":
            baseline_recall,

        "f1":
            baseline_f1,
    },

    "trained_at":
        datetime.now().isoformat(),

    "data_first_timestamp":
        df["timestamp"].min().isoformat(),

    "data_last_timestamp":
        df["timestamp"].max().isoformat(),
}


joblib.dump(
    model_bundle,
    MODEL_FILE
)


print("\n" + "=" * 75)
print("MODEL SAVED")
print("=" * 75)


print(
    f"\nSaved to:"
)

print(
    MODEL_FILE
)


print("\n" + "=" * 75)
print("TRAINING COMPLETE")
print("=" * 75)