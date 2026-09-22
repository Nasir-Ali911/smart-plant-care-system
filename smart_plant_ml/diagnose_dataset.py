import json
import pandas as pd
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
DATA_FILE = BASE_DIR / "data" / "firebase_export.json"


print("=" * 70)
print("SMART PLANT CARE - DATASET DIAGNOSTIC")
print("=" * 70)


# ============================================================
# LOAD
# ============================================================

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

logs = data["SmartPlant"]["Logs"]

print(f"\nRaw log entries: {len(logs):,}")


# ============================================================
# EXTRACT EVERYTHING
# ============================================================

records = []

for key, value in logs.items():

    if not isinstance(value, dict):
        continue

    records.append({
        "key": key,
        "Timestamp": value.get("Timestamp"),
        "Temperature": value.get("Temperature"),
        "Humidity": value.get("Humidity"),
        "LightIntensity": value.get("LightIntensity"),
        "SoilMoistureRaw": value.get("SoilMoistureRaw"),
        "SoilStatus": value.get("SoilStatus"),
    })


df = pd.DataFrame(records)


# ============================================================
# BASIC COUNTS
# ============================================================

print("\n" + "=" * 70)
print("BASIC COUNTS")
print("=" * 70)

print(f"Total records              : {len(df):,}")

print(
    f"Missing Timestamp          : "
    f"{df['Timestamp'].isna().sum():,}"
)

print(
    f"Missing Temperature        : "
    f"{df['Temperature'].isna().sum():,}"
)

print(
    f"Missing Humidity           : "
    f"{df['Humidity'].isna().sum():,}"
)

print(
    f"Missing LightIntensity     : "
    f"{df['LightIntensity'].isna().sum():,}"
)

print(
    f"Missing SoilMoistureRaw    : "
    f"{df['SoilMoistureRaw'].isna().sum():,}"
)


# ============================================================
# NUMERIC CONVERSION
# ============================================================

for column in [
    "Temperature",
    "Humidity",
    "LightIntensity",
    "SoilMoistureRaw",
]:

    df[column + "_numeric"] = pd.to_numeric(
        df[column],
        errors="coerce"
    )


# ============================================================
# INVALID VALUES
# ============================================================

print("\n" + "=" * 70)
print("INVALID / SPECIAL VALUES")
print("=" * 70)


print(
    "Temperature == 0:",
    (
        df["Temperature_numeric"] == 0
    ).sum()
)

print(
    "Humidity == 0:",
    (
        df["Humidity_numeric"] == 0
    ).sum()
)

print(
    "Temperature == 0 AND Humidity == 0:",
    (
        (df["Temperature_numeric"] == 0)
        &
        (df["Humidity_numeric"] == 0)
    ).sum()
)

print(
    "SoilMoistureRaw == 0:",
    (
        df["SoilMoistureRaw_numeric"] == 0
    ).sum()
)

print(
    "SoilMoistureRaw == 1:",
    (
        df["SoilMoistureRaw_numeric"] == 1
    ).sum()
)

print(
    "SoilMoistureRaw other values:",
    (
        ~df["SoilMoistureRaw_numeric"]
        .isin([0, 1])
        &
        df["SoilMoistureRaw_numeric"]
        .notna()
    ).sum()
)


# ============================================================
# TIMESTAMP ANALYSIS
# ============================================================

df["ParsedTimestamp"] = pd.to_datetime(
    df["Timestamp"],
    errors="coerce"
)

print("\n" + "=" * 70)
print("TIMESTAMP")
print("=" * 70)

print(
    "Invalid timestamps:",
    df["ParsedTimestamp"].isna().sum()
)

valid_dates = df[
    df["ParsedTimestamp"].notna()
]["ParsedTimestamp"]

if len(valid_dates) > 0:

    print(
        "First:",
        valid_dates.min()
    )

    print(
        "Last :",
        valid_dates.max()
    )


# ============================================================
# APPLY DIFFERENT CLEANING STEPS
# ============================================================

print("\n" + "=" * 70)
print("CLEANING STEP COUNTS")
print("=" * 70)


step1 = df[
    df["ParsedTimestamp"].notna()
].copy()

