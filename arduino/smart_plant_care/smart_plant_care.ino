// ============================================================
// SMART PLANT CARE SYSTEM
// ESP8266 + DHT22 + LDR + Soil Moisture + Relay + Firebase
// ============================================================
//
// Firmware Version: v1.3.6-ml-data-logging-fixed
//
// IMPORTANT CHANGE FROM v1.3.5:
// - Automatic watering occurs ONCE per DRY episode.
// - After watering, automatic watering is locked.
// - Lock is released only when soil becomes WET.
// - Prevents repeated pump activation every ~30-60 seconds.
//
// PURPOSE:
// - Sensor data collection
// - Real-time Firebase monitoring
// - Automatic irrigation
// - Manual pump control from Flutter
// - ML-ready historical data
// - Explicit watering-event logging
//
// WIRING:
// - LDR AOUT        -> A0
// - Soil DOUT       -> D7
// - DHT22 DATA      -> D5
// - Relay IN        -> D1
//
// SOIL SENSOR:
// - HIGH = DRY
// - LOW  = WET
//
// LDR:
// - > 500  = DARK
// - <= 500 = BRIGHT
//
// FIREBASE PATHS:
// - /SmartPlant
// - /SmartPlant/Device
// - /SmartPlant/Logs
// - /SmartPlant/WateringEvents
// - /SmartPlant/Control/PumpManual
//
// ============================================================


// ============================================================
// LIBRARIES
// ============================================================

#include <ESP8266WiFi.h>
#include <DHT.h>
#include <FirebaseESP8266.h>
#include <addons/TokenHelper.h>
#include <time.h>


// ============================================================
// FIRMWARE VERSION
// ============================================================

#define FIRMWARE_VERSION "v1.3.6-ml-data-logging-fixed"


// ============================================================
// WIFI CONFIGURATION
// ============================================================
// Enter your existing Wi-Fi credentials here.
// Do NOT upload real credentials to GitHub.

#define WIFI_SSID "Infinix NOTE 40"
#define WIFI_PASSWORD "124124125"


// ============================================================
// FIREBASE CONFIGURATION
// ============================================================

#define FIREBASE_HOST "https://smart-plant-care-fyp-2026-default-rtdb.firebaseio.com"
#define FIREBASE_API_KEY "AIzaSyBPoUhpPEE-15YPx7AfJa1OU45ayBgYSPA"


// ============================================================
// FIREBASE OBJECTS
// ============================================================

FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;


// ============================================================
// AUTHENTICATION STATUS
// ============================================================

bool isAuthenticated = false;


// ============================================================
// PIN DEFINITIONS
// ============================================================

#define DHT_PIN D5
#define DHT_TYPE DHT22

#define SOIL_PIN D7

#define LDR_PIN A0

#define RELAY_PIN D1


// ============================================================
// SENSOR OBJECT
// ============================================================

DHT dht(DHT_PIN, DHT_TYPE);


// ============================================================
// TIMING
// ============================================================

// Sensor reading every 10 seconds
const unsigned long SENSOR_INTERVAL = 10000;

// Firebase historical log every 60 seconds
const unsigned long HISTORY_INTERVAL = 60000;

// Wi-Fi connection timeout
const unsigned long WIFI_TIMEOUT = 20000;

// Retry Wi-Fi every 5 seconds
const unsigned long WIFI_RETRY_DELAY = 5000;

// Pump duration
const unsigned long PUMP_WATER_DURATION = 3000;

// Manual command check every second
const unsigned long CONTROL_CHECK_INTERVAL = 1000;


// ============================================================
// TIMESTAMP VARIABLES
// ============================================================

unsigned long lastSensorRead = 0;
unsigned long lastHistoryUpload = 0;
unsigned long lastWiFiRetry = 0;
unsigned long lastControlCheck = 0;


// ============================================================
// WATERING STATE
// ============================================================

// True while pump is physically running
bool wateringInProgress = false;

