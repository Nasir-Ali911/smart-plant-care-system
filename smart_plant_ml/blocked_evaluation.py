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
    brier_score_loss,
    confusion_matrix,
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

PROJECT_START = pd.Timestamp(
    "2026-09-01"
)

FUTURE_MINUTES_LOW = 12
FUTURE_MINUTES_HIGH = 18


# ============================================================
# LOAD DATA
# ============================================================

print("=" * 75)
print("SMART PLANT CARE - BLOCKED TEMPORAL EVALUATION")
print("=" * 75)

with open(
    DATA_FILE,
    "r",
    encoding="utf-8"
) as f:

    data = json.load(f)


logs = data["SmartPlant"]["Logs"]

records = []


for key, value in logs.items():

    if not isinstance(value, dict):
        continue

    timestamp = pd.to_datetime(
        value.get("Timestamp"),
        errors="coerce"
    )

    if pd.isna(timestamp):
        continue

    # Remove impossible historical timestamps.
    if timestamp < PROJECT_START:
        continue

    try:

        temperature = float(
            value["Temperature"]
        )

        humidity = float(
            value["Humidity"]
        )

        light = float(
            value["LightIntensity"]
        )

        soil = float(
            value["SoilMoistureRaw"]
        )

    except (
        TypeError,
        ValueError,
        KeyError,
    ):

        continue


    # Remove known invalid sensor row
    if (
        temperature == 0
        and humidity == 0
    ):

        continue


    # Only valid firmware soil states
    if soil not in [0, 1]:
        continue


    records.append({

        "timestamp": timestamp,

        "Temperature": temperature,

        "Humidity": humidity,

        "LightIntensity": light,

        "CurrentSoilState": int(soil),

    })


df = pd.DataFrame(records)

df = (
    df
    .sort_values("timestamp")
    .reset_index(drop=True)
)


print(
    f"\nClean project records: "
    f"{len(df):,}"
)

print(
    f"First record: "
    f"{df['timestamp'].min()}"
)

print(
    f"Last record: "
    f"{df['timestamp'].max()}"
)


# ============================================================
# FEATURES
# ============================================================

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


df["TemperatureChange"] = (
    df["Temperature"]
    .diff()
    .fillna(0)
)


df["HumidityChange"] = (
    df["Humidity"]
    .diff()
    .fillna(0)
)


df["LightChange"] = (
    df["LightIntensity"]
    .diff()
    .fillna(0)
)


df["IntervalMin"] = (
    df["timestamp"]
    .diff()
    .dt.total_seconds()
    / 60
).fillna(1)


df["IntervalMin"] = (
    df["IntervalMin"]
    .clip(
        lower=0,
        upper=60
    )
)


# ============================================================
# DRY DURATION
# ============================================================

dry_duration = []

duration = 0.0


for i in range(len(df)):

    if (
        df.loc[
            i,
            "CurrentSoilState"
        ] == 1
    ):

        duration += (
            df.loc[
                i,
                "IntervalMin"
            ]
        )

    else:

        duration = 0.0


    dry_duration.append(
        duration
    )


df["DryDurationHours"] = (
    np.array(dry_duration) / 60
)


# ============================================================
# FUTURE TARGET
# ============================================================

future_targets = []