print(
    f"1. Valid timestamp       : {len(step1):,}"
)


step2 = step1[
    step1["Temperature_numeric"].notna()
    &
    step1["Humidity_numeric"].notna()
    &
    step1["LightIntensity_numeric"].notna()
    &
    step1["SoilMoistureRaw_numeric"].notna()
].copy()

print(
    f"2. All required numeric  : {len(step2):,}"
)


step3 = step2[
    ~(
        (step2["Temperature_numeric"] == 0)
        &
        (step2["Humidity_numeric"] == 0)
    )
].copy()

print(
    f"3. Remove Temp=0/Hum=0  : {len(step3):,}"
)


step4 = step3[
    step3["SoilMoistureRaw_numeric"].isin(
        [0, 1]
    )
].copy()

print(
    f"4. Soil state 0/1 only   : {len(step4):,}"
)


# ============================================================
# DUPLICATE TIMESTAMPS
# ============================================================

print("\n" + "=" * 70)
print("DUPLICATE TIMESTAMPS")
print("=" * 70)

duplicates = (
    step4["ParsedTimestamp"]
    .duplicated(keep=False)
)

print(
    "Records sharing timestamp:",
    duplicates.sum()
)

print(
    "Unique timestamps:",
    step4["ParsedTimestamp"].nunique()
)


# ============================================================
# DUPLICATE COMPLETE RECORDS
# ============================================================

print("\n" + "=" * 70)
print("DUPLICATE SENSOR RECORDS")
print("=" * 70)

duplicate_sensor_rows = (
    step4[
        [
            "ParsedTimestamp",
            "Temperature_numeric",
            "Humidity_numeric",
            "LightIntensity_numeric",
            "SoilMoistureRaw_numeric",
        ]
    ]
    .duplicated(keep=False)
)

print(
    "Duplicate sensor rows:",
    duplicate_sensor_rows.sum()
)


# ============================================================
# SOIL DISTRIBUTION
# ============================================================

print("\n" + "=" * 70)
print("SOIL DISTRIBUTION")
print("=" * 70)

print(
    step4["SoilMoistureRaw_numeric"]
    .value_counts()
    .sort_index()
)


# ============================================================
# DAILY DISTRIBUTION
# ============================================================

print("\n" + "=" * 70)
print("DAILY DISTRIBUTION")
print("=" * 70)

step4["Date"] = (
    step4["ParsedTimestamp"]
    .dt.date
)

daily = (
    step4
    .groupby("Date")
    ["SoilMoistureRaw_numeric"]
    .agg(
        total="count",
        wet=lambda x: (x == 0).sum(),
        dry=lambda x: (x == 1).sum(),
    )
)

daily["dry_percent"] = (
    daily["dry"]
    / daily["total"]
    * 100
)

print(
    daily.to_string()
)


# ============================================================
# HOURLY DISTRIBUTION
# ============================================================

print("\n" + "=" * 70)
print("HOURLY DISTRIBUTION")
print("=" * 70)

step4["Hour"] = (
    step4["ParsedTimestamp"].dt.hour
)

hourly = (
    step4
    .groupby("Hour")
    ["SoilMoistureRaw_numeric"]
    .agg(
        total="count",
        wet=lambda x: (x == 0).sum(),
        dry=lambda x: (x == 1).sum(),
    )
)

hourly["dry_percent"] = (
    hourly["dry"]
    / hourly["total"]
    * 100
)

print(
    hourly.to_string()
)


# ============================================================
# FINAL SUMMARY
# ============================================================

print("\n" + "=" * 70)
print("FINAL SUMMARY")
print("=" * 70)

print(
    f"""
Raw records                  : {len(df):,}
Valid timestamps              : {len(step1):,}
Required numeric fields      : {len(step2):,}
After invalid sensor removal : {len(step3):,}
Valid soil states             : {len(step4):,}

Removed by invalid sensor rule:
{len(step2) - len(step3):,}

Removed by soil-state rule:
{len(step3) - len(step4):,}
"""
)

print("=" * 70)
print("DIAGNOSTIC COMPLETE")
print("=" * 70)