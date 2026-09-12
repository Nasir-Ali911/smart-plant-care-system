// ============================================================
// SMART PLANT CARE SYSTEM
// ESP8266 + DHT22 + LDR + Soil Moisture + Relay + Firebase
// ============================================================
//
// Firmware Version: v1.3.4-manual-auto-watering
//
// PURPOSE:
// - Automatic irrigation based on soil moisture status
// - Safe 3-second pump burst when soil is dry
// - Manual pump command from Flutter app via Firebase
// - Preserves all existing sensors + Firebase functionality
//
// WIRING:
// - LDR AOUT        -> A0
// - Soil DOUT       -> D7
// - DHT22 DATA      -> D5
// - Relay IN        -> D1
//
// FIREBASE PATHS:
// - /SmartPlant
// - /SmartPlant/Device
// - /SmartPlant/Logs
// - /SmartPlant/Control/PumpManual
//
// SENSOR LOGIC:
// - Soil HIGH = DRY (Needs Water!)
// - Soil LOW  = WET (Soil is fine)
// - LDR > 500 = DARK
// - LDR <=500 = BRIGHT
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

#define FIRMWARE_VERSION "v1.3.4-manual-auto-watering"


// ============================================================
// WIFI CONFIGURATION
// ============================================================

#define WIFI_SSID "Kaka-chaniyan-ala"
#define WIFI_PASSWORD "03227571971"


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

// DHT22
#define DHT_PIN D5
#define DHT_TYPE DHT22

// Soil moisture digital output
#define SOIL_PIN D7

// LDR analog output
#define LDR_PIN A0

// Relay control pin
#define RELAY_PIN D1


// ============================================================
// SENSOR OBJECT
// ============================================================

DHT dht(DHT_PIN, DHT_TYPE);


// ============================================================
// TIMING
// ============================================================

const unsigned long SENSOR_INTERVAL = 10000;

const unsigned long HISTORY_INTERVAL = 60000;

const unsigned long WIFI_TIMEOUT = 20000;

const unsigned long WIFI_RETRY_DELAY = 5000;

// Pump watering duration when triggered automatically (3 seconds)
const unsigned long PUMP_WATER_DURATION = 3000;

// Manual watering is also limited to 3 seconds for safety.
// Prevent immediate repeated automatic watering after any watering cycle.
const unsigned long WATERING_COOLDOWN = 30000;

// Check the Flutter manual pump command once per second.
const unsigned long CONTROL_CHECK_INTERVAL = 1000;


// ============================================================
// TIMESTAMP VARIABLES
// ============================================================

unsigned long lastSensorRead = 0;

unsigned long lastHistoryUpload = 0;

unsigned long lastWiFiRetry = 0;

unsigned long lastWateringTime = 0;

unsigned long lastControlCheck = 0;

bool wateringInProgress = false;


// ============================================================
// SENSOR VARIABLES
// ============================================================

float temperature = 0.0;

float humidity = 0.0;

int lightValue = 0;

String soilStatus = "UNKNOWN";

String lightStatus = "UNKNOWN";

