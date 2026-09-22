import json
import joblib
import numpy as np
import pandas as pd

from pathlib import Path
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    average_precision_score,
    confusion_matrix,
    brier_score_loss,
)


# ============================================================
# PATHS
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

DATA_FILE = BASE_DIR / "data" / "firebase_export.json"
MODEL_FILE = (
    BASE_DIR
    / "model"
    / "smart_plant_soil_forecasting_model.joblib"
)


# ============================================================
# SETTINGS
# ============================================================

FUTURE_MIN_MINUTES = 12
FUTURE_MAX_MINUTES = 18


# ============================================================
# LOAD DATA
# ============================================================

print("=" * 70)
print("SMART PLANT CARE - MODEL EVALUATION")
print("=" * 70)

print("\nLoading data...")

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

logs = data["SmartPlant"]["Logs"]

records = []

for key, value in logs.items():

    if not isinstance(value, dict):
        continue

    try:
        timestamp = pd.to_datetime(
            value.get("Timestamp"),
            errors="coerce"
        )

        temperature = float(value["Temperature"])
        humidity = float(value["Humidity"])
        light = float(value["LightIntensity"])
        soil_raw = float(value["SoilMoistureRaw"])

    except (TypeError, ValueError, KeyError):
        continue

    if pd.isna(timestamp):
        continue

    # Same invalid sensor filtering
    # used during model development.
    if temperature == 0 and humidity == 0:
        continue

    if pd.isna(soil_raw):
        continue

    # Firmware:
    # SoilMoistureRaw = 0 -> WET
    # SoilMoistureRaw = 1 -> DRY
    soil_state = 1 if soil_raw == 1 else 0

    records.append({
        "timestamp": timestamp,
        "Temperature": temperature,
        "Humidity": humidity,
        "LightIntensity": light,
        "CurrentSoilState": soil_state,
    })


df = pd.DataFrame(records)

df = (
    df
    .sort_values("timestamp")
    .reset_index(drop=True)
)

print(f"Clean records: {len(df):,}")


# ============================================================
# CREATE EXACT MODEL FEATURES
# ============================================================

# Time features
df["Hour"] = (
    df["timestamp"].dt.hour
    + df["timestamp"].dt.minute / 60
)

df["HourSin"] = np.sin(
    2 * np.pi * df["Hour"] / 24
)

df["HourCos"] = np.cos(
    2 * np.pi * df["Hour"] / 24
)


# Sensor changes
df["TemperatureChange"] = (
    df["Temperature"].diff().fillna(0)
)

df["HumidityChange"] = (
    df["Humidity"].diff().fillna(0)
)

df["LightChange"] = (
    df["LightIntensity"].diff().fillna(0)
)


# Sampling interval
df["IntervalMin"] = (
    df["timestamp"]
    .diff()
    .dt.total_seconds()
    / 60
).fillna(1)

df["IntervalMin"] = df[
    "IntervalMin"
].clip(
    lower=0,
    upper=60
)


# ============================================================
# DRY DURATION
# ============================================================

dry_duration = []

current_duration = 0.0

for i in range(len(df)):

    if df.loc[i, "CurrentSoilState"] == 1:

        current_duration += (
            df.loc[i, "IntervalMin"]
        )

    else:

        current_duration = 0.0

    dry_duration.append(
        current_duration
    )


df["DryDurationHours"] = (
    np.array(dry_duration) / 60.0
)


# ============================================================
# FUTURE 15-MINUTE TARGET
# ============================================================

future_target = []

for i in range(len(df)):

    current_time = df.loc[
        i,
        "timestamp"
    ]

    min_time = (
        current_time
        + pd.Timedelta(
            minutes=FUTURE_MIN_MINUTES
        )
    )

    max_time = (
        current_time
        + pd.Timedelta(
            minutes=FUTURE_MAX_MINUTES
        )
    )

    candidates = df[
        (df["timestamp"] >= min_time)
        &
        (df["timestamp"] <= max_time)
    ]

    if len(candidates) == 0:

        future_target.append(np.nan)

        continue

    target_time = (
        current_time
        + pd.Timedelta(minutes=15)
    )

    candidates = candidates.copy()

    candidates["distance"] = (
        candidates["timestamp"]
        - target_time
    ).abs()

    best_idx = (
        candidates["distance"]
        .idxmin()
    )

    future_target.append(
        df.loc[
            best_idx,
            "CurrentSoilState"
        ]
    )