// IMPORTANT:
// Once automatic watering happens while soil is DRY,
// this becomes true.
//
// It prevents another automatic watering until the soil
// becomes WET.
//
// This is the main fix for the repeated watering problem.
bool automaticWateringLocked = false;


// ============================================================
// SENSOR VARIABLES
// ============================================================

float temperature = 0.0;
float humidity = 0.0;

int lightValue = 0;

// Digital soil sensor value.
// HIGH = DRY
// LOW  = WET
int soilMoistureRaw = 0;

String soilStatus = "UNKNOWN";
String lightStatus = "UNKNOWN";

String currentRelayStatus = "OFF";

String currentPumpState = "OFF";


// ============================================================
// FUNCTION DECLARATIONS
// ============================================================

void connectWiFi();
void initializeFirebase();

bool readDHTSensor();
void readSensors();

void checkManualWatering();
void checkAndWaterPlant();

void runWateringCycle(const char* reason);

void uploadSensorData();
void uploadHistory();
void uploadWateringEvent(
  const char* reason,
  unsigned long duration
);

void uploadDeviceInformation();

String getTimestamp();

void relayON();
void relayOFF();


// ============================================================
// SETUP
// ============================================================

void setup()
{
  Serial.begin(115200);

  delay(1000);

  Serial.println();
  Serial.println("================================================");
  Serial.println("       SMART PLANT CARE SYSTEM");
  Serial.println("       ML DATA COLLECTION MODE");
  Serial.println("================================================");

  Serial.print("Firmware: ");
  Serial.println(FIRMWARE_VERSION);

  Serial.println();


  // ----------------------------------------------------------
  // GPIO INITIALIZATION
  // ----------------------------------------------------------

  pinMode(SOIL_PIN, INPUT);

  pinMode(LDR_PIN, INPUT);


  // ----------------------------------------------------------
  // RELAY INITIALIZATION
  // ----------------------------------------------------------

  pinMode(RELAY_PIN, OUTPUT);

  // Active LOW relay
  // HIGH = OFF
  relayOFF();

  Serial.println("Relay initialized.");
  Serial.println("Relay state: OFF");


  // ----------------------------------------------------------
  // DHT22 INITIALIZATION
  // ----------------------------------------------------------

  Serial.println("Initializing DHT22...");

  dht.begin();

  delay(2000);

  Serial.println("DHT22 initialized.");


  // ----------------------------------------------------------
  // WIFI
  // ----------------------------------------------------------

  connectWiFi();


  // ----------------------------------------------------------
  // NTP
  // ----------------------------------------------------------

  Serial.println();
  Serial.println("Initializing NTP...");

  configTime(
    5 * 3600,
    0,
    "pool.ntp.org",
    "time.nist.gov"
  );

  Serial.println("NTP initialized.");


  // ----------------------------------------------------------
  // FIREBASE
  // ----------------------------------------------------------

  if (WiFi.status() == WL_CONNECTED)
  {
    initializeFirebase();
  }
  else
  {
    Serial.println();
    Serial.println("WiFi not connected.");
    Serial.println("Firebase initialization skipped.");
  }


  // ----------------------------------------------------------
  // DEVICE INFORMATION
  // ----------------------------------------------------------

  if (WiFi.status() == WL_CONNECTED &&
      isAuthenticated &&
      Firebase.ready())
  {
    uploadDeviceInformation();
  }
  else
  {
    Serial.println();
    Serial.println("Firebase not ready yet.");
    Serial.println("Device information upload deferred.");
  }


  // ----------------------------------------------------------
  // INITIALIZE TIMERS
  // ----------------------------------------------------------

  lastSensorRead = millis();
  lastHistoryUpload = millis();
  lastWiFiRetry = millis();
  lastControlCheck = millis();


  // ----------------------------------------------------------
  // STARTUP MESSAGE
  // ----------------------------------------------------------

  Serial.println();
  Serial.println("================================================");
  Serial.println("SYSTEM READY");
  Serial.println("AUTOMATIC WATERING PROTECTION: ENABLED");
  Serial.println("ONE WATERING EVENT PER DRY EPISODE");
  Serial.println("================================================");
  Serial.println();
}


