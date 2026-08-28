// ============================================================
// SMART PLANT CARE SYSTEM
// ESP8266 + DHT22 + LDR + Soil Moisture + Firebase
// ============================================================
//
// Firmware Version: v1.2.0-esp8266
//
// TESTED SENSOR CONFIGURATION
// ------------------------------------------------------------
//
// LDR:
//   AOUT -> A0
//
// Soil Moisture:
//   DOUT -> D7
//
// DHT22:
//   DATA -> D5
//
// Firebase:
//   /SmartPlant
//
// ============================================================

#include <ESP8266WiFi.h>
#include <DHT.h>
#include <FirebaseESP8266.h>
#include <time.h>

// ============================================================
// WIFI
// ============================================================

#define WIFI_SSID "SSID"
#define WIFI_PASSWORD "Enter password"

// ============================================================
// FIREBASE
// ============================================================

#define FIREBASE_HOST \
  "smart-plant-care-fyp-2026-default-rtdb.firebaseio.com"

// ============================================================
// FIRMWARE
// ============================================================

#define FIRMWARE_VERSION "v1.2.0-esp8266"

// ============================================================
// SENSOR PINS
// ============================================================

// LDR AOUT -> A0
#define LDR_PIN A0

// Soil DOUT -> D7
#define SOIL_PIN D7

// DHT22 DATA -> D5
#define DHTPIN D5
#define DHTTYPE DHT22

// ============================================================
// DHT OBJECT
// ============================================================

DHT dht(
  DHTPIN,
  DHTTYPE
);

// ============================================================
// FIREBASE OBJECTS
// ============================================================

FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

// ============================================================
// TIMING
// ============================================================

// Read sensors and update Firebase every 10 seconds.
const unsigned long SENSOR_INTERVAL = 10000;

// Store history once every 60 seconds.
const unsigned long HISTORY_INTERVAL = 60000;

// Wi-Fi connection timeout.
const unsigned long WIFI_TIMEOUT = 20000;

// Delay before Wi-Fi reconnection attempt.
const unsigned long WIFI_RETRY_DELAY = 5000;

// ============================================================
// NTP
// ============================================================

const long GMT_OFFSET_SEC = 5 * 60 * 60;

const int DAYLIGHT_OFFSET_SEC = 0;

// ============================================================
// DHT22
// ============================================================

const int DHT_MAX_ATTEMPTS = 3;

// DHT22 needs approximately 2 seconds between readings.
const unsigned long DHT_RETRY_DELAY = 2200;

// ============================================================
// SOIL
// ============================================================
//
// Based on your tested digital soil sensor code:
//
// HIGH = DRY
// LOW  = WET
//
// ============================================================

// ============================================================
// LDR
// ============================================================
//
// Based on your tested analog LDR code:
//
// LDR value > 500 = DARK
// LDR value <= 500 = BRIGHT
//
// Change this later after observing real readings.
// ============================================================

const int LDR_DARK_THRESHOLD = 500;

// ============================================================
// GLOBAL TIMERS
// ============================================================

unsigned long previousMillis = 0;

unsigned long lastHistoryMillis = 0;

// ============================================================
// FUNCTION DECLARATIONS
// ============================================================

bool connectToWiFi();

void checkWiFiConnection();

void initializeTime();

unsigned long getUnixTime();

void initializeFirebase();

void uploadDeviceInformation();

int readLDR();

String getLightStatus(
  int ldrValue
);

int readSoilDigital();

String getSoilStatus(
  int soilValue
);

bool readDHT22(
  float &temperature,
  float &humidity
);

bool uploadSensorData(
  int ldrValue,
  String lightStatus,
  int soilValue,
  String soilStatus,
  float temperature,
  float humidity,
  bool dhtSuccess,
  int wifiRSSI,
  String ipAddress,
  String macAddress,
  unsigned long uptimeSeconds,
  unsigned long unixTimestamp
);

bool uploadHistory(
  int ldrValue,
  String lightStatus,
  int soilValue,
  String soilStatus,
  float temperature,
  float humidity,
  unsigned long unixTimestamp
);

