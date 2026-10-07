
"""
Smart Plant Care - Production Notification Engine

Responsibilities:
    1. Read notification settings from Firebase RTDB.
    2. Read FCM tokens from Firestore.
    3. Decide whether the ML prediction requires an alert.
    4. Prevent duplicate/repeated alerts.
    5. Send production FCM notifications.
    6. Save successfully-sent notifications to:
           Users/{uid}/Notifications

Notification category currently supported:
    Soil Moisture -> soilMoisture

The engine does NOT activate the physical pump.
"""

from datetime import datetime, timezone
from pathlib import Path

import firebase_admin
from firebase_admin import credentials
from firebase_admin import db
from firebase_admin import firestore
from firebase_admin import messaging


# ============================================================
# FIREBASE CONFIGURATION
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

RENDER_SERVICE_ACCOUNT_PATH = Path(
    "/etc/secrets/firebase-service-account.json"
)

LOCAL_SERVICE_ACCOUNT_PATH = (
    BASE_DIR / "firebase-service-account.json"
)

if RENDER_SERVICE_ACCOUNT_PATH.exists():
    SERVICE_ACCOUNT_PATH = RENDER_SERVICE_ACCOUNT_PATH
else:
    SERVICE_ACCOUNT_PATH = LOCAL_SERVICE_ACCOUNT_PATH

DATABASE_URL = (
    "https://smart-plant-care-fyp-2026-default-rtdb.firebaseio.com"
)


# ============================================================
# NOTIFICATION CONFIGURATION
# ============================================================

SOIL_CATEGORY = "Soil"
SOIL_TYPE = "AI Soil Forecast"

LOWER_DRY_THRESHOLD = 0.50
HIGH_DRY_THRESHOLD = 0.70

NOTIFICATION_CHANNEL_ID = "smart_plant_care_alerts"


# ============================================================
# FIREBASE INITIALIZATION
# ============================================================

def initialize_firebase():
    """
    Initialize Firebase Admin SDK exactly once.
    """

    if firebase_admin._apps:
        return firebase_admin.get_app()

    if not SERVICE_ACCOUNT_PATH.exists():
        raise FileNotFoundError(
            "Firebase service-account file not found:\n"
            f"{SERVICE_ACCOUNT_PATH}"
        )

    print(
        "NOTIFICATION ENGINE: "
        f"Using Firebase credentials from: "
        f"{SERVICE_ACCOUNT_PATH}"
    )

    cred = credentials.Certificate(
        str(SERVICE_ACCOUNT_PATH)
    )

    return firebase_admin.initialize_app(
        cred,
        {
            "databaseURL": DATABASE_URL,
        },
    )


# ============================================================
# FIREBASE CLIENTS
# ============================================================

def get_firestore_client():
    """
    Return the Firebase Admin Firestore client.
    """

    initialize_firebase()
    return firestore.client()


# ============================================================
# NOTIFICATION SETTINGS
# ============================================================

def get_notification_settings(uid):
    """
    Read notification settings from:

        Users/{uid}/NotificationSettings

    Default behavior is ON if settings do not exist.
    """

    initialize_firebase()

    default_settings = {
        "enabled": True,
        "soilMoisture": True,
        "irrigation": True,
        "environmental": True,
        "deviceAlerts": True,
    }

    try:
        data = db.reference(
            f"/Users/{uid}/NotificationSettings"
        ).get()

        if not isinstance(data, dict):
            return default_settings

        settings = default_settings.copy()

        for key in default_settings:
            if key in data:
                settings[key] = bool(data[key])

        return settings

    except Exception as error:
        print(
            "NOTIFICATION SETTINGS ERROR "
            f"for {uid}: {error}"
        )

        # Fail closed:
        # If settings cannot be read, do not send.
        return {
            "enabled": False,
            "soilMoisture": False,
            "irrigation": False,
            "environmental": False,
            "deviceAlerts": False,
        }


# ============================================================
# CATEGORY PERMISSION
# ============================================================

def soil_notifications_enabled(uid):
    """
    Check both:

        enabled
        soilMoisture

    before sending an AI soil notification.
    """

    settings = get_notification_settings(uid)

    return bool(
        settings.get("enabled", False)
        and settings.get("soilMoisture", False)
    )