String currentRelayStatus = "OFF";


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
  Serial.println("       AUTOMATIC IRRIGATION MODE");
  Serial.println("================================================");

  Serial.print("Firmware: ");
  Serial.println(FIRMWARE_VERSION);

  Serial.println();


  // ----------------------------------------------------------
  // Initialize GPIO
  // ----------------------------------------------------------

  pinMode(SOIL_PIN, INPUT);

  pinMode(LDR_PIN, INPUT);


  // ----------------------------------------------------------
  // Initialize relay
  // ----------------------------------------------------------

  pinMode(RELAY_PIN, OUTPUT);

  // Active-low relay: HIGH = OFF
  relayOFF();

  Serial.println("Relay initialized.");
  Serial.println("Relay state: OFF");


  // ----------------------------------------------------------
  // Initialize DHT22
  // ----------------------------------------------------------

  Serial.println("Initializing DHT22...");

  dht.begin();

  delay(2000);

  Serial.println("DHT22 initialized.");


  // ----------------------------------------------------------
  // Connect WiFi
  // ----------------------------------------------------------

  connectWiFi();


  // ----------------------------------------------------------
  // Initialize NTP
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
  // Initialize Firebase
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
  // Initial Device Information
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
  // Initialize timers
  // ----------------------------------------------------------

  lastSensorRead = millis();

  lastHistoryUpload = millis();


  Serial.println();
  Serial.println("================================================");
  Serial.println("SYSTEM READY — AUTOMATIC WATERING ACTIVE");
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
  // Firebase readiness
  // ----------------------------------------------------------

  if (WiFi.status() == WL_CONNECTED && isAuthenticated)
  {
    firebaseReady = Firebase.ready();
  }


  // ----------------------------------------------------------
  // Manual pump command check
  // ----------------------------------------------------------

  if (firebaseReady &&
      millis() - lastControlCheck >= CONTROL_CHECK_INTERVAL)
  {
    lastControlCheck = millis();
    checkManualWatering();
  }


  // ----------------------------------------------------------
  // WiFi monitoring
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
  // Sensor interval
  // ----------------------------------------------------------

  if (millis() - lastSensorRead < SENSOR_INTERVAL)
  {
    delay(100);

    return;
  }

  lastSensorRead = millis();


  // ----------------------------------------------------------
  // Read sensors
  // ----------------------------------------------------------

  readSensors();


  // ----------------------------------------------------------
  // Automatic watering logic
  // ----------------------------------------------------------

  checkAndWaterPlant();


  // ----------------------------------------------------------
  // Serial monitor
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

  Serial.print("Soil        : ");
  Serial.println(soilStatus);

  Serial.print("Relay       : ");
  Serial.println(currentRelayStatus);

  Serial.println("------------------------------------------------");


  // ----------------------------------------------------------
  // Firebase authentication check
  // ----------------------------------------------------------

  if (!isAuthenticated)
  {
    Serial.println("Firebase authentication was not initialized.");
    Serial.println("Skipping Firebase upload.");

    delay(100);

    return;
  }


  // ----------------------------------------------------------
  // Firebase readiness check
  // ----------------------------------------------------------

  if (!firebaseReady)
  {
    Serial.println("Firebase not ready.");
    Serial.println("Skipping Firebase upload for this cycle.");

    delay(100);

    return;
  }


  // ----------------------------------------------------------
  // Upload current sensor data
  // ----------------------------------------------------------

  uploadSensorData();


  // ----------------------------------------------------------
  // Upload history periodically
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

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long startAttemptTime = millis();

  while (WiFi.status() != WL_CONNECTED &&
         millis() - startAttemptTime < WIFI_TIMEOUT)
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

  firebaseData.setBSSLBufferSize(4096, 1024);
  firebaseData.setResponseSize(2048);

  Serial.println("Starting Firebase Anonymous Authentication...");

  bool signupResult = Firebase.signUp(
    &config,
    &auth,
    "",
    ""
  );

  if (signupResult)
  {
    Serial.println("Firebase anonymous authentication initialized.");
    isAuthenticated = true;
  }
  else
  {
    Serial.println("Firebase anonymous authentication failed.");
    Serial.print("Signup error: ");
    Serial.println(config.signer.signupError.message.c_str());
    isAuthenticated = false;
  }

  Firebase.begin(&config, &auth);
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
      Serial.println("Firebase authentication/token processing is");
      Serial.println("still initializing. It will be handled by loop().");
    }
  }

  Serial.println("================================================");
}


// ============================================================
// RELAY ON
// ============================================================

void relayON()
{
  digitalWrite(RELAY_PIN, LOW);
  currentRelayStatus = "ON";
  Serial.println("RELAY: ON");
}


// ============================================================
// RELAY OFF
// ============================================================

void relayOFF()
{
  digitalWrite(RELAY_PIN, HIGH);
  currentRelayStatus = "OFF";
  Serial.println("RELAY: OFF");
}


// ============================================================
// CHECK MANUAL WATERING COMMAND
// ============================================================