void printResetReason();

// ============================================================
// SETUP
// ============================================================

void setup() {

  Serial.begin(115200);

  delay(1000);

  Serial.println();
  Serial.println();

  Serial.println("========================================");
  Serial.println("     SMART PLANT CARE SYSTEM");
  Serial.println("       ESP8266 FIRMWARE v1.2.0");
  Serial.println("========================================");

  // ==========================================================
  // RESET INFORMATION
  // ==========================================================

  printResetReason();

  // ==========================================================
  // SENSOR INITIALIZATION
  // ==========================================================

  Serial.println();
  Serial.println("Initializing sensors...");

  // LDR AOUT -> A0
  pinMode(
    LDR_PIN,
    INPUT
  );

  // Soil DOUT -> D7
  pinMode(
    SOIL_PIN,
    INPUT_PULLUP
  );

  // DHT22 DATA -> D5
  dht.begin();

  delay(1000);

  Serial.println("Sensors initialized.");

  // ==========================================================
  // WIRING INFORMATION
  // ==========================================================

  Serial.println();
  Serial.println("CURRENT SENSOR WIRING");
  Serial.println("----------------------------------------");

  Serial.println("LDR AOUT -> A0");
  Serial.println("Soil DOUT -> D7");
  Serial.println("DHT22 DATA -> D5");

  Serial.println("----------------------------------------");

  // ==========================================================
  // INITIAL SENSOR TEST
  // ==========================================================

  Serial.println();
  Serial.println("Initial Sensor Test");
  Serial.println("----------------------------------------");

  int initialLDR =
    readLDR();

  int initialSoil =
    readSoilDigital();

  Serial.print("LDR A0 RAW: ");
  Serial.println(initialLDR);

  Serial.print("LDR STATUS: ");
  Serial.println(
    getLightStatus(initialLDR)
  );

  Serial.print("SOIL D7 RAW: ");
  Serial.println(initialSoil);

  Serial.print("SOIL STATUS: ");
  Serial.println(
    getSoilStatus(initialSoil)
  );

  Serial.println("----------------------------------------");

  // ==========================================================
  // WIFI
  // ==========================================================

  Serial.println();
  Serial.println(
    "Starting Wi-Fi connection..."
  );

  if (
    connectToWiFi()
  ) {

    Serial.println();
    Serial.println(
      "Wi-Fi connection successful."
    );

  } else {

    Serial.println();
    Serial.println(
      "WARNING: Wi-Fi connection failed."
    );

    Serial.println(
      "System will retry automatically."
    );
  }

  // ==========================================================
  // NTP
  // ==========================================================

  if (
    WiFi.status() ==
    WL_CONNECTED
  ) {

    initializeTime();

  } else {

    Serial.println(
      "NTP skipped because Wi-Fi is unavailable."
    );
  }

  // ==========================================================
  // FIREBASE
  // ==========================================================

  initializeFirebase();

  // ==========================================================
  // DEVICE INFORMATION
  // ==========================================================

  if (
    WiFi.status() ==
    WL_CONNECTED
  ) {

    delay(500);

    uploadDeviceInformation();

  } else {

    Serial.println(
      "Device information upload skipped."
    );
  }

  // ==========================================================
  // READY
  // ==========================================================

  Serial.println();
  Serial.println("========================================");
  Serial.println("System Ready.");
  Serial.print("Firmware: ");
  Serial.println(FIRMWARE_VERSION);

  Serial.print("Sensor interval: ");
  Serial.print(
    SENSOR_INTERVAL / 1000
  );
  Serial.println(" seconds");

  Serial.print("History interval: ");
  Serial.print(
    HISTORY_INTERVAL / 1000
  );
  Serial.println(" seconds");

  Serial.println("========================================");
}

// ============================================================
// LOOP
// ============================================================

