// ============================================================
// SMART PLANT CARE SYSTEM
// ESP8266 + DHT22 + LDR + YL-69 + Firebase
// ============================================================
//
// Firmware Version: v1.0.9-esp8266
//
// CURRENT WIRING
//
// Soil Sensor:
//   VCC  -> 3V3
//   GND  -> GND
//   AOUT -> A0
//   DOUT -> NC
//
// DHT22:
//   VCC  -> 3V3
//   GND  -> GND
//   DATA -> D2
//
// LDR Module:
//   VCC  -> 3V3
//   GND  -> GND
//   DOUT -> D6
//   AOUT -> NC
//
// FIREBASE ROOT:
//   /SmartPlant
//
// SOIL OUTPUT:
//   DRY (Needs Water!)
//   WET (Soil is fine)
//
// ============================================================

#include <ESP8266WiFi.h>
#include <DHT.h>
#include <FirebaseESP8266.h>
#include <time.h>

// ============================================================
// WIFI
// ============================================================

#define WIFI_SSID "WIFI"
#define WIFI_PASSWORD "Password"

// ============================================================
// FIREBASE
// ============================================================

#define FIREBASE_HOST \
  "smart-plant-care-fyp-2026-default-rtdb.firebaseio.com"

// ============================================================
// FIRMWARE
// ============================================================

#define FIRMWARE_VERSION "v1.0.9-esp8266"

// ============================================================
// PINS
// ============================================================

#define DHTPIN D2
#define DHTTYPE DHT22

// Soil AOUT
#define SOIL_AOUT_PIN A0

// LDR DOUT
#define LDR_DOUT_PIN D6

// ============================================================
// SENSOR OBJECT
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

unsigned long previousMillis = 0;

const unsigned long SENSOR_INTERVAL = 5000;

// ============================================================
// WIFI SETTINGS
// ============================================================

const unsigned long WIFI_TIMEOUT = 20000;

const unsigned long WIFI_RETRY_DELAY = 5000;

// ============================================================
// NTP
// ============================================================

const long GMT_OFFSET_SEC =
  5 * 60 * 60;

const int DAYLIGHT_OFFSET_SEC = 0;

// ============================================================
// DHT SETTINGS
// ============================================================

const int DHT_MAX_ATTEMPTS = 3;

const unsigned long DHT_RETRY_DELAY = 2200;

// ============================================================
// SOIL THRESHOLD
// ============================================================
//
// IMPORTANT:
//
// This is currently based on your observed readings.
//
// Current readings:
//
//   6
//   7
//   14
//
// We will calibrate this after hardware testing.
//
// If your sensor gives LOWER values when wet:
//
//   raw <= threshold -> WET
//   raw >  threshold -> DRY
//
// ============================================================

const int SOIL_WET_THRESHOLD = 10;

// ============================================================
// FUNCTION DECLARATIONS
// ============================================================

bool connectToWiFi();

void checkWiFiConnection();

void initializeTime();

unsigned long getUnixTime();

void initializeFirebase();

void uploadDeviceInformation();

int readSoilRaw();

String getSoilStatus(
  int soilRaw
);

int readLDR();

String getLightStatus(
  int ldrValue
);

bool readDHT22(
  float &temperature,
  float &humidity
);

