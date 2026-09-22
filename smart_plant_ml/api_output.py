import json
from datetime import datetime


def create_ml_output(
    current_soil,
    dry_probability,
    wet_probability,
    horizon_minutes=15
):
    """
    Convert ML prediction into a stable JSON response
    for the Flutter application.
    """

    # Make sure probabilities are valid
    dry_probability = float(dry_probability)
    wet_probability = float(wet_probability)

    # Determine forecast state
    forecast_soil = "DRY" if dry_probability >= wet_probability else "WET"

    # AI recommendation
    if dry_probability >= 0.70:
        recommendation = "Watering may be required soon."
    elif dry_probability >= 0.50:
        recommendation = "Monitor soil moisture. Watering may be required."
    else:
        recommendation = "Soil moisture is expected to remain adequate."

    result = {
        "success": True,
        "timestamp": datetime.now().isoformat(),

        "current": {
            "soil_status": current_soil
        },

        "forecast": {
            "soil_status": forecast_soil,
            "dry_probability": round(dry_probability, 4),
            "wet_probability": round(wet_probability, 4),
            "horizon_minutes": horizon_minutes
        },

        "recommendation": {
            "message": recommendation,
            "pump_activation": False
        }
    }

    return result


if __name__ == "__main__":

    # Example using your current ML result
    output = create_ml_output(
        current_soil="WET",
        dry_probability=0.6850,
        wet_probability=0.3150,
        horizon_minutes=15
    )

    print(json.dumps(output, indent=2))