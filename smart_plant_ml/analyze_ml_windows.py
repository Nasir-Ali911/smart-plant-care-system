import json
from pathlib import Path
from datetime import datetime, timedelta
from collections import Counter


DATA_FILE = Path("data/firebase_export.json")


print("=" * 75)
print("SMART PLANT CARE — ML WINDOW ANALYSIS")
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
# CLEAN DATA
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

    # Remove known invalid sensor failure
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
# DATE RANGE
# ============================================================

print("\n" + "=" * 75)
print("DATE RANGE")
print("=" * 75)

print(
    f"First record: {records[0]['timestamp']}"
)

print(
    f"Last record : {records[-1]['timestamp']}"
)


# ============================================================
# DAILY DISTRIBUTION
# ============================================================

print("\n" + "=" * 75)
print("DAILY SOIL DISTRIBUTION")
print("=" * 75)


daily = {}


for record in records:

    date = record["timestamp"].date()

    if date not in daily:
        daily[date] = {
            "wet": 0,
            "dry": 0,
            "total": 0
        }

    daily[date]["total"] += 1

    if record["soil"] == 0:
        daily[date]["wet"] += 1
    else:
        daily[date]["dry"] += 1


for date in sorted(daily):

    d = daily[date]

    dry_percent = (
        d["dry"] /
        d["total"] *
        100
    )

    print(
        f"{date} | "
        f"Total={d['total']:4d} | "
        f"WET={d['wet']:4d} | "
        f"DRY={d['dry']:4d} | "
        f"Dry%={dry_percent:5.1f}%"
    )


# ============================================================
# HOURLY SOIL DISTRIBUTION
# ============================================================

print("\n" + "=" * 75)
print("HOURLY SOIL DISTRIBUTION")
print("=" * 75)


hourly = {
    hour: {
        "wet": 0,
        "dry": 0
    }
    for hour in range(24)
}


for record in records:

    hour = record["timestamp"].hour

    if record["soil"] == 0:
        hourly[hour]["wet"] += 1
    else:
        hourly[hour]["dry"] += 1


for hour in range(24):

    wet = hourly[hour]["wet"]
    dry = hourly[hour]["dry"]

    total = wet + dry

    if total == 0:
        continue

    dry_percent = (
        dry /
        total *
        100
    )

    print(
        f"{hour:02d}:00 | "
        f"Total={total:4d} | "
        f"WET={wet:4d} | "
        f"DRY={dry:4d} | "
        f"Dry%={dry_percent:5.1f}%"
    )


# ============================================================
# ENVIRONMENTAL DIFFERENCES
# ============================================================

print("\n" + "=" * 75)
print("ENVIRONMENTAL VARIABLES BY SOIL STATE")
print("=" * 75)


for state, name in [(0, "WET"), (1, "DRY")]:

    subset = [
        r
        for r in records
        if r["soil"] == state
    ]

    temperatures = [
        r["temperature"]
        for r in subset
    ]

    humidities = [
        r["humidity"]
        for r in subset
    ]

    lights = [
        r["light"]
        for r in subset
    ]

    print(f"\n{name}")

    print(
        f"  Temperature: "
        f"{sum(temperatures)/len(temperatures):.2f}"
    )

    print(
        f"  Humidity: "
        f"{sum(humidities)/len(humidities):.2f}"
    )

    print(
        f"  Light: "
        f"{sum(lights)/len(lights):.2f}"
    )


# ============================================================
# CONSECUTIVE RUNS
# ============================================================

print("\n" + "=" * 75)
print("CONSECUTIVE SOIL RUNS")
print("=" * 75)


runs = []

current_state = records[0]["soil"]
run_start = records[0]["timestamp"]
run_count = 1


for i in range(1, len(records)):

    previous = records[i - 1]
    current = records[i]

    gap = (
        current["timestamp"] -
        previous["timestamp"]
    ).total_seconds()

    # Large gap = don't treat as continuous run
    if gap > 300:

        runs.append({
            "state": current_state,
            "count": run_count,
            "start": run_start,
            "end": previous["timestamp"]
        })

        current_state = current["soil"]
        run_start = current["timestamp"]
        run_count = 1

        continue


    if current["soil"] == current_state:

        run_count += 1

    else:

        runs.append({
            "state": current_state,
            "count": run_count,
            "start": run_start,
            "end": previous["timestamp"]
        })

        current_state = current["soil"]
        run_start = current["timestamp"]
        run_count = 1


runs.append({
    "state": current_state,
    "count": run_count,
    "start": run_start,
    "end": records[-1]["timestamp"]
})


wet_runs = [
    r for r in runs
    if r["state"] == 0
]

dry_runs = [
    r for r in runs
    if r["state"] == 1
]


print(
    f"\nWET runs: {len(wet_runs)}"
)

print(
    f"DRY runs: {len(dry_runs)}"
)


print("\nLargest WET runs:")

for run in sorted(
    wet_runs,
    key=lambda x: x["count"],
    reverse=True
)[:10]:

    duration = (
        run["end"] -
        run["start"]
    ).total_seconds() / 60

    print(
        f"  {run['start']} → "
        f"{run['end']} | "
        f"{run['count']} records | "
        f"{duration:.1f} min"
    )


print("\nLargest DRY runs:")

for run in sorted(
    dry_runs,
    key=lambda x: x["count"],
    reverse=True
)[:10]:

    duration = (
        run["end"] -
        run["start"]
    ).total_seconds() / 60

    print(
        f"  {run['start']} → "
        f"{run['end']} | "
        f"{run['count']} records | "
        f"{duration:.1f} min"
    )


print("\n" + "=" * 75)
print("WINDOW ANALYSIS COMPLETE")
print("=" * 75)