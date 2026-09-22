import json
from pathlib import Path
from datetime import datetime
from collections import Counter

DATA_FILE = Path("data/firebase_export.json")

print("=" * 75)
print("SMART PLANT CARE — FINAL ML DATA QUALITY CHECK")
print("=" * 75)

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

logs = data["SmartPlant"]["Logs"]


def parse_timestamp(value):
    if not isinstance(value, str):
        return None

    try:
        return datetime.strptime(value, "%Y-%m-%d %H:%M:%S")
    except ValueError:
        return None


valid_logs = []

for key, log in logs.items():

    if not isinstance(log, dict):
        continue

    timestamp = parse_timestamp(log.get("Timestamp"))

    if timestamp is None:
        continue

    valid_logs.append(log)


print(f"\nValid logs: {len(valid_logs):,}")


# ============================================================
# ZERO / SUSPICIOUS VALUES
# ============================================================

print("\n" + "=" * 75)
print("SUSPICIOUS SENSOR VALUES")
print("=" * 75)

checks = [
    ("Temperature == 0", "Temperature", 0),
    ("Humidity == 0", "Humidity", 0),
    ("LightIntensity == 0", "LightIntensity", 0),
    ("SoilMoistureRaw == 0", "SoilMoistureRaw", 0),
]


for label, field, value in checks:

    matches = [
        log
        for log in valid_logs
        if log.get(field) == value
    ]

    print(f"\n{label}: {len(matches):,}")

    for log in matches[:5]:
        print(
            f"  {log.get('Timestamp')} "
            f"| Temp={log.get('Temperature')} "
            f"| Humidity={log.get('Humidity')} "
            f"| Light={log.get('LightIntensity')} "
            f"| Soil={log.get('SoilMoistureRaw')}"
        )


# ============================================================
# EXTREME VALUES
# ============================================================

print("\n" + "=" * 75)
print("EXTREME VALUES")
print("=" * 75)

temperature_values = [
    float(log["Temperature"])
    for log in valid_logs
    if isinstance(log.get("Temperature"), (int, float))
]

humidity_values = [
    float(log["Humidity"])
    for log in valid_logs
    if isinstance(log.get("Humidity"), (int, float))
]

light_values = [
    float(log["LightIntensity"])
    for log in valid_logs
    if isinstance(log.get("LightIntensity"), (int, float))
]


print("\nTemperature < 10°C:")
print(
    sum(1 for x in temperature_values if x < 10)
)

print("Temperature > 40°C:")
print(
    sum(1 for x in temperature_values if x > 40)
)

print("\nHumidity < 20%:")
print(
    sum(1 for x in humidity_values if x < 20)
)

print("Humidity > 95%:")
print(
    sum(1 for x in humidity_values if x > 95)
)

print("\nLight < 50:")
print(
    sum(1 for x in light_values if x < 50)
)


# ============================================================
# SOIL STATUS VS RAW VALUE
# ============================================================

print("\n" + "=" * 75)
print("SOIL STATUS CONSISTENCY")
print("=" * 75)

mismatches = []

for log in valid_logs:

    raw = log.get("SoilMoistureRaw")
    status = str(log.get("SoilStatus", "")).upper()

    if raw == 0 and "DRY" in status:
        mismatches.append(log)

    if raw == 1 and "WET" in status:
        mismatches.append(log)


print(
    f"Raw/status mismatches: {len(mismatches):,}"
)

for log in mismatches[:10]:

    print(
        f"  {log.get('Timestamp')} | "
        f"Raw={log.get('SoilMoistureRaw')} | "
        f"Status={log.get('SoilStatus')}"
    )


# ============================================================
# TIMESTAMP INTERVALS
# ============================================================

print("\n" + "=" * 75)
print("SAMPLING INTERVAL")
print("=" * 75)

timestamped = []

for log in valid_logs:

    timestamp = parse_timestamp(log.get("Timestamp"))

    if timestamp:
        timestamped.append(timestamp)


timestamped.sort()

intervals = []

for i in range(1, len(timestamped)):

    seconds = (
        timestamped[i] - timestamped[i - 1]
    ).total_seconds()

    if seconds >= 0:
        intervals.append(seconds)


if intervals:

    sorted_intervals = sorted(intervals)

    median = sorted_intervals[
        len(sorted_intervals) // 2
    ]

    print(f"Minimum interval : {min(intervals):.1f} sec")
    print(f"Median interval  : {median:.1f} sec")
    print(f"Maximum interval : {max(intervals):.1f} sec")

    print("\nIntervals <= 10 sec:")
    print(
        sum(1 for x in intervals if x <= 10)
    )

    print("Intervals 10–120 sec:")
    print(
        sum(1 for x in intervals if 10 < x <= 120)
    )

    print("Intervals > 120 sec:")
    print(
        sum(1 for x in intervals if x > 120)
    )


print("\n" + "=" * 75)
print("QUALITY CHECK COMPLETE")
print("=" * 75)

print("\nNo data was modified.")