import json
from pathlib import Path
from datetime import datetime, timedelta


DATA_FILE = Path("data/firebase_export.json")


print("=" * 75)
print("SMART PLANT CARE — FUTURE SOIL TARGET ANALYSIS")
print("=" * 75)


# ============================================================
# LOAD DATA
# ============================================================

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)


logs = data["SmartPlant"]["Logs"]


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
# CLEAN RECORDS
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

    if not isinstance(temperature, (int, float)):
        continue

    if not isinstance(humidity, (int, float)):
        continue

    if not isinstance(light, (int, float)):
        continue

    if soil not in (0, 1):
        continue

    # Remove the two known sensor-failure records
    if temperature == 0 and humidity == 0:
        continue

    records.append({
        "timestamp": timestamp,
        "temperature": float(temperature),
        "humidity": float(humidity),
        "light": float(light),
        "soil": int(soil),
    })


records.sort(
    key=lambda x: x["timestamp"]
)


print(f"\nClean records: {len(records):,}")


# ============================================================
# TARGET ANALYSIS
# ============================================================

TARGET_MINUTES = 15
TARGET_TOLERANCE_MINUTES = 3

target_delta = timedelta(
    minutes=TARGET_MINUTES
)

minimum_delta = timedelta(
    minutes=TARGET_MINUTES -
    TARGET_TOLERANCE_MINUTES
)

maximum_delta = timedelta(
    minutes=TARGET_MINUTES +
    TARGET_TOLERANCE_MINUTES
)


print("\n" + "=" * 75)
print("TARGET DEFINITION")
print("=" * 75)

print(
    f"Target: soil state approximately "
    f"{TARGET_MINUTES} minutes in the future"
)

print(
    f"Allowed future window: "
    f"{TARGET_MINUTES - TARGET_TOLERANCE_MINUTES}–"
    f"{TARGET_MINUTES + TARGET_TOLERANCE_MINUTES} minutes"
)


# ============================================================
# BUILD TARGETS
# ============================================================

samples = []

no_future = 0
large_gap = 0


for i, current in enumerate(records):

    target_time = (
        current["timestamp"] +
        target_delta
    )

    best_future = None
    best_difference = None

    # Search future records
    for j in range(i + 1, len(records)):

        future = records[j]

        difference = (
            future["timestamp"] -
            current["timestamp"]
        )

        # Future record too early
        if difference < minimum_delta:
            continue

        # Future record too late
        if difference > maximum_delta:
            break

        # Check that there isn't a large sampling gap
        previous = records[j - 1]

        gap = (
            future["timestamp"] -
            previous["timestamp"]
        ).total_seconds()

        if gap > 300:
            continue

        difference_from_target = abs(
            difference.total_seconds()
            - target_delta.total_seconds()
        )

        if (
            best_difference is None
            or difference_from_target < best_difference
        ):

            best_difference = difference_from_target
            best_future = future


    if best_future is None:

        no_future += 1
        continue


    samples.append({
        "timestamp": current["timestamp"],
        "current_soil": current["soil"],
        "future_soil": best_future["soil"],
        "future_timestamp": best_future["timestamp"],
        "minutes_ahead": (
            best_future["timestamp"] -
            current["timestamp"]
        ).total_seconds() / 60
    })


# ============================================================
# RESULTS
# ============================================================

print("\n" + "=" * 75)
print("TARGET COVERAGE")
print("=" * 75)

print(
    f"Usable prediction samples: "
    f"{len(samples):,}"
)

print(
    f"No suitable future observation: "
    f"{no_future:,}"
)


# ============================================================
# FUTURE SOIL DISTRIBUTION
# ============================================================

future_wet = sum(
    1
    for s in samples
    if s["future_soil"] == 0
)

future_dry = sum(
    1
    for s in samples
    if s["future_soil"] == 1
)


print("\n" + "=" * 75)
print("FUTURE SOIL DISTRIBUTION")
print("=" * 75)

print(
    f"Future WET: {future_wet:,}"
)

print(
    f"Future DRY: {future_dry:,}"
)


if len(samples) > 0:

    print(
        f"Future DRY percentage: "
        f"{future_dry / len(samples) * 100:.2f}%"
    )


# ============================================================
# CONFUSION OF CURRENT → FUTURE
# ============================================================

print("\n" + "=" * 75)
print("CURRENT → FUTURE STATE")
print("=" * 75)


current_wet_future_wet = sum(
    1
    for s in samples
    if s["current_soil"] == 0
    and s["future_soil"] == 0
)

current_wet_future_dry = sum(
    1
    for s in samples
    if s["current_soil"] == 0
    and s["future_soil"] == 1
)

current_dry_future_wet = sum(
    1
    for s in samples
    if s["current_soil"] == 1
    and s["future_soil"] == 0
)

current_dry_future_dry = sum(
    1
    for s in samples
    if s["current_soil"] == 1
    and s["future_soil"] == 1
)


print(
    f"Current WET  → Future WET : "
    f"{current_wet_future_wet:,}"
)

print(
    f"Current WET  → Future DRY : "
    f"{current_wet_future_dry:,}"
)

print(
    f"Current DRY  → Future WET : "
    f"{current_dry_future_wet:,}"
)

print(
    f"Current DRY  → Future DRY : "
    f"{current_dry_future_dry:,}"
)


# ============================================================
# TRANSITION RATE
# ============================================================

wet_total = (
    current_wet_future_wet +
    current_wet_future_dry
)

dry_total = (
    current_dry_future_wet +
    current_dry_future_dry
)


print("\n" + "=" * 75)
print("PERSISTENCE / TRANSITION RATES")
print("=" * 75)


if wet_total > 0:

    print(
        f"WET → DRY rate: "
        f"{current_wet_future_dry / wet_total * 100:.2f}%"
    )


if dry_total > 0:

    print(
        f"DRY → WET rate: "
        f"{current_dry_future_wet / dry_total * 100:.2f}%"
    )


# ============================================================
# DAILY TARGET DISTRIBUTION
# ============================================================

print("\n" + "=" * 75)
print("DAILY FUTURE TARGET DISTRIBUTION")
print("=" * 75)


daily = {}


for sample in samples:

    date = sample["timestamp"].date()

    if date not in daily:

        daily[date] = {
            "wet": 0,
            "dry": 0
        }

    if sample["future_soil"] == 0:
        daily[date]["wet"] += 1
    else:
        daily[date]["dry"] += 1


for date in sorted(daily):

    wet = daily[date]["wet"]
    dry = daily[date]["dry"]

    total = wet + dry

    print(
        f"{date} | "
        f"Total={total:4d} | "
        f"WET={wet:4d} | "
        f"DRY={dry:4d}"
    )


# ============================================================
# EXAMPLE TARGETS
# ============================================================

print("\n" + "=" * 75)
print("EXAMPLE FUTURE PREDICTION TARGETS")
print("=" * 75)


for sample in samples[:15]:

    current_name = (
        "WET"
        if sample["current_soil"] == 0
        else "DRY"
    )

    future_name = (
        "WET"
        if sample["future_soil"] == 0
        else "DRY"
    )

    print(
        f"{sample['timestamp']} | "
        f"{current_name} → "
        f"{future_name} | "
        f"{sample['minutes_ahead']:.1f} min"
    )


print("\n" + "=" * 75)
print("TARGET ANALYSIS COMPLETE")
print("=" * 75)

print("\nNo data was modified.")