df["FutureSoilState"] = future_target


# ============================================================
# BUILD ML DATASET
# ============================================================

feature_columns = [
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


ml_df = df.dropna(
    subset=["FutureSoilState"]
).copy()

X = ml_df[
    feature_columns
]

y = (
    ml_df["FutureSoilState"]
    .astype(int)
)


print(
    f"Usable prediction samples: "
    f"{len(ml_df):,}"
)

print("\nFuture target distribution:")

print(
    y.value_counts()
    .sort_index()
    .rename(
        index={
            0: "WET",
            1: "DRY"
        }
    )
)


# ============================================================
# LOAD MODEL
# ============================================================

print("\nLoading trained model...")

bundle = joblib.load(
    MODEL_FILE
)

print(
    "Model loaded from:"
)

print(MODEL_FILE)


if isinstance(bundle, dict):

    model = bundle["model"]

    saved_features = bundle.get(
        "features",
        bundle.get(
            "feature_columns",
            feature_columns
        )
    )

else:

    model = bundle

    saved_features = feature_columns


print("\nModel type:")

print(
    type(model).__name__
)


print("\nFeatures:")

for feature in saved_features:

    print(
        f"  - {feature}"
    )


# ============================================================
# FEATURE CHECK
# ============================================================

missing_features = [
    feature
    for feature in saved_features
    if feature not in ml_df.columns
]

if missing_features:

    raise ValueError(
        "Missing model features: "
        f"{missing_features}"
    )


X = ml_df[
    saved_features
]


# ============================================================
# MODEL PREDICTIONS
# ============================================================

probabilities = (
    model
    .predict_proba(X)[:, 1]
)

predictions_05 = (
    probabilities >= 0.50
).astype(int)


# ============================================================
# PERSISTENCE BASELINE
# ============================================================

# Baseline assumption:
#
# Current soil state remains the same
# 15 minutes into the future.

baseline_predictions = (
    ml_df["CurrentSoilState"]
    .astype(int)
    .values
)


# ============================================================
# EVALUATION FUNCTION
# ============================================================

def evaluate_predictions(
    name,
    y_true,
    predictions,
    probabilities=None
):

    print("\n" + "-" * 70)

    print(name)

    print("-" * 70)

    accuracy = accuracy_score(
        y_true,
        predictions
    )

    precision = precision_score(
        y_true,
        predictions,
        zero_division=0
    )

    recall = recall_score(
        y_true,
        predictions,
        zero_division=0
    )

    f1 = f1_score(
        y_true,
        predictions,
        zero_division=0
    )

    print(
        f"Accuracy : {accuracy:.4f}"
    )

    print(
        f"Precision: {precision:.4f}"
    )

    print(
        f"Recall   : {recall:.4f}"
    )

    print(
        f"F1 Score : {f1:.4f}"
    )

    print("\nConfusion Matrix:")

    print(
        confusion_matrix(
            y_true,
            predictions
        )
    )

    if probabilities is not None:

        try:

            auc = roc_auc_score(
                y_true,
                probabilities
            )

            print(
                f"\nROC-AUC  : {auc:.4f}"
            )

        except ValueError:

            print(
                "\nROC-AUC  : unavailable"
            )

        try:

            ap = average_precision_score(
                y_true,
                probabilities
            )

            print(
                f"PR-AUC   : {ap:.4f}"
            )

        except ValueError:

            print(
                "PR-AUC   : unavailable"
            )

        brier = brier_score_loss(
            y_true,
            probabilities
        )

        print(
            f"Brier    : {brier:.4f}"
        )


# ============================================================
# RANDOM FOREST
# ============================================================

evaluate_predictions(
    "RANDOM FOREST - 0.50 THRESHOLD",
    y,
    predictions_05,
    probabilities
)


# ============================================================
# PERSISTENCE BASELINE
# ============================================================

evaluate_predictions(
    "PERSISTENCE BASELINE",
    y,
    baseline_predictions,
    None
)


# ============================================================
# THRESHOLD ANALYSIS
# ============================================================

print("\n" + "=" * 70)

print("THRESHOLD ANALYSIS")

print("=" * 70)

print(
    "\nThreshold | Accuracy | Precision | Recall | F1"
)

best_f1 = -1
best_threshold = None

for threshold in np.arange(
    0.10,
    0.91,
    0.05
):

    preds = (
        probabilities >= threshold
    ).astype(int)

    acc = accuracy_score(
        y,
        preds
    )

    precision = precision_score(
        y,
        preds,
        zero_division=0
    )

    recall = recall_score(
        y,
        preds,
        zero_division=0
    )

    f1 = f1_score(
        y,
        preds,
        zero_division=0
    )

    print(
        f"{threshold:9.2f} | "
        f"{acc:8.4f} | "
        f"{precision:9.4f} | "
        f"{recall:6.4f} | "
        f"{f1:.4f}"
    )

    if f1 > best_f1:

        best_f1 = f1

        best_threshold = threshold


print(
    f"\nBest F1 threshold: "
    f"{best_threshold:.2f}"
)

print(
    f"Best F1: "
    f"{best_f1:.4f}"
)


# ============================================================
# MODEL VS BASELINE
# ============================================================

print("\n" + "=" * 70)

print("MODEL VS PERSISTENCE")

print("=" * 70)

model_accuracy = accuracy_score(
    y,
    predictions_05
)

baseline_accuracy = accuracy_score(
    y,
    baseline_predictions
)

print(
    f"Random Forest accuracy : "
    f"{model_accuracy:.4f}"
)

print(
    f"Persistence accuracy   : "
    f"{baseline_accuracy:.4f}"
)

print(
    f"Difference             : "
    f"{model_accuracy - baseline_accuracy:+.4f}"
)


# ============================================================
# CURRENT → FUTURE TRANSITIONS
# ============================================================

print("\n" + "=" * 70)

print(
    "CURRENT → FUTURE SOIL TRANSITIONS"
)

print("=" * 70)

transition_table = pd.crosstab(
    ml_df["CurrentSoilState"],
    ml_df["FutureSoilState"]
)

transition_table.index = [
    "Current WET",
    "Current DRY"
]

transition_table.columns = [
    "Future WET",
    "Future DRY"
]

print(
    transition_table
)

print(
    "\nTransition percentages:"
)

for current_state in [0, 1]:

    subset = ml_df[
        ml_df["CurrentSoilState"]
        == current_state
    ]

    if len(subset) == 0:

        continue

    rate = (
        subset["FutureSoilState"]
        == 1
    ).mean()

    current_name = (
        "WET"
        if current_state == 0
        else "DRY"
    )

    print(
        f"Current {current_name} "
        f"→ Future DRY: "
        f"{rate * 100:.2f}%"
    )


# ============================================================
# PROBABILITY SUMMARY
# ============================================================

print("\n" + "=" * 70)

print(
    "MODEL PROBABILITY SUMMARY"
)

print("=" * 70)

ml_df = ml_df.copy()

ml_df[
    "PredictedProbability"
] = probabilities

print(
    "\nProbability statistics:"
)

print(
    ml_df[
        "PredictedProbability"
    ]
    .describe()
    .to_string()
)

print(
    "\nProbability by actual future state:"
)

probability_summary = (
    ml_df
    .groupby("FutureSoilState")
    ["PredictedProbability"]
    .agg(
        [
            "count",
            "mean",
            "median",
            "min",
            "max",
        ]
    )
)

probability_summary.index = [
    "Future WET",
    "Future DRY",
]

print(
    probability_summary.to_string()
)


# ============================================================
# SAVE RESULTS
# ============================================================

results_file = (
    BASE_DIR
    / "evaluation_results.csv"
)

result_df = ml_df[
    [
        "timestamp",
        "CurrentSoilState",
        "FutureSoilState",
        "PredictedProbability",
    ]
].copy()

result_df[
    "ModelPrediction_05"
] = predictions_05

result_df[
    "PersistencePrediction"
] = baseline_predictions

result_df.to_csv(
    results_file,
    index=False
)

print(
    "\nEvaluation results saved to:"
)

print(
    results_file
)


print("\n" + "=" * 70)

print(
    "EVALUATION COMPLETE"
)

print("=" * 70)