// ============================================================
// MAIN LOOP
// ============================================================

void loop()
{
  bool firebaseReady = false;


  // ----------------------------------------------------------
  // FIREBASE READINESS
  // ----------------------------------------------------------

  if (WiFi.status() == WL_CONNECTED &&
      isAuthenticated)
  {
    firebaseReady = Firebase.ready();
  }


  // ----------------------------------------------------------
  // MANUAL PUMP COMMAND
  // ----------------------------------------------------------

  if (firebaseReady &&
      millis() - lastControlCheck >= CONTROL_CHECK_INTERVAL)
  {
    lastControlCheck = millis();

    checkManualWatering();
  }


  // ----------------------------------------------------------
  // WIFI MONITORING
  // ----------------------------------------------------------

  if (WiFi.status() != WL_CONNECTED)
  {
    Serial.println();
    Serial.println("WiFi disconnected.");

    if (millis() - lastWiFiRetry >= WIFI_RETRY_DELAY)
    {
      lastWiFiRetry = millis();

      connectWiFi();
    }

    delay(100);

    return;
  }


  // ----------------------------------------------------------
  // SENSOR INTERVAL
  // ----------------------------------------------------------

  if (millis() - lastSensorRead < SENSOR_INTERVAL)
  {
    delay(100);

    return;
  }

  lastSensorRead = millis();


  // ----------------------------------------------------------
  // READ SENSORS
  // ----------------------------------------------------------

  readSensors();


  // ----------------------------------------------------------
  // AUTOMATIC WATERING
  // ----------------------------------------------------------

  checkAndWaterPlant();


  // ----------------------------------------------------------
  // SERIAL MONITOR
  // ----------------------------------------------------------

  Serial.println();
  Serial.println("------------------------------------------------");
  Serial.println("SENSOR DATA");
  Serial.println("------------------------------------------------");

  Serial.print("Temperature : ");
  Serial.print(temperature, 2);
  Serial.println(" °C");

  Serial.print("Humidity    : ");
  Serial.print(humidity, 2);
  Serial.println(" %");

  Serial.print("Light Raw   : ");
  Serial.println(lightValue);

  Serial.print("Light       : ");
  Serial.println(lightStatus);

  Serial.print("Soil Raw    : ");
  Serial.println(soilMoistureRaw);

  Serial.print("Soil        : ");
  Serial.println(soilStatus);

  Serial.print("Relay       : ");
  Serial.println(currentRelayStatus);

  Serial.print("Pump        : ");
  Serial.println(currentPumpState);

  Serial.print("Auto Lock   : ");
  Serial.println(
    automaticWateringLocked ? "LOCKED" : "READY"
  );

  Serial.println("------------------------------------------------");


  // ----------------------------------------------------------
  // AUTHENTICATION CHECK
  // ----------------------------------------------------------

  if (!isAuthenticated)
  {
    Serial.println(
      "Firebase authentication was not initialized."
    );

    Serial.println("Skipping Firebase upload.");

    delay(100);

    return;
  }


  // ----------------------------------------------------------
  // FIREBASE READINESS CHECK
  // ----------------------------------------------------------

  if (!firebaseReady)
  {
    Serial.println("Firebase not ready.");

    Serial.println(
      "Skipping Firebase upload for this cycle."
    );

    delay(100);

    return;
  }


  // ----------------------------------------------------------
  // UPLOAD CURRENT SENSOR DATA
  // ----------------------------------------------------------

  uploadSensorData();


  // ----------------------------------------------------------
  // UPLOAD HISTORY
  // ----------------------------------------------------------

  if (millis() - lastHistoryUpload >= HISTORY_INTERVAL)
  {
    lastHistoryUpload = millis();

    uploadHistory();
  }


  delay(100);
}


// ============================================================
// CONNECT TO WIFI
// ============================================================

