import json
from pathlib import Path
from datetime import datetime


# ============================================================
# CONFIGURATION
# ============================================================

DATA_FILE = Path("data/firebase_export.json")


# ============================================================
# LOAD FIREBASE EXPORT
# ============================================================

print("=" * 70)
print("SMART PLANT CARE — FIREBASE DATA INSPECTION")
print("=" * 70)

if not DATA_FILE.exists():
    raise FileNotFoundError(
        f"Dataset not found:\n{DATA_FILE.resolve()}"
    )

file_size_mb = DATA_FILE.stat().st_size / (1024 * 1024)

print(f"\nDataset:")
print(DATA_FILE.resolve())

print(f"File size: {file_size_mb:.2f} MB")

print("\nLoading JSON...")

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

print("JSON loaded successfully.")


# ============================================================
# BASIC STRUCTURE
# ============================================================

print("\n" + "=" * 70)
print("TOP-LEVEL STRUCTURE")
print("=" * 70)

if isinstance(data, dict):

    print(f"Top-level keys: {len(data)}")

    for key in data.keys():
        value = data[key]

        if isinstance(value, dict):
            print(
                f"  {key}: dictionary "
                f"({len(value):,} entries)"
            )

        elif isinstance(value, list):
            print(
                f"  {key}: list "
                f"({len(value):,} items)"
            )

        else:
            print(
                f"  {key}: {type(value).__name__}"
            )

else:
    print(
        f"WARNING: Root JSON object is "
        f"{type(data).__name__}, not a dictionary."
    )


# ============================================================
# FIND SMARTPLANT
# ============================================================

smart_plant = data.get("SmartPlant")

if smart_plant is None:
    print("\nWARNING: /SmartPlant was not found.")

else:

    print("\n" + "=" * 70)
    print("SMARTPLANT STRUCTURE")
    print("=" * 70)

    if isinstance(smart_plant, dict):

        for key, value in smart_plant.items():

            if isinstance(value, dict):
                print(
                    f"  {key}: dictionary "
                    f"({len(value):,} entries)"
                )

            elif isinstance(value, list):
                print(
                    f"  {key}: list "
                    f"({len(value):,} items)"
                )

            else:
                print(
                    f"  {key}: "
                    f"{type(value).__name__} = {value}"
                )


# ============================================================
# FIND LOGS
# ============================================================

logs = None

if isinstance(smart_plant, dict):
    logs = smart_plant.get("Logs")


if logs is None:

    print("\n" + "=" * 70)
    print("LOGS")
    print("=" * 70)

    print("No /SmartPlant/Logs node found.")

else:

    print("\n" + "=" * 70)
    print("LOG INFORMATION")
    print("=" * 70)

    print(f"Log container type: {type(logs).__name__}")

    if isinstance(logs, dict):

        print(f"Number of log entries: {len(logs):,}")

        if len(logs) > 0:

            # ------------------------------------------------
            # Inspect first log
            # ------------------------------------------------

            first_key = next(iter(logs))
            first_log = logs[first_key]

            print("\nFirst log key:")
            print(first_key)

            print("\nFirst log fields:")

            if isinstance(first_log, dict):

                for key, value in first_log.items():
                    print(
                        f"  {key}: "
                        f"{type(value).__name__} = {value}"
                    )

            # ------------------------------------------------
            # Determine available fields
            # ------------------------------------------------

            all_fields = set()

            for log in logs.values():

                if isinstance(log, dict):
                    all_fields.update(log.keys())

            print("\nAll fields found across logs:")

            for field in sorted(all_fields):
                print(f"  - {field}")

            # ------------------------------------------------
            # Timestamp analysis
            # ------------------------------------------------

            timestamps = []

            for log in logs.values():

                if not isinstance(log, dict):
                    continue

                timestamp = log.get("Timestamp")

                if timestamp is None:
                    continue

                try:

                    timestamp = float(timestamp)

                    # Seconds → milliseconds
                    if timestamp < 10_000_000_000:
                        timestamp *= 1000

                    timestamps.append(
                        int(timestamp)
                    )

                except (TypeError, ValueError):
                    pass

            if timestamps:

                timestamps.sort()

                first_timestamp = timestamps[0]
                last_timestamp = timestamps[-1]

                first_date = datetime.fromtimestamp(
                    first_timestamp / 1000
                )

                last_date = datetime.fromtimestamp(
                    last_timestamp / 1000
                )

                print("\nTimestamp information:")

                print(
                    f"  First log: "
                    f"{first_date}"
                )

                print(
                    f"  Last log: "
                    f"{last_date}"
                )

                duration = (
                    last_date - first_date
                )

                print(
                    f"  Total time span: "
                    f"{duration}"
                )

                # ------------------------------------------------
                # Sampling interval
                # ------------------------------------------------

                if len(timestamps) > 1:

                    intervals = []

                    for i in range(1, len(timestamps)):

                        diff = (
                            timestamps[i]
                            - timestamps[i - 1]
                        )

                        if diff > 0:
                            intervals.append(diff / 1000)

                    if intervals:

                        intervals.sort()

                        median_interval = intervals[
                            len(intervals) // 2
                        ]

                        average_interval = (
                            sum(intervals)
                            / len(intervals)
                        )

                        print(
                            f"\nSampling interval:"
                        )

                        print(
                            f"  Average: "
                            f"{average_interval:.2f} seconds"
                        )

                        print(
                            f"  Median: "
                            f"{median_interval:.2f} seconds"
                        )


# ============================================================
# SOIL STATUS ANALYSIS
# ============================================================

if isinstance(logs, dict) and logs:

    print("\n" + "=" * 70)
    print("SOIL STATUS ANALYSIS")
    print("=" * 70)

    soil_counts = {}

    for log in logs.values():

        if not isinstance(log, dict):
            continue

        status = log.get("SoilStatus")

        if status is None:
            continue

        status = str(status).strip()

        soil_counts[status] = (
            soil_counts.get(status, 0) + 1
        )

    if soil_counts:

        for status, count in sorted(
            soil_counts.items(),
            key=lambda x: x[1],
            reverse=True
        ):

            percentage = (
                count / sum(soil_counts.values())
            ) * 100

            print(
                f"  {status}: "
                f"{count:,} "
                f"({percentage:.2f}%)"
            )

    else:

        print("No SoilStatus values found.")


# ============================================================
# MISSING DATA ANALYSIS
# ============================================================

if isinstance(logs, dict) and logs:

    print("\n" + "=" * 70)
    print("MISSING DATA ANALYSIS")
    print("=" * 70)

    expected_fields = [
        "Temperature",
        "Humidity",
        "LightIntensity",
        "SoilMoistureRaw",
        "SoilStatus",
        "Timestamp",
    ]

    total_logs = len(logs)

    for field in expected_fields:

        missing = 0

        for log in logs.values():

            if not isinstance(log, dict):
                missing += 1
                continue

            value = log.get(field)

            if value is None:
                missing += 1

        percentage = (
            missing / total_logs
        ) * 100

        print(
            f"  {field}: "
            f"{missing:,} missing "
            f"({percentage:.2f}%)"
        )


# ============================================================
# FINISH
# ============================================================

print("\n" + "=" * 70)
print("INSPECTION COMPLETE")
print("=" * 70)

print(
    "\nNo training was performed."
)

print(
    "No data was modified."
)

print(
    "The original Firebase JSON remains unchanged."
)