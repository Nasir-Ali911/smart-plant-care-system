// ============================================================
// SMART PLANT CARE SYSTEM
// ESP8266 + DHT22 + LDR + YL-69 + Firebase
// ============================================================

#include <ESP8266WiFi.h>
#include <DHT.h>
#include <FirebaseESP8266.h>
#include <time.h>

// ============================================================
// Wi-Fi
// ============================================================

#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// ============================================================
// Firebase
// ============================================================

#define FIREBASE_HOST "smart-plant-care-fyp-2026-default-rtdb.firebaseio.com"

// ============================================================
// Firmware
// ============================================================

#define FIRMWARE_VERSION "v1.0.7-esp8266"

// ============================================================
// Sensors
// ============================================================

#define DHTPIN D2
#define DHTTYPE DHT22

const int LDR_PIN = A0;
const int SOIL_PIN = D5;

DHT dht(DHTPIN, DHTTYPE);

// ============================================================
// Firebase Objects
// ============================================================

FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

// ============================================================
// SENSOR INTERVAL
// ============================================================

unsigned long previousMillis = 0;

const unsigned long SENSOR_INTERVAL = 5000;

// ============================================================
// NTP TIME
// ============================================================

const long GMT_OFFSET_SEC = 5 * 60 * 60;
const int DAYLIGHT_OFFSET_SEC = 0;

// ============================================================
// DHT RETRY SETTINGS
// ============================================================

const int DHT_MAX_ATTEMPTS = 3;
const unsigned long DHT_RETRY_DELAY = 2200;

// ============================================================
// SETUP
// ============================================================

void setup() {

  Serial.begin(115200);

  delay(1000);

  Serial.println();
  Serial.println("========================================");
  Serial.println("     SMART PLANT CARE SYSTEM");
  Serial.println("          ESP8266 VERSION");
  Serial.println("========================================");

  // ----------------------------------------------------------
  // Initialize sensors
  // ----------------------------------------------------------

  pinMode(SOIL_PIN, INPUT);

  dht.begin();

  Serial.println("Sensors initialized.");

  // ----------------------------------------------------------
  // Connect to Wi-Fi
  // ----------------------------------------------------------

  Serial.print("Connecting to Wi-Fi");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED) {

    delay(500);

    Serial.print(".");
  }

  Serial.println();

  Serial.println("Wi-Fi Connected!");

  // ----------------------------------------------------------
  // Device information
  // ----------------------------------------------------------

  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  Serial.print("MAC Address: ");
  Serial.println(WiFi.macAddress());

  Serial.print("Wi-Fi RSSI: ");
  Serial.print(WiFi.RSSI());
  Serial.println(" dBm");

  // ----------------------------------------------------------
  // Synchronize real time
  // ----------------------------------------------------------

  initializeTime();

  // ----------------------------------------------------------
  // Initialize Firebase
  // ----------------------------------------------------------

  config.host = FIREBASE_HOST;
  config.database_url = FIREBASE_HOST;

  // Temporary testing mode
  config.signer.test_mode = true;

  firebaseData.setBSSLBufferSize(4096, 1024);
  firebaseData.setResponseSize(2048);

  Firebase.begin(&config, &auth);

  Firebase.reconnectWiFi(true);

  Serial.println("Firebase initialized.");

  // ----------------------------------------------------------
  // Upload initial device information
  // ----------------------------------------------------------

  uploadDeviceInformation();

  Serial.println("========================================");
  Serial.println("System Ready.");
  Serial.println("========================================");
}

// ============================================================
// LOOP
// ============================================================

