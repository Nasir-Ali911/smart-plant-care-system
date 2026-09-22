import json
from pathlib import Path
from datetime import datetime, timedelta

DATA_FILE = Path("data/firebase_export.json")

print("=" * 80)
print("SMART PLANT CARE — ML DATASET ANALYSIS")
print("=" * 80)

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

smart_plant = data["SmartPlant"]
logs = smart_plant["Logs"]
watering_events = smart_plant["WateringEvents"]


def parse_timestamp(value):
    if not isinstance(value, str):
        return None

    try:
        return datetime.strptime(value, "%Y-%m-%d %H:%M:%S")
    except ValueError:
        return None


# ============================================================
# LOAD SENSOR LOGS
# ============================================================

sensor_logs = []

for key, log in logs.items():

    if not isinstance(log, dict):
        continue

    timestamp = parse_timestamp(log.get("Timestamp"))

    if timestamp is None:
        continue

    sensor_logs.append({
        "key": key,
        "timestamp": timestamp,
        "temperature": log.get("Temperature"),
        "humidity": log.get("Humidity"),
        "light": log.get("LightIntensity"),
        "soil_raw": log.get("SoilMoistureRaw"),
        "soil_status": log.get("SoilStatus"),
        "watering_event": log.get("WateringEvent"),
        "pump_state": log.get("PumpState"),
    })


sensor_logs.sort(key=lambda x: x["timestamp"])


# ============================================================
# LOAD WATERING EVENTS
# ============================================================

events = []

for key, event in watering_events.items():

    if not isinstance(event, dict):
        continue

    timestamp = parse_timestamp(event.get("Timestamp"))

    if timestamp is None:
        continue

    events.append({
        "key": key,
        "timestamp": timestamp,
    })


events.sort(key=lambda x: x["timestamp"])


# ============================================================
# CREATE WATERING SESSIONS
# ============================================================

SESSION_GAP_SECONDS = 300

sessions = []

if events:

    current = [events[0]]

    for event in events[1:]:

        gap = (
            event["timestamp"]
            - current[-1]["timestamp"]
        ).total_seconds()

        if gap <= SESSION_GAP_SECONDS:
            current.append(event)

        else:
            sessions.append(current)
            current = [event]

    sessions.append(current)


print("\n" + "=" * 80)
print("DATASET OVERVIEW")
print("=" * 80)

print(f"Valid sensor logs      : {len(sensor_logs):,}")
print(f"Watering events        : {len(events):,}")
print(f"Watering sessions      : {len(sessions):,}")

if sensor_logs:

    print(f"First sensor log       : {sensor_logs[0]['timestamp']}")
    print(f"Last sensor log        : {sensor_logs[-1]['timestamp']}")


# ============================================================
# SESSION ANALYSIS
# ============================================================

print("\n" + "=" * 80)
print("WATERING SESSION ANALYSIS")
print("=" * 80)

