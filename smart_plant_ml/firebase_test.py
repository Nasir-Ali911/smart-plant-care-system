import firebase_admin
from firebase_admin import credentials, db


SERVICE_ACCOUNT = "firebase-service-account.json"

DATABASE_URL = (
    "https://smart-plant-care-fyp-2026-default-rtdb.firebaseio.com"
)


def main():
    print("Initializing Firebase...")

    cred = credentials.Certificate(SERVICE_ACCOUNT)

    firebase_admin.initialize_app(
        cred,
        {
            "databaseURL": DATABASE_URL,
        },
    )

    print("Firebase initialized successfully.")

    smart_plant = db.reference("/SmartPlant").get()

    print()
    print("SMARTPLANT DATA")
    print("----------------")

    if smart_plant is None:
        print("No data found at /SmartPlant")
        return

    for key, value in smart_plant.items():
        if key == "Control":
            print(f"{key}: [control data]")
        else:
            print(f"{key}: {value}")


if __name__ == "__main__":
    main()