void loop() {

  // ==========================================================
  // CHECK WI-FI
  // ==========================================================

  if (WiFi.status() != WL_CONNECTED) {

    Serial.println();
    Serial.println("Wi-Fi disconnected!");
    Serial.println("Reconnecting...");

    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    delay(5000);

    return;
  }

  // ==========================================================
  // SENSOR TIMER
  // ==========================================================

  unsigned long currentMillis = millis();

  if (currentMillis - previousMillis < SENSOR_INTERVAL) {
    return;
  }

  previousMillis = currentMillis;

  // ==========================================================
  // READ LDR
  // ==========================================================

  int lightValue = analogRead(LDR_PIN);

  // ==========================================================
  // READ SOIL SENSOR
  // ==========================================================

  int soilValue = digitalRead(SOIL_PIN);

  String soilStatus;

  if (soilValue == HIGH) {

    soilStatus = "DRY (Needs Water!)";

  } else {

    soilStatus = "WET (Soil is fine)";
  }

  // ==========================================================
  // READ DHT22 WITH RETRY
  // ==========================================================

  float temperature = NAN;
  float humidity = NAN;

  bool dhtSuccess = false;

  for (int attempt = 1;
       attempt <= DHT_MAX_ATTEMPTS;
       attempt++) {

    Serial.print("DHT22 reading attempt ");
    Serial.print(attempt);
    Serial.println("...");

    temperature = dht.readTemperature();
    humidity = dht.readHumidity();

    if (!isnan(temperature) &&
        !isnan(humidity)) {

      dhtSuccess = true;

      break;
    }

    Serial.println("DHT22 reading failed.");

    if (attempt < DHT_MAX_ATTEMPTS) {

      Serial.print("Waiting ");
      Serial.print(DHT_RETRY_DELAY);
      Serial.println(" ms before retry...");

      delay(DHT_RETRY_DELAY);
    }
  }

  // ==========================================================
  // DEVICE INFORMATION
  // ==========================================================

  int wifiRSSI = WiFi.RSSI();

  String ipAddress =
      WiFi.localIP().toString();

  String macAddress =
      WiFi.macAddress();

  unsigned long uptimeSeconds =
      millis() / 1000;

  // ==========================================================
  // REAL UNIX TIMESTAMP
  // ==========================================================

  unsigned long unixTimestamp =
      getUnixTime();

  // ==========================================================
  // SERIAL MONITOR
  // ==========================================================

  Serial.println();
  Serial.println("========================================");
  Serial.println("          SENSOR READINGS");
  Serial.println("========================================");

  Serial.print("Light Intensity: ");
  Serial.println(lightValue);

  Serial.print("Soil D0 Value: ");
  Serial.println(soilValue);

  Serial.print("Soil Status: ");
  Serial.println(soilStatus);

  if (!dhtSuccess) {

    Serial.println("DHT22 ERROR!");
    Serial.println(
        "Temperature/Humidity unavailable after retries.");

  } else {

    Serial.print("Temperature: ");
    Serial.print(temperature, 2);
    Serial.println(" °C");

    Serial.print("Humidity: ");
    Serial.print(humidity, 2);
    Serial.println(" %");
  }

  Serial.print("Unix Timestamp: ");
  Serial.println(unixTimestamp);

  Serial.println("----------------------------------------");

  Serial.print("IP Address: ");
  Serial.println(ipAddress);

  Serial.print("MAC Address: ");
  Serial.println(macAddress);

  Serial.print("Wi-Fi RSSI: ");
  Serial.print(wifiRSSI);
  Serial.println(" dBm");

  Serial.print("Uptime: ");
  Serial.print(uptimeSeconds);
  Serial.println(" seconds");

  // ==========================================================
  // FIREBASE UPLOAD
  // ==========================================================

  Serial.println("----------------------------------------");
  Serial.println("Uploading data to Firebase...");

  bool success = true;

  // ==========================================================
  // CURRENT LIGHT
  // ==========================================================

  if (Firebase.setInt(
        firebaseData,
        "/SmartPlant/LightIntensity",
        lightValue)) {

    Serial.println("✓ Light uploaded.");

  } else {

    Serial.print("✗ Light upload failed: ");
    Serial.println(
        firebaseData.errorReason());

    success = false;
  }

  // ==========================================================
  // CURRENT SOIL STATUS
  // ==========================================================

  if (Firebase.setString(
        firebaseData,
        "/SmartPlant/SoilStatus",
        soilStatus)) {

    Serial.println("✓ Soil status uploaded.");

  } else {

    Serial.print("✗ Soil upload failed: ");
    Serial.println(
        firebaseData.errorReason());

    success = false;
  }

  // ==========================================================
  // CURRENT TEMPERATURE
  // ==========================================================

  if (dhtSuccess) {

    if (Firebase.setFloat(
          firebaseData,
          "/SmartPlant/Temperature",
          temperature)) {

      Serial.println(
          "✓ Temperature uploaded.");

    } else {

      Serial.print(
          "✗ Temperature upload failed: ");

      Serial.println(
          firebaseData.errorReason());

      success = false;
    }
  } else {

    Serial.println(
        "⚠ Temperature skipped because DHT22 reading failed.");
  }

  // ==========================================================
  // CURRENT HUMIDITY
  // ==========================================================

  if (dhtSuccess) {

    if (Firebase.setFloat(
          firebaseData,
          "/SmartPlant/Humidity",
          humidity)) {

      Serial.println(
          "✓ Humidity uploaded.");

    } else {

      Serial.print(
          "✗ Humidity upload failed: ");

      Serial.println(
          firebaseData.errorReason());

      success = false;
    }
  } else {

    Serial.println(
        "⚠ Humidity skipped because DHT22 reading failed.");
  }

  // ==========================================================
  // DEVICE STATUS
  // ==========================================================

  if (Firebase.setString(
        firebaseData,
        "/SmartPlant/Device/Status",
        "Connected")) {

    Serial.println(
        "✓ Device status uploaded.");

  } else {

    Serial.print(
        "✗ Device status upload failed: ");

    Serial.println(
        firebaseData.errorReason());

    success = false;
  }

  // ==========================================================
  // IP ADDRESS
  // ==========================================================

  if (Firebase.setString(
        firebaseData,
        "/SmartPlant/Device/IPAddress",
        ipAddress)) {

    Serial.println(
        "✓ IP address uploaded.");

  } else {

    Serial.print(
        "✗ IP upload failed: ");

    Serial.println(
        firebaseData.errorReason());

    success = false;
  }

  // ==========================================================
  // MAC ADDRESS
  // ==========================================================

  if (Firebase.setString(
        firebaseData,
        "/SmartPlant/Device/MACAddress",
        macAddress)) {

    Serial.println(
        "✓ MAC address uploaded.");

  } else {

    Serial.print(
        "✗ MAC upload failed: ");

    Serial.println(
        firebaseData.errorReason());

    success = false;
  }

  // ==========================================================
  // WI-FI RSSI
  // ==========================================================

  if (Firebase.setInt(
        firebaseData,
        "/SmartPlant/Device/WiFiRSSI",
        wifiRSSI)) {

    Serial.println(
        "✓ Wi-Fi RSSI uploaded.");

  } else {

    Serial.print(
        "✗ RSSI upload failed: ");

    Serial.println(
        firebaseData.errorReason());

    success = false;
  }

  // ==========================================================
  // FIRMWARE VERSION
  // ==========================================================

  if (Firebase.setString(
        firebaseData,
        "/SmartPlant/Device/FirmwareVersion",
        FIRMWARE_VERSION)) {

    Serial.println(
        "✓ Firmware version uploaded.");

  } else {

    Serial.print(
        "✗ Firmware upload failed: ");

    Serial.println(
        firebaseData.errorReason());

    success = false;
  }

  // ==========================================================
  // UPTIME
  // ==========================================================

  if (Firebase.setInt(
        firebaseData,
        "/SmartPlant/Device/UptimeSeconds",
        uptimeSeconds)) {

    Serial.println(
        "✓ Uptime uploaded.");

  } else {

    Serial.print(
        "✗ Uptime upload failed: ");

    Serial.println(
        firebaseData.errorReason());

    success = false;
  }

  // ==========================================================
  // LAST UPDATE
  // ==========================================================

  if (unixTimestamp > 0) {

    if (Firebase.setInt(
          firebaseData,
          "/SmartPlant/Device/LastUpdateUnix",
          unixTimestamp)) {

      Serial.println(
          "✓ Last update uploaded.");

    } else {

      Serial.print(
          "✗ Last update upload failed: ");

      Serial.println(
          firebaseData.errorReason());

      success = false;
    }
  }

  // ==========================================================
  // SENSOR HISTORY
  // ==========================================================
  //
  // IMPORTANT:
  //
  // We only create a historical log when BOTH
  // temperature and humidity are valid.
  //
  // This prevents incomplete records such as:
  //
  // Temperature: missing
  // Humidity: missing
  // LightIntensity: 602
  // SoilStatus: DRY
  //
  // Every new valid history record will contain
  // all four sensor values.
  // ==========================================================

  if (dhtSuccess) {

    FirebaseJson logData;

    // --------------------------------------------------------
    // Temperature
    // --------------------------------------------------------

    logData.set(
      "Temperature",
      temperature
    );

    // --------------------------------------------------------
    // Humidity
    // --------------------------------------------------------

    logData.set(
      "Humidity",
      humidity
    );

    // --------------------------------------------------------
    // Light
    // --------------------------------------------------------

    logData.set(
      "LightIntensity",
      lightValue
    );

    // --------------------------------------------------------
    // Soil
    // --------------------------------------------------------

    logData.set(
      "SoilStatus",
      soilStatus
    );

    // --------------------------------------------------------
    // Timestamp
    // --------------------------------------------------------

    logData.set(
      "Timestamp",
      unixTimestamp
    );

    // --------------------------------------------------------
    // Push complete history record
    // --------------------------------------------------------

    if (Firebase.pushJSON(
          firebaseData,
          "/SmartPlant/Logs",
          logData)) {

      Serial.println(
          "✓ COMPLETE sensor log uploaded.");

      Serial.println(
          "  Temperature + Humidity + Light + Soil");

    } else {

      Serial.print(
          "✗ Sensor log upload failed: ");

      Serial.println(
          firebaseData.errorReason());

      success = false;
    }

  } else {

    // --------------------------------------------------------
    // Do NOT create incomplete history record
    // --------------------------------------------------------

    Serial.println(
        "⚠ HISTORY LOG SKIPPED.");

    Serial.println(
        "  Reason: DHT22 temperature/humidity invalid.");

    Serial.println(
        "  No incomplete Firebase history record created.");
  }

  // ==========================================================
  // FINAL STATUS
  // ==========================================================

  Serial.println("----------------------------------------");

  if (success) {

    Serial.println(
        ">>> FIREBASE SYNC SUCCESS <<<");

  } else {

    Serial.println(
        ">>> FIREBASE SYNC FAILED <<<");
  }

  Serial.println(
      "========================================");
}

