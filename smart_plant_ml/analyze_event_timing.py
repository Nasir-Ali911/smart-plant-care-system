import json
from pathlib import Path
from datetime import datetime
from collections import Counter

DATA_FILE = Path("data/firebase_export.json")

print("=" * 75)
print("SMART PLANT CARE — WATERING EVENT TIMING ANALYSIS")
print("=" * 75)

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

smart_plant = data.get("SmartPlant", {})
logs = smart_plant.get("Logs", {})
watering_events = smart_plant.get("WateringEvents", {})


def parse_timestamp(value):
    if value is None:
        return None

    if isinstance(value, str):
        try:
            return datetime.strptime(value, "%Y-%m-%d %H:%M:%S")
        except ValueError:
            return None

    return None


# ------------------------------------------------------------
# Extract watering events
# ------------------------------------------------------------

events = []

for key, event in watering_events.items():
    if not isinstance(event, dict):
        continue

    timestamp = parse_timestamp(event.get("Timestamp"))

    if timestamp is not None:
        events.append({
            "key": key,
            "timestamp": timestamp,
            "duration_ms": event.get("DurationMs"),
            "temperature": event.get("Temperature"),
            "humidity": event.get("Humidity"),
            "light": event.get("LightIntensity"),
            "soil_raw": event.get("SoilMoistureRaw"),
            "soil_status": event.get("SoilStatus"),
            "reason": event.get("WateringReason"),
        })

events.sort(key=lambda x: x["timestamp"])

print("\nTotal watering events:", len(events))

if not events:
    print("No valid watering timestamps found.")
    raise SystemExit


# ------------------------------------------------------------
# Basic timing
# ------------------------------------------------------------

print("\n" + "=" * 75)
print("EVENT TIME RANGE")
print("=" * 75)

print("First event:")
print(" ", events[0]["timestamp"])

print("Last event:")
print(" ", events[-1]["timestamp"])


# ------------------------------------------------------------
# Calculate intervals
# ------------------------------------------------------------

intervals = []

for i in range(1, len(events)):
    delta = events[i]["timestamp"] - events[i - 1]["timestamp"]
    intervals.append(delta.total_seconds())


print("\n" + "=" * 75)
print("TIME BETWEEN WATERING EVENTS")
print("=" * 75)

if intervals:
    print(f"Minimum interval : {min(intervals):.1f} seconds")
    print(f"Maximum interval : {max(intervals):.1f} seconds")
    print(f"Average interval : {sum(intervals) / len(intervals):.1f} seconds")

    sorted_intervals = sorted(intervals)
    median = sorted_intervals[len(sorted_intervals) // 2]

    print(f"Median interval  : {median:.1f} seconds")

    print("\nFirst 30 intervals:")

    for i, seconds in enumerate(intervals[:30], start=1):
        print(f"  {i:02d}. {seconds:.1f} seconds")


# ------------------------------------------------------------
# Group events into watering sessions
#
# If two events are less than 5 minutes apart,
# consider them part of the same watering session.
# ------------------------------------------------------------

SESSION_GAP_SECONDS = 300

sessions = []
current_session = [events[0]]

for event in events[1:]:

    previous = current_session[-1]

    gap = (
        event["timestamp"] - previous["timestamp"]
    ).total_seconds()

    if gap <= SESSION_GAP_SECONDS:
        current_session.append(event)
    else:
        sessions.append(current_session)
        current_session = [event]

sessions.append(current_session)


print("\n" + "=" * 75)
print("WATERING SESSIONS")
print("=" * 75)

print(
    f"Using {SESSION_GAP_SECONDS} seconds as the maximum "
    f"gap inside one session."
)

print(f"Number of sessions: {len(sessions)}")


for i, session in enumerate(sessions, start=1):

    start = session[0]["timestamp"]
    end = session[-1]["timestamp"]

    duration = (end - start).total_seconds()

    print(
        f"\nSession {i}:"
    )
    print(
        f"  Start events : {start}"
    )
    print(
        f"  End events   : {end}"
    )
    print(
        f"  Events       : {len(session)}"
    )
    print(
        f"  Span         : {duration:.1f} seconds"
    )


# ------------------------------------------------------------
# Events by date
# ------------------------------------------------------------

print("\n" + "=" * 75)
print("EVENTS BY DATE")
print("=" * 75)

date_counter = Counter(
    event["timestamp"].date()
    for event in events
)

for date, count in sorted(date_counter.items()):
    print(f"  {date}: {count}")


# ------------------------------------------------------------
# Events by hour
# ------------------------------------------------------------

print("\n" + "=" * 75)
print("EVENTS BY HOUR")
print("=" * 75)

hour_counter = Counter(
    event["timestamp"].hour
    for event in events
)

for hour in sorted(hour_counter):
    print(
        f"  {hour:02d}:00 - {hour:02d}:59 -> "
        f"{hour_counter[hour]} events"
    )


# ------------------------------------------------------------
# Find sensor logs immediately BEFORE events
# ------------------------------------------------------------

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


print("\n" + "=" * 75)
print("LOGS IMMEDIATELY BEFORE WATERING EVENTS")
print("=" * 75)

for event_number, event in enumerate(events, start=1):

    previous_logs = [
        log
        for log in sensor_logs
        if log["timestamp"] < event["timestamp"]
    ]

    if not previous_logs:
        continue

    previous = previous_logs[-1]

    gap = (
        event["timestamp"] - previous["timestamp"]
    ).total_seconds()

    print(f"\nEvent {event_number}:")
    print(f"  Watering time : {event['timestamp']}")
    print(f"  Previous log  : {previous['timestamp']}")
    print(f"  Gap           : {gap:.1f} seconds")
    print(f"  Temperature   : {previous['temperature']}")
    print(f"  Humidity      : {previous['humidity']}")
    print(f"  Light         : {previous['light']}")
    print(f"  Soil raw      : {previous['soil_raw']}")
    print(f"  Soil status   : {previous['soil_status']}")

    # Only display first 20
    if event_number >= 20:
        break


print("\n" + "=" * 75)
print("EVENT TIMING ANALYSIS COMPLETE")
print("=" * 75)

print("\nNo data was modified.")