void loop() {

  // ==========================================================
  // CHECK WIFI
  // ==========================================================

  checkWiFiConnection();

  if (
    WiFi.status() !=
    WL_CONNECTED
  ) {

    delay(1000);

    return;
  }

  // ==========================================================
  // TIMER
  // ==========================================================

  unsigned long currentMillis =
    millis();

  if (
    currentMillis - previousMillis <
    SENSOR_INTERVAL
  ) {

    return;
  }

  previousMillis =
    currentMillis;

  // ==========================================================
  // LDR
  // ==========================================================

  int ldrValue =
    readLDR();

  String lightStatus =
    getLightStatus(
      ldrValue
    );

  // ==========================================================
  // SOIL
  // ==========================================================

  int soilValue =
    readSoilDigital();

  String soilStatus =
    getSoilStatus(
      soilValue
    );

  // ==========================================================
  // DHT22
  // ==========================================================

  float temperature = NAN;

  float humidity = NAN;

  bool dhtSuccess =
    readDHT22(
      temperature,
      humidity
    );

  // ==========================================================
  // DEVICE INFORMATION
  // ==========================================================

  int wifiRSSI =
    WiFi.RSSI();

  String ipAddress =
    WiFi.localIP().toString();

  String macAddress =
    WiFi.macAddress();

  unsigned long uptimeSeconds =
    millis() / 1000;

  unsigned long unixTimestamp =
    getUnixTime();

  // ==========================================================
  // SERIAL OUTPUT
  // ==========================================================

  Serial.println();
  Serial.println("========================================");
  Serial.println("          SENSOR READINGS");
  Serial.println("========================================");

  // ----------------------------------------------------------
  // LDR
  // ----------------------------------------------------------

  Serial.print("LDR ANALOG RAW: ");
  Serial.println(ldrValue);

  Serial.print("LDR STATUS: ");
  Serial.println(lightStatus);

  // ----------------------------------------------------------
  // SOIL
  // ----------------------------------------------------------

  Serial.print("SOIL DIGITAL RAW: ");
  Serial.println(soilValue);

  Serial.print("SOIL STATUS: ");
  Serial.println(soilStatus);

  // ----------------------------------------------------------
  // DHT22
  // ----------------------------------------------------------

  if (dhtSuccess) {

    Serial.print("Humidity: ");
    Serial.print(
      humidity,
      2
    );

    Serial.println("%");

    Serial.print("Temperature: ");
    Serial.print(
      temperature,
      2
    );

    Serial.println("°C");

  } else {

    Serial.println(
      "DHT22 ERROR - Temperature/Humidity unavailable."
    );
  }

  // ----------------------------------------------------------
  // DEVICE
  // ----------------------------------------------------------

  Serial.print("Unix Timestamp: ");
  Serial.println(unixTimestamp);

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
  // FIREBASE CURRENT DATA
  // ==========================================================

  Serial.println("----------------------------------------");

  Serial.println(
    "Uploading current data to Firebase..."
  );

  bool currentDataSuccess =
    uploadSensorData(
      ldrValue,
      lightStatus,
      soilValue,
      soilStatus,
      temperature,
      humidity,
      dhtSuccess,
      wifiRSSI,
      ipAddress,
      macAddress,
      uptimeSeconds,
      unixTimestamp
    );

  // ==========================================================
  // HISTORY
  // ==========================================================

  bool historySuccess = true;

  if (
    currentMillis - lastHistoryMillis >=
    HISTORY_INTERVAL
  ) {

    Serial.println("----------------------------------------");

    Serial.println(
      "Uploading history record..."
    );

    if (dhtSuccess) {

      historySuccess =
        uploadHistory(
          ldrValue,
          lightStatus,
          soilValue,
          soilStatus,
          temperature,
          humidity,
          unixTimestamp
        );

    } else {

      Serial.println(
        "History skipped because DHT22 failed."
      );
    }

    lastHistoryMillis =
      currentMillis;
  }

  // ==========================================================
  // FINAL STATUS
  // ==========================================================

  Serial.println("----------------------------------------");

  if (
    currentDataSuccess &&
    historySuccess
  ) {

    Serial.println(
      ">>> FIREBASE SYNC SUCCESS <<<"
    );

  } else {

    Serial.println(
      ">>> FIREBASE SYNC COMPLETED WITH ERRORS <<<"
    );
  }

  Serial.println(
    "========================================"
  );
}