// ============================================================
// INITIALIZE NTP TIME
// ============================================================

void initializeTime() {

  Serial.println();
  Serial.println(
      "Synchronizing time with NTP...");

  configTime(
    GMT_OFFSET_SEC,
    DAYLIGHT_OFFSET_SEC,
    "pool.ntp.org",
    "time.nist.gov"
  );

  time_t now =
      time(nullptr);

  int attempts = 0;

  while (now < 100000 &&
         attempts < 30) {

    delay(500);

    Serial.print(".");

    now = time(nullptr);

    attempts++;
  }

  Serial.println();

  if (now >= 100000) {

    Serial.println(
        "Time synchronized successfully.");

    Serial.print(
        "Unix timestamp: ");

    Serial.println(
        (unsigned long)now);

  } else {

    Serial.println(
        "WARNING: NTP time synchronization failed.");

    Serial.println(
        "Logs may not contain a valid timestamp.");
  }
}

// ============================================================
// GET UNIX TIME
// ============================================================

unsigned long getUnixTime() {

  time_t now =
      time(nullptr);

  if (now < 100000) {

    return 0;
  }

  return (unsigned long)now;
}

// ============================================================
// UPLOAD DEVICE INFORMATION
// ============================================================

void uploadDeviceInformation() {

  String ipAddress =
      WiFi.localIP().toString();

  String macAddress =
      WiFi.macAddress();

  int wifiRSSI =
      WiFi.RSSI();

  unsigned long uptimeSeconds =
      millis() / 1000;

  unsigned long unixTimestamp =
      getUnixTime();

  Serial.println();
  Serial.println(
      "Uploading device information...");

  Firebase.setString(
    firebaseData,
    "/SmartPlant/Device/Status",
    "Connected"
  );

  Firebase.setString(
    firebaseData,
    "/SmartPlant/Device/IPAddress",
    ipAddress
  );

  Firebase.setString(
    firebaseData,
    "/SmartPlant/Device/MACAddress",
    macAddress
  );

  Firebase.setInt(
    firebaseData,
    "/SmartPlant/Device/WiFiRSSI",
    wifiRSSI
  );

  Firebase.setString(
    firebaseData,
    "/SmartPlant/Device/FirmwareVersion",
    FIRMWARE_VERSION
  );

  Firebase.setInt(
    firebaseData,
    "/SmartPlant/Device/UptimeSeconds",
    uptimeSeconds
  );

  if (unixTimestamp > 0) {

    Firebase.setInt(
      firebaseData,
      "/SmartPlant/Device/LastUpdateUnix",
      unixTimestamp
    );
  }

  Serial.println(
      "Device information uploaded.");
}