# ============================================================
# FCM TOKEN
# ============================================================

def get_user_fcm_token(user_document):
    """
    Extract the FCM token from a Firestore user document.

    NotificationService saves:

        fcmToken
        fcmTokenUpdatedAt
    """

    data = user_document.to_dict()

    if not isinstance(data, dict):
        return None

    token = data.get("fcmToken")

    if token is None:
        return None

    token = str(token).strip()

    if not token:
        return None

    return token


# ============================================================
# NOTIFICATION BAND
# ============================================================

def get_soil_alert_band(dry_probability):
    """
    Convert dry probability into a stable alert state.

        < 0.50
            NONE

        0.50 - 0.6999
            MEDIUM

        >= 0.70
            HIGH
    """

    dry_probability = float(dry_probability)

    if dry_probability >= HIGH_DRY_THRESHOLD:
        return "HIGH"

    if dry_probability >= LOWER_DRY_THRESHOLD:
        return "MEDIUM"

    return "NONE"


# ============================================================
# ALERT CONTENT
# ============================================================

def build_soil_notification(
    dry_probability,
    forecast_soil,
):
    """
    Build notification title/body/priority
    from the ML prediction.
    """

    dry_probability = float(dry_probability)

    percentage = round(
        dry_probability * 100
    )

    band = get_soil_alert_band(
        dry_probability
    )

    if band == "HIGH":

        title = (
            "Smart Plant Care - "
            "Watering Alert"
        )

        body = (
            f"AI forecasts the soil may become "
            f"dry within the next 15 minutes "
            f"({percentage}% dry probability). "
            "Watering may be required soon."
        )

        priority = "HIGH"

    elif band == "MEDIUM":

        title = (
            "Smart Plant Care - "
            "Soil Moisture Warning"
        )

        body = (
            f"AI forecasts a {percentage}% "
            "probability of dry soil within "
            "the next 15 minutes. "
            "Monitor soil moisture."
        )

        priority = "MEDIUM"

    else:
        return None

    return {
        "band": band,
        "title": title,
        "body": body,
        "priority": priority,
        "category": SOIL_CATEGORY,
        "type": SOIL_TYPE,
        "forecast_soil": str(forecast_soil),
        "dry_probability": dry_probability,
    }


# ============================================================
# DUPLICATE STATE
# ============================================================

def get_notification_state(uid):
    """
    Read the last soil notification state from:

        Users/{uid}/NotificationState/aiSoilForecast
    """

    initialize_firebase()

    try:
        data = db.reference(
            f"/Users/{uid}/NotificationState/"
            "aiSoilForecast"
        ).get()

        if isinstance(data, dict):
            return data

    except Exception as error:
        print(
            "NOTIFICATION STATE READ ERROR "
            f"for {uid}: {error}"
        )

    return {}


def save_notification_state(
    uid,
    band,
    event_id,
    sensor_timestamp,
):
    """
    Save the current notification state.
    """

    initialize_firebase()

    state = {
        "band": band,
        "eventId": event_id,
        "sensorTimestamp": str(
            sensor_timestamp
        ),
        "updatedAt": datetime.now(
            timezone.utc
        ).isoformat(),
    }

    db.reference(
        f"/Users/{uid}/NotificationState/"
        "aiSoilForecast"
    ).set(state)


def should_send_soil_alert(
    uid,
    band,
    event_id,
):
    """
    Prevent duplicate notifications.

    Rules:

        NONE
            -> no notification

        First MEDIUM
            -> send

        First HIGH
            -> send

        MEDIUM -> HIGH
            -> send immediately

        HIGH -> HIGH
            -> suppress

        MEDIUM -> MEDIUM
            -> suppress

        Any previous state -> NONE
            -> reset

    This prevents a scheduler from sending the same
    alert repeatedly on every execution.
    """

    if band == "NONE":
        return False

    state = get_notification_state(uid)

    previous_band = str(
        state.get("band", "NONE")
    ).upper()

    previous_event_id = str(
        state.get("eventId", "")
    )

    # Exact same prediction event was already handled.
    if previous_event_id == event_id:
        return False

    # First alert after normal state.
    if previous_band == "NONE":
        return True

    # Escalation from medium to high.
    if (
        previous_band == "MEDIUM"
        and band == "HIGH"
    ):
        return True

    # Same alert level is suppressed.
    return False


