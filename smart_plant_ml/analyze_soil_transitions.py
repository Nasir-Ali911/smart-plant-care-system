import json
from pathlib import Path
from datetime import datetime, timedelta


DATA_FILE = Path("data/firebase_export.json")


print("=" * 75)
print("SMART PLANT CARE — SOIL TRANSITION ANALYSIS")
print("=" * 75)


# ============================================================
# LOAD DATA
# ============================================================

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)


logs = data["SmartPlant"]["Logs"]


# ============================================================
# PARSE TIMESTAMP
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
# BUILD CLEAN SENSOR DATA
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

    # Skip invalid sensor rows
    if not isinstance(temperature, (int, float)):
        continue

    if not isinstance(humidity, (int, float)):
        continue

    if not isinstance(light, (int, float)):
        continue

    if soil not in (0, 1):
        continue

    # Remove obvious zero sensor failure
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
# BASIC SOIL COUNTS
# ============================================================

wet_count = sum(
    1
    for r in records
    if r["soil"] == 0
)

dry_count = sum(
    1
    for r in records
    if r["soil"] == 1
)


print("\n" + "=" * 75)
print("SOIL STATE DISTRIBUTION")
print("=" * 75)

print(f"WET records : {wet_count:,}")
print(f"DRY records : {dry_count:,}")


# ============================================================
# STATE TRANSITIONS
# ============================================================

transitions = []

for i in range(1, len(records)):

    previous = records[i - 1]
    current = records[i]

    # Ignore extremely large gaps when identifying transitions
    gap_seconds = (
        current["timestamp"] -
        previous["timestamp"]
    ).total_seconds()

    if gap_seconds > 300:
        continue

    if previous["soil"] == 0 and current["soil"] == 1:

        transitions.append({
            "timestamp": current["timestamp"],
            "gap_seconds": gap_seconds,
            "temperature": current["temperature"],
            "humidity": current["humidity"],
            "light": current["light"],
        })


print("\n" + "=" * 75)
print("DIRECT WET → DRY TRANSITIONS")
print("=" * 75)

print(
    f"Number of WET → DRY transitions: "
    f"{len(transitions)}"
)


for transition in transitions:

    print(
        f"  {transition['timestamp']} | "
        f"gap={transition['gap_seconds']:.0f}s | "
        f"Temp={transition['temperature']:.1f} | "
        f"Humidity={transition['humidity']:.1f} | "
        f"Light={transition['light']:.0f}"
    )


# ============================================================
# DRY → WET TRANSITIONS
# ============================================================

dry_to_wet = []

for i in range(1, len(records)):

    previous = records[i - 1]
    current = records[i]

    gap_seconds = (
        current["timestamp"] -
        previous["timestamp"]
    ).total_seconds()

    if gap_seconds > 300:
        continue

    if previous["soil"] == 1 and current["soil"] == 0:

        dry_to_wet.append({
            "timestamp": current["timestamp"],
            "gap_seconds": gap_seconds,
        })


print("\n" + "=" * 75)
print("DIRECT DRY → WET TRANSITIONS")
print("=" * 75)

print(
    f"Number of DRY → WET transitions: "
    f"{len(dry_to_wet)}"
)

for transition in dry_to_wet:

    print(
        f"  {transition['timestamp']} | "
        f"gap={transition['gap_seconds']:.0f}s"
    )


# ============================================================
# FUTURE DRY WITHIN 30 MINUTES
# ============================================================

print("\n" + "=" * 75)
print("WET → FUTURE DRY ANALYSIS")
print("=" * 75)


horizon = timedelta(minutes=30)

positive_samples = 0
negative_samples = 0

examples = []


for i, current in enumerate(records):

    # Only make predictions for currently WET soil
    if current["soil"] != 0:
        continue

    current_time = current["timestamp"]

    future_deadline = (
        current_time + horizon
    )

    future_dry = False

    for j in range(i + 1, len(records)):

        future = records[j]

        # Outside future horizon
        if future["timestamp"] > future_deadline:
            break

        # Large data gap means we cannot safely
        # know what happened in between.
        gap = (
            future["timestamp"] -
            records[j - 1]["timestamp"]
        ).total_seconds()

        if gap > 300:
            break

        if future["soil"] == 1:

            future_dry = True

            if len(examples) < 20:
                examples.append({
                    "current": current["timestamp"],
                    "dry_at": future["timestamp"],
                    "minutes": (
                        future["timestamp"] -
                        current["timestamp"]
                    ).total_seconds() / 60
                })

            break

    if future_dry:
        positive_samples += 1
    else:
        negative_samples += 1


print(
    f"\nWET samples becoming DRY within 30 min: "
    f"{positive_samples:,}"
)

print(
    f"WET samples remaining WET: "
    f"{negative_samples:,}"
)


total = positive_samples + negative_samples

if total > 0:

    print(
        f"\nPositive rate: "
        f"{positive_samples / total * 100:.2f}%"
    )


# ============================================================
# EXAMPLES
# ============================================================

print("\n" + "=" * 75)
print("EXAMPLES OF FUTURE-DRY EVENTS")
print("=" * 75)


for example in examples:

    print(
        f"Current={example['current']} | "
        f"DryAt={example['dry_at']} | "
        f"After={example['minutes']:.1f} min"
    )


# ============================================================
# CONCLUSION
# ============================================================

print("\n" + "=" * 75)
print("TRANSITION ANALYSIS COMPLETE")
print("=" * 75)

print(
    "\nNo data was modified."
)