void connectWiFi()
{
  Serial.println();
  Serial.println("================================================");
  Serial.println("CONNECTING TO WIFI");
  Serial.println("================================================");

  Serial.print("SSID: ");
  Serial.println(WIFI_SSID);

  WiFi.mode(WIFI_STA);

  WiFi.begin(
    WIFI_SSID,
    WIFI_PASSWORD
  );

  unsigned long startAttemptTime = millis();


  while (
    WiFi.status() != WL_CONNECTED &&
    millis() - startAttemptTime < WIFI_TIMEOUT
  )
  {
    delay(500);

    Serial.print(".");
  }


  Serial.println();


  if (WiFi.status() == WL_CONNECTED)
  {
    Serial.println("WiFi connected.");

    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    Serial.print("RSSI: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
  }
  else
  {
    Serial.println("WiFi connection failed.");
  }
}


// ============================================================
// INITIALIZE FIREBASE
// ============================================================

void initializeFirebase()
{
  Serial.println();
  Serial.println("================================================");
  Serial.println("INITIALIZING FIREBASE");
  Serial.println("================================================");


  config.api_key = FIREBASE_API_KEY;

  config.database_url = FIREBASE_HOST;

  config.token_status_callback = tokenStatusCallback;


  firebaseData.setBSSLBufferSize(
    4096,
    1024
  );

  firebaseData.setResponseSize(2048);


  Serial.println(
    "Starting Firebase Anonymous Authentication..."
  );


  bool signupResult = Firebase.signUp(
    &config,
    &auth,
    "",
    ""
  );


  if (signupResult)
  {
    Serial.println(
      "Firebase anonymous authentication initialized."
    );

    isAuthenticated = true;
  }
  else
  {
    Serial.println(
      "Firebase anonymous authentication failed."
    );

    Serial.print("Signup error: ");

    Serial.println(
      config.signer.signupError.message.c_str()
    );

    isAuthenticated = false;
  }


  Firebase.begin(
    &config,
    &auth
  );

  Firebase.reconnectWiFi(true);


  Serial.println("Firebase initialized.");

  delay(1000);


  if (isAuthenticated)
  {
    if (Firebase.ready())
    {
      Serial.println("Firebase is READY.");
    }
    else
    {
      Serial.println(
        "Firebase authentication/token processing"
      );

      Serial.println(
        "is still initializing."
      );
    }
  }


  Serial.println(
    "================================================"
  );
}


// ============================================================
// RELAY ON
// ============================================================

void relayON()
{
  // Active LOW relay
  digitalWrite(RELAY_PIN, LOW);

  currentRelayStatus = "ON";
  currentPumpState = "ON";

  Serial.println("RELAY: ON");
}


// ============================================================
// RELAY OFF
// ============================================================

void relayOFF()
{
  // Active LOW relay
  digitalWrite(RELAY_PIN, HIGH);

  currentRelayStatus = "OFF";
  currentPumpState = "OFF";

  Serial.println("RELAY: OFF");
}


// ============================================================
// CHECK MANUAL WATERING COMMAND
// ============================================================

void checkManualWatering()
{
  String manualCommand;


  if (!Firebase.getString(
        firebaseData,
        "/SmartPlant/Control/PumpManual"
      ))
  {
    Serial.print(
      "Manual pump command read failed: "
    );

    Serial.println(
      firebaseData.errorReason()
    );

    return;
  }


  manualCommand = firebaseData.stringData();

  manualCommand.trim();

  manualCommand.toUpperCase();


  if (manualCommand != "ON")
  {
    return;
  }


  if (wateringInProgress)
  {
    return;
  }


  Serial.println();
  Serial.println(
    ">>> MANUAL WATERING COMMAND RECEIVED <<<"
  );


  runWateringCycle("MANUAL");


  // ----------------------------------------------------------
  // Reset one-shot Firebase command
  // ----------------------------------------------------------

  if (Firebase.setString(
        firebaseData,
        "/SmartPlant/Control/PumpManual",
        "OFF"
      ))
  {
    Serial.println(
      "Manual pump command reset to OFF."
    );
  }
  else
  {
    Serial.print(
      "Failed to reset manual command: "
    );

    Serial.println(
      firebaseData.errorReason()
    );
  }
}


// ============================================================
// CHECK AND WATER PLANT AUTOMATICALLY
// ============================================================

void checkAndWaterPlant()
{
  // ----------------------------------------------------------
  // Safety: do not start another cycle while pump is running
  // ----------------------------------------------------------

  if (wateringInProgress)
  {
    return;
  }


  // ----------------------------------------------------------
  // SOIL IS WET
  // ----------------------------------------------------------
  //
  // This is extremely important.
  //
  // Once soil becomes WET, the automatic watering lock is
  // released.
  //
  // This creates a new DRY episode.
  // ----------------------------------------------------------

  if (soilMoistureRaw == LOW)
  {
    if (automaticWateringLocked)
    {
      Serial.println();
      Serial.println(
        "Soil is WET again."
      );

      Serial.println(
        "Automatic watering lock RELEASED."
      );
    }

    automaticWateringLocked = false;

    Serial.println(
      "Soil is fine. No automatic watering needed."
    );

    return;
  }


  // ----------------------------------------------------------
  // SOIL IS DRY
  // ----------------------------------------------------------

  if (soilMoistureRaw == HIGH)
  {
    // --------------------------------------------------------
    // AUTOMATIC LOCK
    // --------------------------------------------------------

    if (automaticWateringLocked)
    {
      Serial.println();
      Serial.println(
        "Soil is still DRY."
      );

      Serial.println(
        "Automatic watering already performed."
      );

      Serial.println(
        "Waiting for soil to become WET."
      );

      return;
    }


    // --------------------------------------------------------
    // FIRST DRY DETECTION
    // --------------------------------------------------------

    Serial.println();
    Serial.println(
      ">>> NEW DRY EPISODE DETECTED <<<"
    );

    Serial.println(
      ">>> STARTING AUTOMATIC IRRIGATION <<<"
    );


    // Lock BEFORE watering.
    //
    // This prevents another automatic cycle even if
    // Firebase upload or sensor state behaves unexpectedly.
    automaticWateringLocked = true;


    runWateringCycle("AUTOMATIC");


    Serial.println(
      ">>> AUTOMATIC IRRIGATION COMPLETED <<<"
    );

    Serial.println(
      ">>> AUTOMATIC WATERING LOCKED <<<"
    );

    Serial.println(
      ">>> WAITING FOR SOIL TO BECOME WET <<<"
    );
  }
}


// ============================================================
// RUN SAFE WATERING CYCLE
// ============================================================

void runWateringCycle(
  const char* reason
)
{
  wateringInProgress = true;


  // ----------------------------------------------------------
  // Capture PRE-WATERING sensor state
  // ----------------------------------------------------------

  float preTemperature = temperature;
  float preHumidity = humidity;

  int preLightIntensity = lightValue;
  int preSoilRaw = soilMoistureRaw;

  String preSoilStatus = soilStatus;
  String preLightStatus = lightStatus;


  Serial.println();

  Serial.print("Watering mode: ");
  Serial.println(reason);

  Serial.print("Soil Status Before Watering: ");
  Serial.println(preSoilStatus);

  Serial.print("Soil Raw Before Watering: ");
  Serial.println(preSoilRaw);

  Serial.print("Temperature Before Watering: ");
  Serial.print(preTemperature, 2);
  Serial.println(" °C");

  Serial.print("Humidity Before Watering: ");
  Serial.print(preHumidity, 2);
  Serial.println(" %");

  Serial.print("Light Before Watering: ");
  Serial.println(preLightIntensity);

  Serial.println(
    "Pump ON for 3 seconds."
  );


  // ----------------------------------------------------------
  // PUMP ON
  // ----------------------------------------------------------

  relayON();


  // ----------------------------------------------------------
  // Firebase relay state
  // ----------------------------------------------------------

  if (
    isAuthenticated &&
    Firebase.ready()
  )
  {
    if (!Firebase.setString(
          firebaseData,
          "/SmartPlant/RelayStatus",
          "ON"
        ))
    {
      Serial.print(
        "Failed to update RelayStatus ON: "
      );

      Serial.println(
        firebaseData.errorReason()
      );
    }
  }


  // ----------------------------------------------------------
  // WATERING TIMER
  // ----------------------------------------------------------

  unsigned long wateringStart = millis();


  while (
    millis() - wateringStart <
    PUMP_WATER_DURATION
  )
  {
    delay(50);
  }


  // ----------------------------------------------------------
  // PUMP OFF
  // ----------------------------------------------------------

  relayOFF();


  unsigned long actualDuration =
    millis() - wateringStart;


  wateringInProgress = false;


  // ----------------------------------------------------------
  // Firebase relay state
  // ----------------------------------------------------------

  if (
    isAuthenticated &&
    Firebase.ready()
  )
  {
    if (!Firebase.setString(
          firebaseData,
          "/SmartPlant/RelayStatus",
          "OFF"
        ))
    {
      Serial.print(
        "Failed to update RelayStatus OFF: "
      );

      Serial.println(
        firebaseData.errorReason()
      );
    }
  }


  // ----------------------------------------------------------
  // UPLOAD EXPLICIT WATERING EVENT
  // ----------------------------------------------------------

  uploadWateringEvent(
    reason,
    actualDuration
  );


  // ----------------------------------------------------------
  // SERIAL RESULT
  // ----------------------------------------------------------

  Serial.println();

  Serial.println(
    ">>> IRRIGATION COMPLETED <<<"
  );

  Serial.println(
    ">>> PUMP OFF <<<"
  );

  Serial.print(
    "Actual watering duration: "
  );

  Serial.print(actualDuration);

  Serial.println(" ms");

  Serial.println();
}


// ============================================================
// READ DHT22
// ============================================================

bool readDHTSensor()
{
  const int MAX_ATTEMPTS = 3;


  for (
    int attempt = 1;
    attempt <= MAX_ATTEMPTS;
    attempt++
  )
  {
    temperature = dht.readTemperature();

    humidity = dht.readHumidity();


    if (
      !isnan(temperature) &&
      !isnan(humidity)
    )
    {
      return true;
    }


    Serial.print(
      "DHT22 read failed. Attempt "
    );

    Serial.print(attempt);

    Serial.print("/");

    Serial.println(MAX_ATTEMPTS);


    if (attempt < MAX_ATTEMPTS)
    {
      delay(2200);
    }
  }


  return false;
}


// ============================================================
// READ ALL SENSORS
// ============================================================

void readSensors()
{
  Serial.println();
  Serial.println("Reading sensors...");


  // ----------------------------------------------------------
  // DHT22
  // ----------------------------------------------------------

  if (readDHTSensor())
  {
    Serial.println(
      "DHT22 reading successful."
    );
  }
  else
  {
    Serial.println(
      "DHT22 reading failed."
    );

    temperature = 0.0;
    humidity = 0.0;
  }


  // ----------------------------------------------------------
  // SOIL SENSOR
  // ----------------------------------------------------------

  soilMoistureRaw =
    digitalRead(SOIL_PIN);


  if (soilMoistureRaw == HIGH)
  {
    soilStatus =
      "DRY (Needs Water!)";
  }
  else
  {
    soilStatus =
      "WET (Soil is fine)";
  }


  // ----------------------------------------------------------
  // LDR
  // ----------------------------------------------------------

  lightValue =
    analogRead(LDR_PIN);


  if (lightValue > 500)
  {
    lightStatus = "DARK";
  }
  else
  {
    lightStatus = "BRIGHT";
  }
}


// ============================================================
// UPLOAD CURRENT SENSOR DATA
// ============================================================

void uploadSensorData()
{
  FirebaseJson json;


  // ----------------------------------------------------------
  // Sensor values
  // ----------------------------------------------------------

  json.set(
    "Temperature",
    temperature
  );

  json.set(
    "Humidity",
    humidity
  );

  json.set(
    "LightIntensity",
    lightValue
  );

  json.set(
    "LightStatus",
    lightStatus
  );

  json.set(
    "SoilMoistureRaw",
    soilMoistureRaw
  );

  json.set(
    "SoilStatus",
    soilStatus
  );


  // ----------------------------------------------------------
  // Pump / relay
  // ----------------------------------------------------------

  json.set(
    "RelayStatus",
    currentRelayStatus
  );

  json.set(
    "PumpState",
    currentPumpState
  );


  // ----------------------------------------------------------
  // Device
  // ----------------------------------------------------------

  json.set(
    "Device/Firmware",
    FIRMWARE_VERSION
  );

  json.set(
    "Device/Chip",
    "ESP8266"
  );


  // ----------------------------------------------------------
  // Timestamp
  // ----------------------------------------------------------

  json.set(
    "LastUpdated",
    getTimestamp()
  );


  Serial.println();
  Serial.println(
    "Uploading current sensor data..."
  );


  if (
    Firebase.updateNode(
      firebaseData,
      "/SmartPlant",
      json
    )
  )
  {
    Serial.println(
      "Current sensor data uploaded successfully."
    );
  }
  else
  {
    Serial.print(
      "Sensor upload failed: "
    );

    Serial.println(
      firebaseData.errorReason()
    );
  }
}


// ============================================================
// UPLOAD ML-READY HISTORY
// ============================================================

void uploadHistory()
{
  FirebaseJson logData;


  // ----------------------------------------------------------
  // Sensor features
  // ----------------------------------------------------------

  logData.set(
    "Temperature",
    temperature
  );

  logData.set(
    "Humidity",
    humidity
  );

  logData.set(
    "LightIntensity",
    lightValue
  );

  logData.set(
    "LightStatus",
    lightStatus
  );

  logData.set(
    "SoilMoistureRaw",
    soilMoistureRaw
  );

  logData.set(
    "SoilStatus",
    soilStatus
  );


  // ----------------------------------------------------------
  // Pump state
  // ----------------------------------------------------------

  logData.set(
    "PumpState",
    currentPumpState
  );

  logData.set(
    "RelayStatus",
    currentRelayStatus
  );


  // ----------------------------------------------------------
  // Historical event marker
  // ----------------------------------------------------------

  logData.set(
    "WateringEvent",
    false
  );


  // ----------------------------------------------------------
  // Timestamp
  // ----------------------------------------------------------

  logData.set(
    "Timestamp",
    getTimestamp()
  );


  // ----------------------------------------------------------
  // Firmware
  // ----------------------------------------------------------

  logData.set(
    "Firmware",
    FIRMWARE_VERSION
  );


  Serial.println();
  Serial.println(
    "Uploading ML-ready history..."
  );


  if (
    Firebase.pushJSON(
      firebaseData,
      "/SmartPlant/Logs",
      logData
    )
  )
  {
    Serial.println(
      "History uploaded successfully."
    );

    Serial.print(
      "History key: "
    );

    Serial.println(
      firebaseData.pushName()
    );
  }
  else
  {
    Serial.print(
      "History upload failed: "
    );

    Serial.println(
      firebaseData.errorReason()
    );
  }
}


// ============================================================
// UPLOAD EXPLICIT WATERING EVENT
// ============================================================

void uploadWateringEvent(
  const char* reason,
  unsigned long duration
)
{
  FirebaseJson eventData;


  // ----------------------------------------------------------
  // Explicit event marker
  // ----------------------------------------------------------

  eventData.set(
    "WateringEvent",
    true
  );


  // ----------------------------------------------------------
  // Reason
  // ----------------------------------------------------------

  eventData.set(
    "WateringReason",
    reason
  );


  // ----------------------------------------------------------
  // PRE-WATERING SENSOR DATA
  // ----------------------------------------------------------
  //
  // These values represent the environmental conditions
  // immediately before watering.
  //
  // This is useful for future ML analysis.
  // ----------------------------------------------------------

  eventData.set(
    "Temperature",
    temperature
  );

  eventData.set(
    "Humidity",
    humidity
  );

  eventData.set(
    "LightIntensity",
    lightValue
  );

  eventData.set(
    "LightStatus",
    lightStatus
  );

  eventData.set(
    "SoilMoistureRaw",
    soilMoistureRaw
  );

  eventData.set(
    "SoilStatus",
    soilStatus
  );


  // ----------------------------------------------------------
  // PUMP INFORMATION
  // ----------------------------------------------------------

  eventData.set(
    "PumpState",
    "ON->OFF"
  );

  eventData.set(
    "RelayStatus",
    "OFF"
  );


  // ----------------------------------------------------------
  // ACTUAL DURATION
  // ----------------------------------------------------------

  eventData.set(
    "DurationMs",
    (int)duration
  );


  // ----------------------------------------------------------
  // TIMESTAMP
  // ----------------------------------------------------------

  eventData.set(
    "Timestamp",
    getTimestamp()
  );


  // ----------------------------------------------------------
  // FIRMWARE
  // ----------------------------------------------------------

  eventData.set(
    "Firmware",
    FIRMWARE_VERSION
  );


  Serial.println();
  Serial.println(
    "Uploading watering event..."
  );


  if (
    Firebase.pushJSON(
      firebaseData,
      "/SmartPlant/WateringEvents",
      eventData
    )
  )
  {
    Serial.println(
      "Watering event uploaded successfully."
    );

    Serial.print(
      "Watering event key: "
    );

    Serial.println(
      firebaseData.pushName()
    );
  }
  else
  {
    Serial.print(
      "Watering event upload failed: "
    );

    Serial.println(
      firebaseData.errorReason()
    );
  }
}


// ============================================================
// UPLOAD DEVICE INFORMATION
// ============================================================

void uploadDeviceInformation()
{
  FirebaseJson deviceData;


  deviceData.set(
    "Firmware",
    FIRMWARE_VERSION
  );

  deviceData.set(
    "Board",
    "ESP8266"
  );

  deviceData.set(
    "WiFiSSID",
    WIFI_SSID
  );

  deviceData.set(
    "IPAddress",
    WiFi.localIP().toString()
  );

  deviceData.set(
    "RSSI",
    WiFi.RSSI()
  );

  deviceData.set(
    "Authentication",
    "Anonymous"
  );


  // ----------------------------------------------------------
  // Hardware information
  // ----------------------------------------------------------

  deviceData.set(
    "Relay",
    "D1 / Active LOW"
  );

  deviceData.set(
    "DHT22",
    "D5"
  );

  deviceData.set(
    "SoilSensor",
    "D7 / Digital"
  );

  deviceData.set(
    "LDR",
    "A0 / Analog"
  );


  // ----------------------------------------------------------
  // ML information
  // ----------------------------------------------------------

  deviceData.set(
    "MLDataLogging",
    "Enabled"
  );

  deviceData.set(
    "WateringEventLogging",
    "Enabled"
  );

  deviceData.set(
    "AutomaticWateringMode",
    "One event per DRY episode"
  );


  // ----------------------------------------------------------
  // Timestamp
  // ----------------------------------------------------------

  deviceData.set(
    "LastUpdated",
    getTimestamp()
  );


  Serial.println();
  Serial.println(
    "Uploading device information..."
  );


  if (
    Firebase.updateNode(
      firebaseData,
      "/SmartPlant/Device",
      deviceData
    )
  )
  {
    Serial.println(
      "Device information uploaded successfully."
    );
  }
  else
  {
    Serial.print(
      "Device information upload failed: "
    );

    Serial.println(
      firebaseData.errorReason()
    );
  }
}


// ============================================================
// GET TIMESTAMP
// ============================================================

String getTimestamp()
{
  time_t now = time(nullptr);


  // NTP not ready
  if (now < 100000)
  {
    return "N/A";
  }


  struct tm *timeinfo =
    localtime(&now);


  char buffer[30];


  strftime(
    buffer,
    sizeof(buffer),
    "%Y-%m-%d %H:%M:%S",
    timeinfo
  );


  return String(buffer);
}