# ============================================================
# WRITE NOTIFICATION HISTORY
# ============================================================

def save_notification_history(
    uid,
    notification,
    event_id,
    sensor_timestamp,
):
    """
    Save notification history to:

        Users/{uid}/Notifications

    This is the same RTDB location used by
    NotificationsScreen and NotificationHistoryService.
    """

    initialize_firebase()

    notification_data = {
        "title": notification["title"],
        "message": notification["body"],
        "category": notification["category"],
        "priority": notification["priority"],
        "type": notification["type"],
        "timestamp": datetime.now(
            timezone.utc
        ).isoformat(),
        "isRead": False,
        "messageId": event_id,
        "eventId": event_id,
        "sensorTimestamp": str(
            sensor_timestamp
        ),
        "dryProbability": notification[
            "dry_probability"
        ],
        "forecastSoil": notification[
            "forecast_soil"
        ],
    }

    ref = db.reference(
        f"/Users/{uid}/Notifications"
    )

    new_ref = ref.push(
        notification_data
    )

    return new_ref.key


# ============================================================
# SEND FCM
# ============================================================

def send_fcm_notification(
    token,
    notification,
    event_id,
):
    """
    Send a production FCM notification.

    The message contains both:
        notification
        data

    This allows Android to display the notification
    automatically in the background while Flutter can
    inspect the data when the app is active.
    """

    android_priority = (
        "high"
        if notification["priority"] == "HIGH"
        else "normal"
    )

    message = messaging.Message(
        token=token,

        notification=messaging.Notification(
            title=notification["title"],
            body=notification["body"],
        ),

        data={
            "eventId": event_id,
            "type": notification["type"],
            "category": notification["category"],
            "priority": notification["priority"],
            "title": notification["title"],
            "body": notification["body"],
            "dryProbability": str(
                notification["dry_probability"]
            ),
            "forecastSoil": str(
                notification["forecast_soil"]
            ),
        },

        android=messaging.AndroidConfig(
            priority=android_priority,

            notification=messaging.AndroidNotification(
                channel_id=NOTIFICATION_CHANNEL_ID,

                priority=(
                    "max"
                    if notification["priority"] == "HIGH"
                    else "high"
                ),

                sound="default",
                icon="@mipmap/ic_launcher",
            ),
        ),
    )

    return messaging.send(message)


# ============================================================
# PROCESS ONE USER
# ============================================================