for i, session in enumerate(sessions, start=1):

    start = session[0]["timestamp"]
    end = session[-1]["timestamp"]

    print(f"\nSession {i}")
    print(f"  Start       : {start}")
    print(f"  End         : {end}")
    print(f"  Pump events : {len(session)}")

    # --------------------------------------------------------
    # Logs in previous 6 hours
    # --------------------------------------------------------

    window_start = start - timedelta(hours=6)

    previous_logs = [
        log
        for log in sensor_logs
        if window_start <= log["timestamp"] < start
    ]

    print(f"  Logs in previous 6h: {len(previous_logs)}")

    # --------------------------------------------------------
    # Logs in previous 30 minutes
    # --------------------------------------------------------

    window_start_30 = start - timedelta(minutes=30)

    previous_30 = [
        log
        for log in sensor_logs
        if window_start_30 <= log["timestamp"] < start
    ]

    print(f"  Logs in previous 30m: {len(previous_30)}")

    # --------------------------------------------------------
    # Nearest previous log
    # --------------------------------------------------------

    previous = [
        log
        for log in sensor_logs
        if log["timestamp"] < start
    ]

    if previous:

        last = previous[-1]

        gap = (
            start - last["timestamp"]
        ).total_seconds()

        print("\n  Last sensor reading before session:")

        print(f"    Time        : {last['timestamp']}")
        print(f"    Gap         : {gap:.1f} seconds")
        print(f"    Temperature : {last['temperature']}")
        print(f"    Humidity    : {last['humidity']}")
        print(f"    Light       : {last['light']}")
        print(f"    Soil raw    : {last['soil_raw']}")
        print(f"    Soil status : {last['soil_status']}")

    # --------------------------------------------------------
    # Numeric ranges in previous 6 hours
    # --------------------------------------------------------

    def numeric_values(field):

        values = []

        for log in previous_logs:

            value = log.get(field)

            if isinstance(value, (int, float)):
                values.append(float(value))

        return values


    for field, label in [
        ("temperature", "Temperature"),
        ("humidity", "Humidity"),
        ("light", "Light"),
        ("soil_raw", "SoilMoistureRaw"),
    ]:

        values = numeric_values(field)

        if values:

            print(
                f"    {label:18s}: "
                f"min={min(values):.2f}, "
                f"max={max(values):.2f}, "
                f"mean={sum(values)/len(values):.2f}"
            )


# ============================================================
# NORMAL PERIODS
# ============================================================

print("\n" + "=" * 80)
print("NORMAL / NON-WATERING DATA")
print("=" * 80)

non_event_logs = [
    log
    for log in sensor_logs
    if log.get("watering_event") is not True
    and log.get("pump_state") != "ON"
]

print(
    f"Non-watering sensor logs: "
    f"{len(non_event_logs):,}"
)


# ============================================================
# SENSOR DISTRIBUTIONS
# ============================================================

print("\n" + "=" * 80)
print("SENSOR VALUE RANGES")
print("=" * 80)


def show_range(name, field):

    values = []

    for log in sensor_logs:

        value = log.get(field)

        if isinstance(value, (int, float)):
            values.append(float(value))

    if values:

        print(
            f"{name:20s}: "
            f"min={min(values):.2f}, "
            f"max={max(values):.2f}, "
            f"mean={sum(values)/len(values):.2f}"
        )

    else:

        print(f"{name:20s}: no numeric data")


show_range("Temperature", "temperature")
show_range("Humidity", "humidity")
show_range("LightIntensity", "light")
show_range("SoilMoistureRaw", "soil_raw")


# ============================================================
# SOIL RAW DISTRIBUTION
# ============================================================

print("\n" + "=" * 80)
print("SOIL MOISTURE RAW VALUES")
print("=" * 80)

soil_values = [
    log["soil_raw"]
    for log in sensor_logs
    if isinstance(log.get("soil_raw"), (int, float))
]

from collections import Counter

counter = Counter(soil_values)

for value, count in sorted(counter.items()):

    print(
        f"  {value}: {count:,}"
    )


# ============================================================
# MISSINGNESS
# ============================================================

print("\n" + "=" * 80)
print("MISSINGNESS")
print("=" * 80)

for field, label in [
    ("temperature", "Temperature"),
    ("humidity", "Humidity"),
    ("light", "LightIntensity"),
    ("soil_raw", "SoilMoistureRaw"),
]:

    missing = sum(
        1
        for log in sensor_logs
        if log.get(field) is None
    )

    percentage = (
        missing / len(sensor_logs) * 100
        if sensor_logs
        else 0
    )

    print(
        f"{label:20s}: "
        f"{missing:,} missing "
        f"({percentage:.2f}%)"
    )


# ============================================================
# CONCLUSION
# ============================================================

print("\n" + "=" * 80)
print("ML DATASET ANALYSIS COMPLETE")
print("=" * 80)

print("\nNo data was modified.")