for i in range(len(df)):

    current_time = (
        df.loc[
            i,
            "timestamp"
        ]
    )


    lower = (
        current_time
        + pd.Timedelta(
            minutes=FUTURE_MINUTES_LOW
        )
    )


    upper = (
        current_time
        + pd.Timedelta(
            minutes=FUTURE_MINUTES_HIGH
        )
    )


    candidates = df[
        (
            df["timestamp"]
            >= lower
        )
        &
        (
            df["timestamp"]
            <= upper
        )
    ]


    if len(candidates) == 0:

        future_targets.append(
            np.nan
        )

        continue


    target_time = (
        current_time
        + pd.Timedelta(
            minutes=15
        )
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


    future_targets.append(
        df.loc[
            best_idx,
            "CurrentSoilState"
        ]
    )


df["FutureSoilState"] = (
    future_targets
)


# ============================================================
# ML DATASET
# ============================================================

features = [

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
    subset=[
        "FutureSoilState"
    ]
).copy()


print(
    f"\nUsable ML samples: "
    f"{len(ml_df):,}"
)


# ============================================================
# LOAD MODEL
# ============================================================

bundle = joblib.load(
    MODEL_FILE
)


if isinstance(bundle, dict):

    model = bundle["model"]

else:

    model = bundle


print(
    f"\nModel: "
    f"{type(model).__name__}"
)


# ============================================================
# CREATE PREDICTIONS
# ============================================================

X = ml_df[
    features
]

y = (
    ml_df[
        "FutureSoilState"
    ]
    .astype(int)
)


probabilities = (
    model
    .predict_proba(X)[:, 1]
)


# ============================================================
# CREATE CHRONOLOGICAL BLOCKS
# ============================================================

ml_df["Date"] = (
    ml_df["timestamp"]
    .dt.date
)


dates = sorted(
    ml_df["Date"].unique()
)


print(
    "\nChronological blocks:"
)

for date in dates:

    block = ml_df[
        ml_df["Date"] == date
    ]

    print(
        f"{date} | "
        f"n={len(block):4d} | "
        f"WET="
        f"{(block['FutureSoilState'] == 0).sum():3d} | "
        f"DRY="
        f"{(block['FutureSoilState'] == 1).sum():3d}"
    )


# ============================================================
# EVALUATION FUNCTION
# ============================================================

def evaluate(
    name,
    y_true,
    predictions,
    probs
):

    print(
        "\n" + "-" * 75
    )

    print(name)

    print(
        "-" * 75
    )


    print(
        f"Samples   : {len(y_true)}"
    )


    print(
        f"Accuracy  : "
        f"{accuracy_score(y_true, predictions):.4f}"
    )


    print(
        f"Precision : "
        f"{precision_score(y_true, predictions, zero_division=0):.4f}"
    )


    print(
        f"Recall    : "
        f"{recall_score(y_true, predictions, zero_division=0):.4f}"
    )


    print(
        f"F1        : "
        f"{f1_score(y_true, predictions, zero_division=0):.4f}"
    )


    print(
        "\nConfusion Matrix:"
    )

    print(
        confusion_matrix(
            y_true,
            predictions
        )
    )


    if len(np.unique(y_true)) == 2:

        print(
            f"\nROC-AUC   : "
            f"{roc_auc_score(y_true, probs):.4f}"
        )

        print(
            f"PR-AUC    : "
            f"{average_precision_score(y_true, probs):.4f}"
        )


    print(
        f"Brier     : "
        f"{brier_score_loss(y_true, probs):.4f}"
    )


# ============================================================
# LEAVE-ONE-DAY-OUT EVALUATION
# ============================================================

print(
    "\n" + "=" * 75
)

print(
    "LEAVE-ONE-DAY-OUT EVALUATION"
)

print(
    "=" * 75
)


all_predictions = []
all_probabilities = []
all_actual = []
all_baseline = []


for test_date in dates:

    test_mask = (
        ml_df["Date"]
        == test_date
    )


    train_mask = (
        ml_df["Date"]
        != test_date
    )


    X_train = ml_df.loc[
        train_mask,
        features
    ]

    y_train = (
        ml_df.loc[
            train_mask,
            "FutureSoilState"
        ]
        .astype(int)
    )


    X_test = ml_df.loc[
        test_mask,
        features
    ]

    y_test = (
        ml_df.loc[
            test_mask,
            "FutureSoilState"
        ]
        .astype(int)
    )


    # Skip if training data does not contain both classes
    if len(y_train.unique()) < 2:

        print(
            f"\nSkipping {test_date}: "
            f"training data has only one class."
        )

        continue


    # --------------------------------------------------------
    # Train a fresh RF for this fold
    # --------------------------------------------------------

    from sklearn.ensemble import RandomForestClassifier


    fold_model = RandomForestClassifier(

        n_estimators=300,

        max_depth=10,

        min_samples_leaf=5,

        class_weight="balanced",

        random_state=42,

        n_jobs=-1,

    )


    fold_model.fit(
        X_train,
        y_train
    )


    fold_prob = (
        fold_model
        .predict_proba(
            X_test
        )[:, 1]
    )


    fold_pred = (
        fold_prob >= 0.50
    ).astype(int)


    fold_baseline = (
        ml_df.loc[
            test_mask,
            "CurrentSoilState"
        ]
        .astype(int)
        .values
    )


    all_actual.extend(
        y_test.values
    )

    all_predictions.extend(
        fold_pred
    )

    all_probabilities.extend(
        fold_prob
    )

    all_baseline.extend(
        fold_baseline
    )


    print(
        f"\n{test_date}"
    )

    print(
        f"Samples: {len(y_test)}"
    )

    print(
        f"Actual WET: "
        f"{(y_test == 0).sum()}"
    )

    print(
        f"Actual DRY: "
        f"{(y_test == 1).sum()}"
    )


# ============================================================
# OVERALL BLOCKED RESULTS
# ============================================================

all_actual = np.array(
    all_actual
)

all_predictions = np.array(
    all_predictions
)

all_probabilities = np.array(
    all_probabilities
)

all_baseline = np.array(
    all_baseline
)


evaluate(
    "BLOCKED RANDOM FOREST",
    all_actual,
    all_predictions,
    all_probabilities
)


evaluate(
    "BLOCKED PERSISTENCE BASELINE",
    all_actual,
    all_baseline,
    all_baseline
)


# ============================================================
# BASELINE COMPARISON
# ============================================================

print(
    "\n" + "=" * 75
)

print(
    "BLOCKED MODEL VS BASELINE"
)

print(
    "=" * 75
)


rf_acc = accuracy_score(
    all_actual,
    all_predictions
)


baseline_acc = accuracy_score(
    all_actual,
    all_baseline
)


rf_f1 = f1_score(
    all_actual,
    all_predictions,
    zero_division=0
)


baseline_f1 = f1_score(
    all_actual,
    all_baseline,
    zero_division=0
)


print(
    f"Random Forest accuracy : "
    f"{rf_acc:.4f}"
)


print(
    f"Persistence accuracy   : "
    f"{baseline_acc:.4f}"
)


print(
    f"Accuracy difference    : "
    f"{rf_acc - baseline_acc:+.4f}"
)


print(
    f"\nRandom Forest F1       : "
    f"{rf_f1:.4f}"
)


print(
    f"Persistence F1         : "
    f"{baseline_f1:.4f}"
)


print(
    f"F1 difference          : "
    f"{rf_f1 - baseline_f1:+.4f}"
)


# ============================================================
# SAVE RESULTS
# ============================================================

results = pd.DataFrame({

    "Actual": all_actual,

    "RandomForestPrediction":
        all_predictions,

    "RandomForestProbability":
        all_probabilities,

    "PersistencePrediction":
        all_baseline,

})


output_file = (
    BASE_DIR
    / "blocked_evaluation_results.csv"
)


results.to_csv(
    output_file,
    index=False
)


print(
    "\nResults saved to:"
)

print(
    output_file
)


print(
    "\n" + "=" * 75
)

print(
    "BLOCKED EVALUATION COMPLETE"
)

print(
    "=" * 75
)