def process_user(
    uid,
    user_document,
    prediction,
):
    """
    Process one authenticated user's notification.
    """

    print()
    print("----------------------------------------")
    print(f"NOTIFICATION USER: {uid}")

    # --------------------------------------------------------
    # Notification settings
    # --------------------------------------------------------

    if not soil_notifications_enabled(uid):

        print(
            "NOTIFICATION: Soil notifications "
            "are disabled."
        )

        return False

    # --------------------------------------------------------
    # FCM token
    # --------------------------------------------------------

    token = get_user_fcm_token(
        user_document
    )

    if not token:

        print(
            "NOTIFICATION: No FCM token."
        )

        return False

    # --------------------------------------------------------
    # Prediction values
    # --------------------------------------------------------

    forecast = prediction.get(
        "forecast",
        {}
    )

    if not isinstance(forecast, dict):
        forecast = {}

    try:
        dry_probability = float(
            forecast.get(
                "dry_probability",
                0.0
            )
        )
    except (TypeError, ValueError):
        dry_probability = 0.0

    # Keep probability inside the valid range.
    dry_probability = max(
        0.0,
        min(1.0, dry_probability)
    )

    forecast_soil = str(
        forecast.get(
            "soil_status",
            "UNKNOWN"
        )
    )

    sensor_timestamp = prediction.get(
        "timestamp",
        datetime.now(
            timezone.utc
        ).isoformat()
    )

    # --------------------------------------------------------
    # Determine alert
    # --------------------------------------------------------

    notification = build_soil_notification(
        dry_probability=dry_probability,
        forecast_soil=forecast_soil,
    )

    if notification is None:

        # Prediction is below notification threshold.
        #
        # Reset state so a future transition into
        # MEDIUM/HIGH can notify again.

        save_notification_state(
            uid=uid,
            band="NONE",
            event_id="",
            sensor_timestamp=sensor_timestamp,
        )

        print(
            "NOTIFICATION: No soil alert required."
        )

        return False

    band = notification["band"]

    # --------------------------------------------------------
    # Stable event ID
    # --------------------------------------------------------

    event_id = (
        "ai_soil_"
        f"{band.lower()}_"
        f"{str(sensor_timestamp)}"
    )

    # --------------------------------------------------------
    # Duplicate protection
    # --------------------------------------------------------

    if not should_send_soil_alert(
        uid=uid,
        band=band,
        event_id=event_id,
    ):

        print(
            "NOTIFICATION: Duplicate/repeated "
            "alert suppressed."
        )

        return False

    # --------------------------------------------------------
    # Send FCM
    # --------------------------------------------------------

    try:

        fcm_message_id = send_fcm_notification(
            token=token,
            notification=notification,
            event_id=event_id,
        )

        print(
            "NOTIFICATION: FCM sent successfully."
        )

        print(
            f"FCM message ID: {fcm_message_id}"
        )

    except (
        messaging.UnregisteredError,
        messaging.SenderIdMismatchError,
    ) as error:

        print(
            "NOTIFICATION: FCM token is invalid "
            f"for {uid}: {error}"
        )

        return False

    except Exception as error:

        print(
            "NOTIFICATION: FCM send failed "
            f"for {uid}: {error}"
        )

        return False

    # --------------------------------------------------------
    # Save notification history
    # --------------------------------------------------------

    try:

        history_id = save_notification_history(
            uid=uid,
            notification=notification,
            event_id=event_id,
            sensor_timestamp=sensor_timestamp,
        )

        print(
            "NOTIFICATION: History saved."
        )

        print(
            f"History ID: {history_id}"
        )

    except Exception as error:

        print(
            "NOTIFICATION HISTORY ERROR "
            f"for {uid}: {error}"
        )

    # --------------------------------------------------------
    # Save duplicate state
    # --------------------------------------------------------

    try:

        save_notification_state(
            uid=uid,
            band=band,
            event_id=event_id,
            sensor_timestamp=sensor_timestamp,
        )

    except Exception as error:

        print(
            "NOTIFICATION STATE SAVE ERROR "
            f"for {uid}: {error}"
        )

    return True


# ============================================================
# MAIN PRODUCTION NOTIFICATION ENGINE
# ============================================================

def send_production_notifications(
    prediction
):
    """
    Send the supplied ML prediction to all eligible
    authenticated users.

    Expected input is the output returned by:

        create_api_output()

    Returns a summary dictionary.
    """

    initialize_firebase()

    if not isinstance(prediction, dict):
        raise ValueError(
            "Prediction must be a dictionary."
        )

    if not prediction.get("success", False):

        print(
            "NOTIFICATION ENGINE: "
            "Prediction is not successful."
        )

        return {
            "success": False,
            "sent": 0,
            "skipped": 0,
            "error": "Invalid prediction.",
        }

    firestore_client = get_firestore_client()

    users = firestore_client.collection(
        "users"
    ).stream()

    sent = 0
    skipped = 0
    total_users = 0

    for user_document in users:

        total_users += 1
        uid = user_document.id

        try:

            was_sent = process_user(
                uid=uid,
                user_document=user_document,
                prediction=prediction,
            )

            if was_sent:
                sent += 1
            else:
                skipped += 1

        except Exception as error:

            skipped += 1

            print(
                "NOTIFICATION USER ERROR "
                "for {uid}: {error}"
            )

    summary = {
        "success": True,
        "total_users": total_users,
        "sent": sent,
        "skipped": skipped,
    }

    print()
    print("========================================")
    print("NOTIFICATION ENGINE SUMMARY")
    print("========================================")
    print(f"Users:   {total_users}")
    print(f"Sent:    {sent}")
    print(f"Skipped: {skipped}")
    print("========================================")

    return summary