// ============================================================
// READ LDR
// ============================================================

int readLDR() {

  return analogRead(
    LDR_PIN
  );
}

// ============================================================
// LDR STATUS
// ============================================================

String getLightStatus(
  int ldrValue
) {

  if (
    ldrValue > LDR_DARK_THRESHOLD
  ) {

    return "DARK";

  } else {

    return "BRIGHT";
  }
}

// ============================================================
// READ SOIL DIGITAL
// ============================================================

int readSoilDigital() {

  return digitalRead(
    SOIL_PIN
  );
}

// ============================================================
// SOIL STATUS
// ============================================================
//
// Based on your tested code:
//
// HIGH = DRY
// LOW  = WET
//
// ============================================================

String getSoilStatus(
  int soilValue
) {

  if (
    soilValue == HIGH
  ) {

    return "DRY (Needs Water!)";

  } else {

    return "WET (Soil is fine)";
  }
}

// ============================================================
// READ DHT22
// ============================================================

bool readDHT22(
  float &temperature,
  float &humidity
) {

  for (
    int attempt = 1;
    attempt <= DHT_MAX_ATTEMPTS;
    attempt++
  ) {

    Serial.print(
      "DHT22 reading attempt "
    );

    Serial.print(attempt);

    Serial.println("...");

    humidity =
      dht.readHumidity();

    temperature =
      dht.readTemperature();

    if (
      !isnan(temperature) &&
      !isnan(humidity)
    ) {

      return true;
    }

    Serial.println(
      "DHT22 reading failed."
    );

    if (
      attempt <
      DHT_MAX_ATTEMPTS
    ) {

      delay(
        DHT_RETRY_DELAY
      );
    }
  }

  return false;
}

// ============================================================
// WIFI CONNECTION
// ============================================================

bool connectToWiFi() {

  Serial.println();
  Serial.println("========================================");
  Serial.println("           WI-FI CONNECTION");
  Serial.println("========================================");

  Serial.print("SSID: ");
  Serial.println(WIFI_SSID);

  WiFi.mode(
    WIFI_STA
  );

  WiFi.disconnect();

  delay(300);

  // Disable Wi-Fi sleep.
  // Helps maintain stable HTTPS connections.
  WiFi.setSleepMode(
    WIFI_NONE_SLEEP
  );

  WiFi.setAutoReconnect(
    true
  );

  WiFi.begin(
    WIFI_SSID,
    WIFI_PASSWORD
  );

  unsigned long startTime =
    millis();

  Serial.print("Connecting");

  while (
    WiFi.status() !=
      WL_CONNECTED &&
    millis() - startTime <
      WIFI_TIMEOUT
  ) {

    delay(500);

    Serial.print(".");
  }

  Serial.println();

  if (
    WiFi.status() ==
    WL_CONNECTED
  ) {

    Serial.println(
      "Wi-Fi Connected!"
    );

    Serial.print("IP Address: ");
    Serial.println(
      WiFi.localIP()
    );

    Serial.print("MAC Address: ");
    Serial.println(
      WiFi.macAddress()
    );

    Serial.print("Wi-Fi RSSI: ");
    Serial.print(
      WiFi.RSSI()
    );

    Serial.println(" dBm");

    Serial.println(
      "========================================"
    );

    return true;
  }

  Serial.println(
    "Wi-Fi connection FAILED."
  );

  Serial.print(
    "WiFi Status Code: "
  );

  Serial.println(
    WiFi.status()
  );

  Serial.println(
    "========================================"
  );

  return false;
}

// ============================================================
// WIFI RECONNECTION
// ============================================================

