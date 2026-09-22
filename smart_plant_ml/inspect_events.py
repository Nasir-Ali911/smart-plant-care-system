import json
from pathlib import Path
from collections import Counter


DATA_FILE = Path("data/firebase_export.json")


print("=" * 70)
print("SMART PLANT CARE — WATERING EVENT INSPECTION")
print("=" * 70)


# ============================================================
# LOAD DATA
# ============================================================

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)


smart_plant = data.get("SmartPlant", {})

logs = smart_plant.get("Logs", {})
watering_events = smart_plant.get("WateringEvents", {})


# ============================================================
# BASIC COUNTS
# ============================================================

print("\nWateringEvents node:")
print(f"Type: {type(watering_events).__name__}")
print(f"Number of events: {len(watering_events):,}")


print("\nLogs:")
print(f"Number of logs: {len(logs):,}")


# ============================================================
# WATERING EVENT STRUCTURE
# ============================================================

print("\n" + "=" * 70)
print("WATERING EVENT STRUCTURE")
print("=" * 70)


if watering_events:

    first_key = next(iter(watering_events))

    first_event = watering_events[first_key]

    print("\nFirst event key:")
    print(first_key)

    print("\nFirst event:")

    if isinstance(first_event, dict):

        for key, value in first_event.items():
            print(
                f"  {key}: "
                f"{type(value).__name__} = {value}"
            )

    else:
        print(
            f"  {type(first_event).__name__} = "
            f"{first_event}"
        )


# ============================================================
# ALL EVENT FIELDS
# ============================================================

print("\n" + "=" * 70)
print("ALL WATERING EVENT FIELDS")
print("=" * 70)


event_fields = set()

for event in watering_events.values():

    if isinstance(event, dict):
        event_fields.update(event.keys())


for field in sorted(event_fields):
    print(f"  - {field}")


# ============================================================
# EVENT VALUE DISTRIBUTION
# ============================================================

print("\n" + "=" * 70)
print("WATERING EVENT VALUE DISTRIBUTION")
print("=" * 70)


for field in sorted(event_fields):

    counter = Counter()

    for event in watering_events.values():

        if not isinstance(event, dict):
            continue

        value = event.get(field)

        if value is not None:

            # Avoid printing huge values
            value_text = str(value)

            if len(value_text) > 100:
                value_text = value_text[:100] + "..."

            counter[value_text] += 1

    print(f"\n{field}:")

    for value, count in counter.most_common(20):

        print(
            f"  {value}: {count:,}"
        )


# ============================================================
# SAMPLE EVENTS
# ============================================================

print("\n" + "=" * 70)
print("SAMPLE WATERING EVENTS")
print("=" * 70)


for i, (key, event) in enumerate(
    watering_events.items()
):

    if i >= 10:
        break

    print(f"\nEvent {i + 1}")
    print(f"Key: {key}")

    if isinstance(event, dict):

        for field, value in event.items():

            print(
                f"  {field}: {value}"
            )

    else:

        print(
            f"  Value: {event}"
        )


# ============================================================
# LOGS CONTAINING WATERING EVENT
# ============================================================

print("\n" + "=" * 70)
print("LOGS WITH WATERING EVENTS")
print("=" * 70)


event_logs = []

for key, log in logs.items():

    if not isinstance(log, dict):
        continue

    event_value = log.get("WateringEvent")

    if event_value is not None:

        event_logs.append(
            (key, log)
        )


print(
    f"Logs containing WateringEvent: "
    f"{len(event_logs):,}"
)


for i, (key, log) in enumerate(event_logs):

    if i >= 15:
        break

    print(f"\nLog {i + 1}")
    print(f"Key: {key}")

    for field in [
        "Timestamp",
        "TimestampMillis",
        "Temperature",
        "Humidity",
        "LightIntensity",
        "SoilMoisture",
        "SoilMoistureRaw",
        "SoilStatus",
        "WateringEvent",
        "PumpState",
        "RelayStatus",
    ]:

        if field in log:

            print(
                f"  {field}: "
                f"{log[field]}"
            )


# ============================================================
# FINISH
# ============================================================

print("\n" + "=" * 70)
print("EVENT INSPECTION COMPLETE")
print("=" * 70)

print(
    "\nNo data was modified."
)