void checkManualWatering()
{
  String manualCommand;

  if (!Firebase.getString(firebaseData, "/SmartPlant/Control/PumpManual"))
  {
    Serial.print("Manual pump command read failed: ");
    Serial.println(firebaseData.errorReason());
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
  Serial.println(">>> MANUAL WATERING COMMAND RECEIVED <<<");

  runWateringCycle("MANUAL");

  // Reset the one-shot command so the same command is not repeated.
  if (Firebase.setString(firebaseData, "/SmartPlant/Control/PumpManual", "OFF"))
  {
    Serial.println("Manual pump command reset to OFF.");
  }
  else
  {
    Serial.print("Failed to reset manual command: ");
    Serial.println(firebaseData.errorReason());
  }
}


// ============================================================
// CHECK AND WATER PLANT AUTOMATICALLY
// ============================================================

void checkAndWaterPlant()
{
  // Do not start another cycle while a cycle is already running.
  if (wateringInProgress)
  {
    return;
  }

  // Prevent repeated automatic watering immediately after a manual
  // or automatic watering cycle.
  if (lastWateringTime > 0 &&
      millis() - lastWateringTime < WATERING_COOLDOWN)
  {
    Serial.println("Watering cooldown active. No automatic watering.");
    return;
  }

  if (soilStatus.indexOf("DRY") >= 0)
  {
    Serial.println();
    Serial.println(">>> SOIL IS DRY! STARTING AUTOMATIC IRRIGATION... <<<");

    runWateringCycle("AUTOMATIC");

    Serial.println(">>> AUTOMATIC IRRIGATION COMPLETED. PUMP OFF. <<<");
  }
  else
  {
    Serial.println("Soil is fine. No automatic watering needed.");
  }
}


// ============================================================
// RUN SAFE WATERING CYCLE
// ============================================================

void runWateringCycle(const char* reason)
{
  wateringInProgress = true;

  Serial.println();
  Serial.print("Watering mode: ");
  Serial.println(reason);
  Serial.println("Pump ON for 3 seconds.");

  relayON();

  // Update Firebase immediately when the relay turns ON.
  if (isAuthenticated && Firebase.ready())
  {
    if (!Firebase.setString(firebaseData, "/SmartPlant/RelayStatus", "ON"))
    {
      Serial.print("Failed to update RelayStatus ON: ");
      Serial.println(firebaseData.errorReason());
    }
  }

  unsigned long wateringStart = millis();

  while (millis() - wateringStart < PUMP_WATER_DURATION)
  {
    // Hard safety limit is the same 3-second duration.
    delay(50);
  }

  relayOFF();
  lastWateringTime = millis();
  wateringInProgress = false;

  // Update Firebase immediately when the relay turns OFF.
  if (isAuthenticated && Firebase.ready())
  {
    if (!Firebase.setString(firebaseData, "/SmartPlant/RelayStatus", "OFF"))
    {
      Serial.print("Failed to update RelayStatus OFF: ");
      Serial.println(firebaseData.errorReason());
    }
  }

  Serial.println("Pump OFF.");
}


// ============================================================
// READ DHT22
// ============================================================

bool readDHTSensor()
{
  const int MAX_ATTEMPTS = 3;

  for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)
  {
    temperature = dht.readTemperature();
    humidity = dht.readHumidity();

    if (!isnan(temperature) && !isnan(humidity))
    {
      return true;
    }

    Serial.print("DHT22 read failed. Attempt ");
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

  if (readDHTSensor())
  {
    Serial.println("DHT22 reading successful.");
  }
  else
  {
    Serial.println("DHT22 reading failed.");
    temperature = 0.0;
    humidity = 0.0;
  }

  int soilRaw = digitalRead(SOIL_PIN);

  if (soilRaw == HIGH)
  {
    soilStatus = "DRY (Needs Water!)";
  }
  else
  {
    soilStatus = "WET (Soil is fine)";
  }

  lightValue = analogRead(LDR_PIN);

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

  json.set("Temperature", temperature);
  json.set("Humidity", humidity);
  json.set("LightIntensity", lightValue);
  json.set("LightStatus", lightStatus);
  json.set("SoilStatus", soilStatus);
  json.set("RelayStatus", currentRelayStatus);

  json.set("Device/Firmware", FIRMWARE_VERSION);
  json.set("Device/Chip", "ESP8266");
  json.set("LastUpdated", getTimestamp());

  Serial.println();
  Serial.println("Uploading current sensor data...");

  if (Firebase.updateNode(firebaseData, "/SmartPlant", json))
  {
    Serial.println("Current sensor data uploaded successfully.");
  }
  else
  {
    Serial.print("Sensor upload failed: ");
    Serial.println(firebaseData.errorReason());
  }
}


// ============================================================
// UPLOAD HISTORY
// ============================================================

void uploadHistory()
{
  FirebaseJson logData;

  logData.set("Temperature", temperature);
  logData.set("Humidity", humidity);
  logData.set("LightIntensity", lightValue);
  logData.set("LightStatus", lightStatus);
  logData.set("SoilStatus", soilStatus);
  logData.set("RelayStatus", currentRelayStatus);
  logData.set("Timestamp", getTimestamp());
  logData.set("Firmware", FIRMWARE_VERSION);

  Serial.println();
  Serial.println("Uploading history...");

  if (Firebase.pushJSON(firebaseData, "/SmartPlant/Logs", logData))
  {
    Serial.println("History uploaded successfully.");
    Serial.print("History key: ");
    Serial.println(firebaseData.pushName());
  }
  else
  {
    Serial.print("History upload failed: ");
    Serial.println(firebaseData.errorReason());
  }
}


// ============================================================
// UPLOAD DEVICE INFORMATION
// ============================================================

void uploadDeviceInformation()
{
  FirebaseJson deviceData;

  deviceData.set("Firmware", FIRMWARE_VERSION);
  deviceData.set("Board", "ESP8266");
  deviceData.set("WiFiSSID", WIFI_SSID);
  deviceData.set("IPAddress", WiFi.localIP().toString());
  deviceData.set("RSSI", WiFi.RSSI());
  deviceData.set("Authentication", "Anonymous");
  deviceData.set("Relay", "D1 / Active LOW");
  deviceData.set("LastUpdated", getTimestamp());

  Serial.println();
  Serial.println("Uploading device information...");

  if (Firebase.updateNode(firebaseData, "/SmartPlant/Device", deviceData))
  {
    Serial.println("Device information uploaded successfully.");
  }
  else
  {
    Serial.print("Device information upload failed: ");
    Serial.println(firebaseData.errorReason());
  }
}


// ============================================================
// GET TIMESTAMP
// ============================================================

String getTimestamp()
{
  time_t now = time(nullptr);

  if (now < 100000)
  {
    return "N/A";
  }

  struct tm *timeinfo = localtime(&now);
  char buffer[30];

  strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", timeinfo);
  return String(buffer);
}