void checkWiFiConnection() {

  if (
    WiFi.status() ==
    WL_CONNECTED
  ) {

    return;
  }

  Serial.println();
  Serial.println(
    "Wi-Fi disconnected!"
  );

  Serial.println(
    "Attempting reconnection..."
  );

  delay(
    WIFI_RETRY_DELAY
  );

  if (
    connectToWiFi()
  ) {

    Serial.println(
      "Wi-Fi reconnection successful."
    );

  } else {

    Serial.println(
      "Wi-Fi reconnection failed."
    );
  }
}

// ============================================================
// FIREBASE INITIALIZATION
// ============================================================

void initializeFirebase() {

  Serial.println();
  Serial.println("========================================");
  Serial.println("       INITIALIZING FIREBASE");
  Serial.println("========================================");

  config.host =
    FIREBASE_HOST;

  config.database_url =
    FIREBASE_HOST;

  // Current Firebase project configuration.
  config.signer.test_mode =
    true;

  firebaseData.setBSSLBufferSize(
    4096,
    1024
  );

  firebaseData.setResponseSize(
    2048
  );

  Firebase.begin(
    &config,
    &auth
  );

  Firebase.reconnectWiFi(
    true
  );

  delay(500);

  Serial.println(
    "Firebase initialized."
  );

  Serial.println(
    "========================================"
  );
}

// ============================================================
// UPLOAD CURRENT DATA
// ============================================================
//
// ONE Firebase updateNode() request.
//
// This is the major improvement over the previous firmware.
// ============================================================

bool uploadSensorData(
  int ldrValue,
  String lightStatus,
  int soilValue,
  String soilStatus,
  float temperature,
  float humidity,
  bool dhtSuccess,
  int wifiRSSI,
  String ipAddress,
  String macAddress,
  unsigned long uptimeSeconds,
  unsigned long unixTimestamp
) {

  if (
    WiFi.status() !=
    WL_CONNECTED
  ) {

    Serial.println(
      "✗ Firebase upload skipped: Wi-Fi disconnected."
    );

    return false;
  }

  FirebaseJson json;

  // ==========================================================
  // LDR
  // ==========================================================

  json.set(
    "LightIntensity",
    ldrValue
  );

  json.set(
    "LightStatus",
    lightStatus
  );

  // ==========================================================
  // SOIL
  // ==========================================================

  json.set(
    "SoilMoistureRaw",
    soilValue
  );

  json.set(
    "SoilStatus",
    soilStatus
  );

  // ==========================================================
  // DHT22
  // ==========================================================

  if (dhtSuccess) {

    json.set(
      "Temperature",
      temperature
    );

    json.set(
      "Humidity",
      humidity
    );

  } else {

    Serial.println(
      "⚠ DHT22 data not included in Firebase update."
    );
  }

  // ==========================================================
  // DEVICE
  // ==========================================================

  json.set(
    "Device/Status",
    "Connected"
  );

  json.set(
    "Device/IPAddress",
    ipAddress
  );

  json.set(
    "Device/MACAddress",
    macAddress
  );

  json.set(
    "Device/WiFiRSSI",
    wifiRSSI
  );

  json.set(
    "Device/FirmwareVersion",
    FIRMWARE_VERSION
  );

  json.set(
    "Device/UptimeSeconds",
    uptimeSeconds
  );

  if (
    unixTimestamp > 0
  ) {

    json.set(
      "Device/LastUpdateUnix",
      unixTimestamp
    );
  }

  // ==========================================================
  // ONE FIREBASE REQUEST
  // ==========================================================

  Serial.println(
    "Sending ONE Firebase update..."
  );

  bool result =
    Firebase.updateNode(
      firebaseData,
      "/SmartPlant",
      json
    );

  if (result) {

    Serial.println(
      "✓ Current sensor/device data uploaded."
    );

    return true;
  }

  Serial.print(
    "✗ Firebase update failed: "
  );

  Serial.println(
    firebaseData.errorReason()
  );

  return false;
}

// ============================================================
// HISTORY
// ============================================================