bool uploadSensorData(
  int soilRaw,
  String soilStatus,
  int ldrValue,
  String lightStatus,
  float temperature,
  float humidity,
  bool dhtSuccess,
  int wifiRSSI,
  String ipAddress,
  String macAddress,
  unsigned long uptimeSeconds,
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
  Serial.println("       ESP8266 FIRMWARE v1.0.9");
  Serial.println("========================================");

  // ==========================================================
  // RESET DIAGNOSTICS
  // ==========================================================

  printResetReason();

  // ==========================================================
  // SENSOR INITIALIZATION
  // ==========================================================

  Serial.println();
  Serial.println("Initializing sensors...");

  pinMode(
    SOIL_AOUT_PIN,
    INPUT
  );

  pinMode(
    LDR_DOUT_PIN,
    INPUT
  );

  dht.begin();

  delay(1000);

  Serial.println("Sensors initialized.");

  // ==========================================================
  // WIRING INFORMATION
  // ==========================================================

  Serial.println();
  Serial.println("CURRENT SENSOR WIRING");
  Serial.println("----------------------------------------");

  Serial.println(
    "Soil AOUT -> A0"
  );

  Serial.println(
    "Soil DOUT -> NC"
  );

  Serial.println(
    "DHT22 DATA -> D2"
  );

  Serial.println(
    "LDR DOUT -> D6"
  );

  Serial.println(
    "LDR AOUT -> NC"
  );

  Serial.println(
    "========================================"
  );

  // ==========================================================
  // INITIAL SOIL TEST
  // ==========================================================

  Serial.println();
  Serial.println(
    "Initial Soil A0 Test"
  );

  Serial.print(
    "Soil A0 RAW: "
  );

  Serial.println(
    readSoilRaw()
  );

  // ==========================================================
  // WIFI
  // ==========================================================

  Serial.println();
  Serial.println(
    "Starting Wi-Fi connection..."
  );

  if (connectToWiFi()) {

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
  // TIME
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
  Serial.println("========================================");
}

// ============================================================
// LOOP
// ============================================================

void loop() {

  // ==========================================================
  // WIFI
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
  // SOIL SENSOR
  // ==========================================================

  int soilRaw =
    readSoilRaw();

  String soilStatus =
    getSoilStatus(
      soilRaw
    );

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
  // SERIAL MONITOR
  // ==========================================================

  Serial.println();
  Serial.println("========================================");
  Serial.println("          SENSOR READINGS");
  Serial.println("========================================");

  // ----------------------------------------------------------
  // SOIL
  // ----------------------------------------------------------

  Serial.print(
    "Soil A0 RAW: "
  );

  Serial.println(
    soilRaw
  );

  Serial.print(
    "Soil Status: "
  );

  Serial.println(
    soilStatus
  );

  // ----------------------------------------------------------
  // LDR
  // ----------------------------------------------------------

  Serial.print(
    "LDR D6 RAW: "
  );

  Serial.println(
    ldrValue
  );

  Serial.print(
    "LDR STATUS: "
  );

  Serial.println(
    lightStatus
  );

  // ----------------------------------------------------------
  // DHT22
  // ----------------------------------------------------------

  if (dhtSuccess) {

    Serial.print(
      "Temperature: "
    );

    Serial.print(
      temperature,
      2
    );

    Serial.println(
      " °C"
    );

    Serial.print(
      "Humidity: "
    );

    Serial.print(
      humidity,
      2
    );

    Serial.println(
      " %"
    );

  } else {

    Serial.println(
      "DHT22 ERROR!"
    );
  }

  // ----------------------------------------------------------
  // DEVICE
  // ----------------------------------------------------------

  Serial.print(
    "Unix Timestamp: "
  );

  Serial.println(
    unixTimestamp
  );

  Serial.print(
    "IP Address: "
  );

  Serial.println(
    ipAddress
  );

  Serial.print(
    "MAC Address: "
  );

  Serial.println(
    macAddress
  );

  Serial.print(
    "Wi-Fi RSSI: "
  );

  Serial.print(
    wifiRSSI
  );

  Serial.println(
    " dBm"
  );

  Serial.print(
    "Uptime: "
  );

  Serial.print(
    uptimeSeconds
  );

  Serial.println(
    " seconds"
  );

  // ==========================================================
  // FIREBASE
  // ==========================================================

  Serial.println("----------------------------------------");

  Serial.println(
    "Uploading data to Firebase..."
  );

  bool success =
    uploadSensorData(
      soilRaw,
      soilStatus,
      ldrValue,
      lightStatus,
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
  // FINAL STATUS
  // ==========================================================

  Serial.println("----------------------------------------");

  if (success) {

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
// READ SOIL
// ============================================================

int readSoilRaw() {

  const int samples = 5;

  long total = 0;

  for (
    int i = 0;
    i < samples;
    i++
  ) {

    total +=
      analogRead(
        SOIL_AOUT_PIN
      );

    delay(10);
  }

  return total / samples;
}

// ============================================================
// SOIL STATUS
// ============================================================

String getSoilStatus(
  int soilRaw
) {

  // Current YL-69 assumption:
  //
  // Lower ADC value = wetter
  // Higher ADC value = drier
  //

  if (
    soilRaw <=
    SOIL_WET_THRESHOLD
  ) {

    return "WET (Soil is fine)";

  } else {

    return "DRY (Needs Water!)";
  }
}

// ============================================================
// READ LDR
// ============================================================

int readLDR() {

  return digitalRead(
    LDR_DOUT_PIN
  );
}

// ============================================================
// LDR STATUS
// ============================================================

String getLightStatus(
  int ldrValue
) {

  if (
    ldrValue == HIGH
  ) {

    return "DARK";

  } else {

    return "BRIGHT";
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

    Serial.print(
      attempt
    );

    Serial.println(
      "..."
    );

    temperature =
      dht.readTemperature();

    humidity =
      dht.readHumidity();

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
// WIFI
// ============================================================

bool connectToWiFi() {

  Serial.println();
  Serial.println("========================================");
  Serial.println("           WI-FI CONNECTION");
  Serial.println("========================================");

  Serial.print(
    "SSID: "
  );

  Serial.println(
    WIFI_SSID
  );

  WiFi.mode(
    WIFI_STA
  );

  WiFi.disconnect();

  delay(300);

  WiFi.begin(
    WIFI_SSID,
    WIFI_PASSWORD
  );

  unsigned long startTime =
    millis();

  Serial.print(
    "Connecting"
  );

  while (
    WiFi.status() !=
      WL_CONNECTED &&
    millis() - startTime <
      WIFI_TIMEOUT
  ) {

    delay(500);

    Serial.print(
      "."
    );
  }

  Serial.println();

  if (
    WiFi.status() ==
    WL_CONNECTED
  ) {

    Serial.println(
      "Wi-Fi Connected!"
    );

    Serial.print(
      "IP Address: "
    );

    Serial.println(
      WiFi.localIP()
    );

    Serial.print(
      "MAC Address: "
    );

    Serial.println(
      WiFi.macAddress()
    );

    Serial.print(
      "Wi-Fi RSSI: "
    );

    Serial.print(
      WiFi.RSSI()
    );

    Serial.println(
      " dBm"
    );

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
// FIREBASE
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
// UPLOAD SENSOR DATA
// ============================================================

bool uploadSensorData(
  int soilRaw,
  String soilStatus,
  int ldrValue,
  String lightStatus,
  float temperature,
  float humidity,
  bool dhtSuccess,
  int wifiRSSI,
  String ipAddress,
  String macAddress,
  unsigned long uptimeSeconds,
  unsigned long unixTimestamp
) {

  bool success = true;

  // ==========================================================
  // SOIL RAW
  // ==========================================================

  if (
    Firebase.setInt(
      firebaseData,
      "/SmartPlant/SoilMoistureRaw",
      soilRaw
    )
  ) {

    Serial.println(
      "✓ Soil raw value uploaded."
    );

  } else {

    Serial.print(
      "✗ Soil raw upload failed: "
    );

    Serial.println(
      firebaseData.errorReason()
    );

    success = false;
  }

  // ==========================================================
  // SOIL STATUS
  // ==========================================================

  if (
    Firebase.setString(
      firebaseData,
      "/SmartPlant/SoilStatus",
      soilStatus
    )
  ) {

    Serial.println(
      "✓ Soil status uploaded."
    );

  } else {

    Serial.print(
      "✗ Soil status upload failed: "
    );

    Serial.println(
      firebaseData.errorReason()
    );

    success = false;
  }

  // ==========================================================
  // LDR
  // ==========================================================

  if (
    Firebase.setInt(
      firebaseData,
      "/SmartPlant/LightIntensity",
      ldrValue
    )
  ) {

    Serial.println(
      "✓ Light value uploaded."
    );

  } else {

    Serial.print(
      "✗ Light upload failed: "
    );

    Serial.println(
      firebaseData.errorReason()
    );

    success = false;
  }

  // ==========================================================
  // LIGHT STATUS
  // ==========================================================

  if (
    Firebase.setString(
      firebaseData,
      "/SmartPlant/LightStatus",
      lightStatus
    )
  ) {

    Serial.println(
      "✓ Light status uploaded."
    );

  } else {

    Serial.print(
      "✗ Light status upload failed: "
    );

    Serial.println(
      firebaseData.errorReason()
    );

    success = false;
  }

  // ==========================================================
  // TEMPERATURE
  // ==========================================================

  if (dhtSuccess) {

    if (
      Firebase.setFloat(
        firebaseData,
        "/SmartPlant/Temperature",
        temperature
      )
    ) {

      Serial.println(
        "✓ Temperature uploaded."
      );

    } else {

      Serial.print(
        "✗ Temperature upload failed: "
      );

      Serial.println(
        firebaseData.errorReason()
      );

      success = false;
    }

  } else {

    Serial.println(
      "⚠ Temperature skipped."
    );
  }

  // ==========================================================
  // HUMIDITY
  // ==========================================================

  if (dhtSuccess) {

    if (
      Firebase.setFloat(
        firebaseData,
        "/SmartPlant/Humidity",
        humidity
      )
    ) {

      Serial.println(
        "✓ Humidity uploaded."
      );

    } else {

      Serial.print(
        "✗ Humidity upload failed: "
      );

      Serial.println(
        firebaseData.errorReason()
      );

      success = false;
    }

  } else {

    Serial.println(
      "⚠ Humidity skipped."
    );
  }

  // ==========================================================
  // DEVICE STATUS
  // ==========================================================

  if (
    Firebase.setString(
      firebaseData,
      "/SmartPlant/Device/Status",
      "Connected"
    )
  ) {

    Serial.println(
      "✓ Device status uploaded."
    );

  } else {

    success = false;
  }

  // ==========================================================
  // IP
  // ==========================================================

  if (
    Firebase.setString(
      firebaseData,
      "/SmartPlant/Device/IPAddress",
      ipAddress
    )
  ) {

    Serial.println(
      "✓ IP address uploaded."
    );

  } else {

    success = false;
  }

  // ==========================================================
  // MAC
  // ==========================================================

  if (
    Firebase.setString(
      firebaseData,
      "/SmartPlant/Device/MACAddress",
      macAddress
    )
  ) {

    Serial.println(
      "✓ MAC address uploaded."
    );

  } else {

    success = false;
  }

  // ==========================================================
  // RSSI
  // ==========================================================

  if (
    Firebase.setInt(
      firebaseData,
      "/SmartPlant/Device/WiFiRSSI",
      wifiRSSI
    )
  ) {

    Serial.println(
      "✓ Wi-Fi RSSI uploaded."
    );

  } else {

    success = false;
  }

  // ==========================================================
  // FIRMWARE
  // ==========================================================

  if (
    Firebase.setString(
      firebaseData,
      "/SmartPlant/Device/FirmwareVersion",
      FIRMWARE_VERSION
    )
  ) {

    Serial.println(
      "✓ Firmware version uploaded."
    );

  } else {

    success = false;
  }

  // ==========================================================
  // UPTIME
  // ==========================================================

  if (
    Firebase.setInt(
      firebaseData,
      "/SmartPlant/Device/UptimeSeconds",
      uptimeSeconds
    )
  ) {

    Serial.println(
      "✓ Uptime uploaded."
    );

  } else {

    success = false;
  }

  // ==========================================================
  // LAST UPDATE
  // ==========================================================

  if (
    unixTimestamp > 0
  ) {

    if (
      Firebase.setInt(
        firebaseData,
        "/SmartPlant/Device/LastUpdateUnix",
        unixTimestamp
      )
    ) {

      Serial.println(
        "✓ Last update uploaded."
      );

    } else {

      success = false;
    }
  }

  // ==========================================================
  // HISTORY
  // ==========================================================

  if (dhtSuccess) {

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
      soilRaw
    );

    logData.set(
      "SoilStatus",
      soilStatus
    );

    logData.set(
      "Timestamp",
      unixTimestamp
    );

    if (
      Firebase.pushJSON(
        firebaseData,
        "/SmartPlant/Logs",
        logData
      )
    ) {

      Serial.println(
        "✓ COMPLETE sensor log uploaded."
      );

    } else {

      Serial.print(
        "✗ Sensor log upload failed: "
      );

      Serial.println(
        firebaseData.errorReason()
      );

      success = false;
    }

  } else {

    Serial.println(
      "⚠ HISTORY LOG SKIPPED."
    );
  }

  return success;
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

    Serial.print(
      "."
    );

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

  if (
    unixTimestamp > 0
  ) {

    Firebase.setInt(
      firebaseData,
      "/SmartPlant/Device/LastUpdateUnix",
      unixTimestamp
    );
  }

  Serial.println(
    "Device information upload completed."
  );
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