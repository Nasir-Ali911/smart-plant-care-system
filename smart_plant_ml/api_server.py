from flask import Flask, jsonify
from pathlib import Path
import json
import sys

# Import functions from predict.py
from predict import (
    load_live_logs,
    predict_from_logs,
    create_api_output,
    save_api_output,
)

app = Flask(__name__)

BASE_DIR = Path(__file__).parent
API_OUTPUT_PATH = BASE_DIR / "ml_output.json"


def generate_forecast():
    """
    Generate a fresh ML forecast from Firebase logs.
    This function does NOT activate the pump.
    """

    # Load latest valid Firebase sensor logs
    logs = load_live_logs()

    if not logs:
        return {
            "success": False,
            "error": "No valid sensor logs available from Firebase."
        }

    # Run the existing Random Forest prediction
    result = predict_from_logs(logs)

    if result is None:
        return {
            "success": False,
            "error": "Unable to generate ML prediction."
        }

    # Convert prediction into stable Flutter/API format
    api_result = create_api_output(result)

    # Explicit safety: AI recommendation never activates pump
    api_result["recommendation"]["pump_activation"] = False

    # Save latest result
    save_api_output(api_result)

    return api_result


@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "success": True,
        "service": "Smart Plant Care ML API",
        "status": "running",
        "endpoint": "/api/soil-forecast"
    })


@app.route("/api/soil-forecast", methods=["GET"])
def soil_forecast():
    """
    Flutter calls this endpoint to obtain the latest AI soil forecast.
    """

    try:
        result = generate_forecast()
        return jsonify(result)

    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route("/api/soil-forecast/cached", methods=["GET"])
def cached_forecast():
    """
    Returns the previously generated ml_output.json.

    Useful when you want Flutter to read the last successful
    prediction without running the ML model again.
    """

    try:
        if not API_OUTPUT_PATH.exists():
            return jsonify({
                "success": False,
                "error": "No cached ML output found. Run a forecast first."
            }), 404

        with open(API_OUTPUT_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)

        return jsonify(data)

    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


if __name__ == "__main__":
    print()
    print("=" * 60)
    print("SMART PLANT CARE - AI SOIL FORECAST API")
    print("=" * 60)
    print()
    print("Local API:")
    print("  http://127.0.0.1:5000/api/soil-forecast")
    print()
    print("Cached API:")
    print("  http://127.0.0.1:5000/api/soil-forecast/cached")
    print()
    print("Press CTRL+C to stop the server.")
    print()

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=False
    )