bool uploadHistory(
  int ldrValue,
  String lightStatus,
  int soilValue,
  String soilStatus,
  float temperature,
  float humidity,
  unsigned long unixTimestamp
) {

  if (
    WiFi.status() !=
    WL_CONNECTED
  ) {

    Serial.println(
      "✗ History upload skipped: Wi-Fi disconnected."
    );

    return false;
  }

  FirebaseJson logData;

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
    ldrValue
  );

  logData.set(
    "LightStatus",
    lightStatus
  );

  logData.set(
    "SoilMoistureRaw",
    soilValue
  );

  logData.set(
    "SoilStatus",
    soilStatus
  );

  logData.set(
    "Timestamp",
    unixTimestamp
  );

  bool result =
    Firebase.pushJSON(
      firebaseData,
      "/SmartPlant/Logs",
      logData
    );

  if (result) {

    Serial.println(
      "✓ History record uploaded."
    );

    return true;
  }

  Serial.print(
    "✗ History upload failed: "
  );

  Serial.println(
    firebaseData.errorReason()
  );

  return false;
}

// ============================================================
// NTP
// ============================================================

void initializeTime() {

  Serial.println();
  Serial.println(
    "Synchronizing time with NTP..."
  );

  configTime(
    GMT_OFFSET_SEC,
    DAYLIGHT_OFFSET_SEC,
    "pool.ntp.org",
    "time.nist.gov"
  );

  time_t now =
    time(nullptr);

  int attempts = 0;

  while (
    now < 100000 &&
    attempts < 30
  ) {

    delay(500);

    Serial.print(".");

    now =
      time(nullptr);

    attempts++;
  }

  Serial.println();

  if (
    now >= 100000
  ) {

    Serial.println(
      "Time synchronized successfully."
    );

    Serial.print(
      "Unix timestamp: "
    );

    Serial.println(
      (unsigned long)now
    );

  } else {

    Serial.println(
      "WARNING: NTP synchronization failed."
    );
  }
}

// ============================================================
// UNIX TIME
// ============================================================

unsigned long getUnixTime() {

  time_t now =
    time(nullptr);

  if (
    now < 100000
  ) {

    return 0;
  }

  return (
    unsigned long
  ) now;
}

// ============================================================
// DEVICE INFORMATION
// ============================================================

void uploadDeviceInformation() {

  if (
    WiFi.status() !=
    WL_CONNECTED
  ) {

    return;
  }

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
    "Uploading device information..."
  );

  FirebaseJson deviceJson;

  deviceJson.set(
    "Status",
    "Connected"
  );

  deviceJson.set(
    "IPAddress",
    ipAddress
  );

  deviceJson.set(
    "MACAddress",
    macAddress
  );

  deviceJson.set(
    "WiFiRSSI",
    wifiRSSI
  );

  deviceJson.set(
    "FirmwareVersion",
    FIRMWARE_VERSION
  );

  deviceJson.set(
    "UptimeSeconds",
    uptimeSeconds
  );

  if (
    unixTimestamp > 0
  ) {

    deviceJson.set(
      "LastUpdateUnix",
      unixTimestamp
    );
  }

  bool result =
    Firebase.updateNode(
      firebaseData,
      "/SmartPlant/Device",
      deviceJson
    );

  if (result) {

    Serial.println(
      "✓ Device information uploaded."
    );

  } else {

    Serial.print(
      "✗ Device information upload failed: "
    );

    Serial.println(
      firebaseData.errorReason()
    );
  }
}

// ============================================================
// RESET INFORMATION
// ============================================================

void printResetReason() {

  Serial.println();
  Serial.println(
    "ESP8266 Reset Information"
  );

  Serial.print(
    "Reset reason: "
  );

  Serial.println(
    ESP.getResetReason()
  );

  Serial.print(
    "Reset info: "
  );

  Serial.println(
    ESP.getResetInfo()
  );

  Serial.print(
    "Free heap: "
  );

  Serial.print(
    ESP.getFreeHeap()
  );

  Serial.println(
    " bytes"
  );

  Serial.print(
    "Chip ID: "
  );

  Serial.println(
    ESP.getChipId(),
    HEX
  );

  Serial.println(
    "----------------------------------------"
  );
}
