/*
 * NOVARA Smart Poultry System - ESP32 Main Controller Firmware
 * 
 * Hardware: Standard ESP32 Dev Board (WROOM-32 / 38-Pin)
 * Actuators & Sensors:
 *  1. Water Level Sensor (GPIO 34) -> Triggers Water Pump Relay 1 (GPIO 26) when NO water is detected.
 *  2. Food Dispenser Servo Motor (GPIO 18) -> Periodically opens flap to feed chickens.
 *  3. Heating Output / Relay 2 / LED (GPIO 27) -> Controls warming bulb / heating LED based on low temp threshold.
 *  4. DHT11/DHT22 Temp & Humidity Sensor (GPIO 16) -> Continuous environmental monitoring.
 *  5. I2C OLED Display (SDA: GPIO 21, SCL: GPIO 22) -> Real-time local LCD/OLED dashboard display.
 *  6. Captive Portal Wi-Fi Configuration Manager (Access Point: "NOVARA-Poultry-Setup").
 *  7. REST API telemetry reporting & command polling with Express / Railway backend server.
 */

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <Preferences.h>
#include <ESP32Servo.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <DHT.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// ---------------------------------------------------------------------------
// Hardware GPIO Pin Configurations
// ---------------------------------------------------------------------------
#define WATER_SENSOR_PIN   34  // Input: Water detection sensor (Analog/Digital)
#define PUMP_RELAY_PIN     26  // Output: Relay 1 for Water Pump
#define SERVO_FEEDER_PIN   18  // Output PWM: Servo Motor for Food Supply
#define HEAT_RELAY_PIN     27  // Output: Relay 2 / LED for Heating Output
#define RESET_WIFI_BUTTON   4  // Input Pullup: Wi-Fi Reset Button
#define DHT_PIN            16  // Input/Output: DHT Temperature & Humidity Sensor
#define OLED_SDA_PIN       21  // I2C Data Pin for OLED Display
#define OLED_SCL_PIN       22  // I2C Clock Pin for OLED Display

// ---------------------------------------------------------------------------
// DHT Sensor Configuration
// ---------------------------------------------------------------------------
#define DHTTYPE DHT11   // Set to DHT11 or DHT22 according to your physical sensor module

// ---------------------------------------------------------------------------
// OLED Display Parameters (Standard 128x64 I2C OLED)
// ---------------------------------------------------------------------------
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1  // Reset pin # (or -1 if sharing Arduino reset pin)

// ---------------------------------------------------------------------------
// Logic Level Macros
// ---------------------------------------------------------------------------
#define RELAY_ON   LOW   // For Active-LOW relay module
#define RELAY_OFF  HIGH  // For Active-LOW relay module

// Flexible Heating State Macro:
// For Prototype LED (GPIO 27 -> LED -> GND): HEATING_ACTIVE_STATE is HIGH, HEATING_INACTIVE_STATE is LOW.
// For Active-LOW Relay Module (Heating Bulb): Set HEATING_ACTIVE_STATE to RELAY_ON (LOW).
#define HEATING_ACTIVE_STATE   HIGH
#define HEATING_INACTIVE_STATE LOW

// ---------------------------------------------------------------------------
// Temperature Regulation Thresholds
// ---------------------------------------------------------------------------
float LOW_TEMPERATURE_THRESHOLD = 25.0; // Minimum acceptable temperature in °C (Heater turns ON when temp < 25.0°C)

// ---------------------------------------------------------------------------
// System Parameters & Intervals (Railway Cloud Production Endpoints)
// ---------------------------------------------------------------------------
const char* BACKEND_TELEMETRY_URL = "https://my-project-production-f607.up.railway.app/api/sensors/telemetry";
const char* BACKEND_POLL_URL      = "https://my-project-production-f607.up.railway.app/api/sensors/commands/pending?deviceSerial=ESP32-POULTRY-01";

// Configurable feeding parameters (persisted in NVS Preferences)
unsigned long feedingIntervalHours = 6;  // Feed interval (in hours, default 6 hours)
unsigned long feedingDurationMs = 1000; // Flap open duration (set to 1000ms / 1s)

const int SERVO_CLOSED_ANGLE = 0;   // Flap closed (Resting initial position at 0°)
const int SERVO_OPEN_ANGLE   = 90;  // Flap open (Rotates Anti-Clockwise to 90°, Closes Clockwise)

// ---------------------------------------------------------------------------
// Global Variables & Objects
// ---------------------------------------------------------------------------
WebServer server(80);
DNSServer dnsServer;
Preferences preferences;
Servo feederServo;
DHT dht(DHT_PIN, DHTTYPE);
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

const byte DNS_PORT = 53;
const char* AP_SSID = "NOVARA-Poultry-Setup";

bool isPortalMode = false;
bool waterDetected = false;
bool pumpState = false;
bool heatLampState = false;
bool isDispensingFood = false;
bool oledInitialized = false;
uint8_t detectedOledAddress = 0x3C; // Default I2C address for SSD1306

float currentTemp = 0.0;
float currentHumidity = 0.0;
bool dhtReadSuccess = false;

unsigned long lastFeedTime = 0;
unsigned long lastTelemetryTime = 0;
unsigned long lastCommandPollTime = 0;
unsigned long lastDhtReadTime = 0;
unsigned long lastDisplayUpdateTime = 0;
unsigned long lastSerialDebugTime = 0;
int totalFeedCycles = 0;

// ---------------------------------------------------------------------------
// I2C Scanner Routine (Detects OLED or any I2C Peripheral on GPIO 21 & 22)
// ---------------------------------------------------------------------------
uint8_t scanI2CAddress() {
  Serial.println("\n🔍 Scanning I2C Bus (SDA: GPIO 21, SCL: GPIO 22)...");
  byte error, address;
  int nDevices = 0;
  uint8_t foundAddress = 0;

  for (address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();

    if (error == 0) {
      Serial.printf("  -> I2C device found at address 0x%02X!\n", address);
      if (address == 0x3C || address == 0x3D) {
        foundAddress = address;
      }
      nDevices++;
    } else if (error == 4) {
      Serial.printf("  -> Unknown error at address 0x%02X\n", address);
    }
  }

  if (nDevices == 0) {
    Serial.println("❌ No I2C devices found on pins GPIO 21 (SDA) / GPIO 22 (SCL).");
    Serial.println("   Check wiring: VCC -> 3.3V, GND -> GND, SDA -> GPIO 21, SCL -> GPIO 22.");
  } else {
    Serial.printf("✅ I2C Scan finished. Found %d device(s).\n", nDevices);
  }

  return (foundAddress != 0) ? foundAddress : 0x3C;
}

// ---------------------------------------------------------------------------
// OLED Display Helper Functions
// ---------------------------------------------------------------------------
void initOLEDDisplay() {
  Wire.begin(OLED_SDA_PIN, OLED_SCL_PIN);
  detectedOledAddress = scanI2CAddress();

  Serial.printf("🖥️ Initializing SSD1306 OLED Display at Address 0x%02X...\n", detectedOledAddress);
  
  if (!display.begin(SSD1306_SWITCHCAPVCC, detectedOledAddress)) {
    Serial.println("⚠️ OLED Warning: Adafruit_SSD1306 allocation failed or screen not responding.");
    Serial.println("   Continuing system boot WITHOUT display screen...");
    oledInitialized = false;
    return;
  }

  oledInitialized = true;
  Serial.println("✅ OLED Display Initialized Successfully!");

  // Display NOVARA Startup Screen
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(20, 10);
  display.println(F("NOVARA FARM"));
  display.setCursor(5, 30);
  display.println(F("System Initializing"));
  display.setCursor(10, 48);
  display.printf("I2C Addr: 0x%02X", detectedOledAddress);
  display.display();
  delay(1500);
}

void updateOLEDDisplay() {
  if (!oledInitialized) return;

  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);

  // Header Banner
  display.setCursor(28, 0);
  display.println(F("NOVARA FARM"));
  display.drawLine(0, 10, 128, 10, SSD1306_WHITE);

  // Temperature
  display.setCursor(0, 16);
  if (dhtReadSuccess) {
    display.printf("Temp: %.1f C", currentTemp);
  } else {
    display.print("Temp: --.- C");
  }

  // Humidity
  display.setCursor(0, 28);
  if (dhtReadSuccess) {
    display.printf("Humidity: %.1f %%", currentHumidity);
  } else {
    display.print("Humidity: -- %%");
  }

  // Heat Lamp Output Status
  display.setCursor(0, 40);
  display.printf("Heat: %s", heatLampState ? "ON" : "OFF");

  // Water Level & Pump Status
  display.setCursor(0, 52);
  display.printf("Water: %s", waterDetected ? "OK" : "EMPTY");

  display.display();
}

// ---------------------------------------------------------------------------
// DHT Temperature & Regulation Logic
// ---------------------------------------------------------------------------
void readDHTAndRegulateTemperature() {
  // Read DHT sensor non-blockingly every 2000ms
  if (millis() - lastDhtReadTime < 2000 && lastDhtReadTime != 0) return;
  lastDhtReadTime = millis();

  float t = dht.readTemperature();
  float h = dht.readHumidity();

  if (isnan(t) || isnan(h)) {
    dhtReadSuccess = false;
    Serial.println("⚠️ DHT Sensor Error: Failed to read from DHT sensor on GPIO 16! Check wiring.");
    return;
  }

  currentTemp = t;
  currentHumidity = h;
  dhtReadSuccess = true;

  // Temperature Regulation Logic:
  // If temperature is strictly lower than LOW_TEMPERATURE_THRESHOLD -> Turn Heating ON
  // If temperature is within normal range (>= LOW_TEMPERATURE_THRESHOLD) -> Turn Heating OFF
  if (currentTemp < LOW_TEMPERATURE_THRESHOLD) {
    if (!heatLampState) {
      heatLampState = true;
      digitalWrite(HEAT_RELAY_PIN, HEATING_ACTIVE_STATE);
      Serial.printf("🔥 LOW TEMP DETECTED (%.1f°C < %.1f°C)! Heating output turned [ON]\n", 
                    currentTemp, LOW_TEMPERATURE_THRESHOLD);
    }
  } else {
    if (heatLampState) {
      heatLampState = false;
      digitalWrite(HEAT_RELAY_PIN, HEATING_INACTIVE_STATE);
      Serial.printf("❄️ NORMAL TEMP DETECTED (%.1f°C >= %.1f°C). Heating output turned [OFF]\n", 
                    currentTemp, LOW_TEMPERATURE_THRESHOLD);
    }
  }
}

// ---------------------------------------------------------------------------
// Servo Food Feeder Action
// ---------------------------------------------------------------------------
void dispenseFood(const char* triggerSource) {
  if (isDispensingFood) return;
  
  isDispensingFood = true;
  Serial.printf("🌾 Food Dispenser Triggered (%s)! Opening flap for %lu ms...\n", triggerSource, feedingDurationMs);
  
  feederServo.write(SERVO_OPEN_ANGLE);
  delay(feedingDurationMs);
  feederServo.write(SERVO_CLOSED_ANGLE);
  
  lastFeedTime = millis();
  totalFeedCycles++;
  isDispensingFood = false;
  Serial.println("🌾 Food Dispenser Closed.");
}

// ---------------------------------------------------------------------------
// Water Sensor Configuration & Logic
// ---------------------------------------------------------------------------
// Threshold for analog water depth sensor (0 - 4095 range on ESP32)
// Most sensors: Dry = ~0 to 300, Submerged = > 500 (set WATER_SENSOR_INVERTED to false)
// Digital/Inverted modules: Dry = > 2000, Submerged = < 500 (set WATER_SENSOR_INVERTED to true)
#define WATER_THRESHOLD 500
#define WATER_SENSOR_INVERTED true  // Inverted logic: sensor reads LOW/high when submerged so pump runs only when DRY

void checkWaterLevelAndActionPump() {
  int rawValue = analogRead(WATER_SENSOR_PIN);

  #if WATER_SENSOR_INVERTED
    waterDetected = (rawValue < WATER_THRESHOLD);
  #else
    waterDetected = (rawValue > WATER_THRESHOLD);
  #endif

  if (!waterDetected) {
    // NO WATER DETECTED -> TURN PUMP ON
    if (!pumpState) {
      pumpState = true;
      digitalWrite(PUMP_RELAY_PIN, RELAY_ON);
      Serial.printf("⚠️ NO WATER DETECTED (Raw ADC: %d)! Water Pump Relay activated [ON]\n", rawValue);
    }
  } else {
    // WATER DETECTED -> TURN PUMP OFF
    if (pumpState) {
      pumpState = false;
      digitalWrite(PUMP_RELAY_PIN, RELAY_OFF);
      Serial.printf("✅ WATER DETECTED IN TROUGH (Raw ADC: %d)! Water Pump Relay deactivated [OFF]\n", rawValue);
    }
  }
}

// ---------------------------------------------------------------------------
// Execute Inbound Cloud Commands from Railway
// ---------------------------------------------------------------------------
void executeCloudCommand(const char* action) {
  if (!action) return;
  Serial.printf("⚡ [Cloud Command Received from Railway] Action: %s\n", action);

  if (strcmp(action, "FEEDER_ON") == 0 || strcmp(action, "FEED") == 0) {
    dispenseFood("Railway Cloud Command");
  } else if (strcmp(action, "WATER_VALVE_ON") == 0 || strcmp(action, "PUMP_ON") == 0) {
    pumpState = true;
    digitalWrite(PUMP_RELAY_PIN, RELAY_ON);
    Serial.println("💧 [Action Executed] Water Pump Relay -> ON");
  } else if (strcmp(action, "WATER_VALVE_OFF") == 0 || strcmp(action, "PUMP_OFF") == 0) {
    pumpState = false;
    digitalWrite(PUMP_RELAY_PIN, RELAY_OFF);
    Serial.println("💧 [Action Executed] Water Pump Relay -> OFF");
  } else if (strcmp(action, "HEATER_ON") == 0 || strcmp(action, "HEAT_ON") == 0) {
    heatLampState = true;
    digitalWrite(HEAT_RELAY_PIN, HEATING_ACTIVE_STATE);
    Serial.println("🔥 [Action Executed] Heating Output -> ON");
  } else if (strcmp(action, "HEATER_OFF") == 0 || strcmp(action, "HEAT_OFF") == 0) {
    heatLampState = false;
    digitalWrite(HEAT_RELAY_PIN, HEATING_INACTIVE_STATE);
    Serial.println("🔥 [Action Executed] Heating Output -> OFF");
  } else {
    Serial.printf("⚠️ Unknown cloud command: %s\n", action);
  }
}

// ---------------------------------------------------------------------------
// Send Telemetry to Railway Backend & Receive Enqueued Commands
// ---------------------------------------------------------------------------
void sendTelemetryToBackend() {
  if (WiFi.status() != WL_CONNECTED || isPortalMode) return;

  WiFiClientSecure client;
  client.setInsecure(); // Bypass CA verification for Railway HTTPS

  HTTPClient http;
  if (!http.begin(client, BACKEND_TELEMETRY_URL)) {
    Serial.println("❌ Failed to initiate connection to Railway HTTPS");
    return;
  }
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<512> doc;
  doc["deviceId"] = "ESP32-POULTRY-01";
  doc["deviceSerial"] = "ESP32-POULTRY-01";
  doc["waterDetected"] = waterDetected;
  doc["waterLevel"] = waterDetected ? 100.0 : 0.0;
  doc["pumpActive"] = pumpState;
  doc["heatLampActive"] = heatLampState;
  doc["temperature"] = dhtReadSuccess ? currentTemp : 0.0;
  doc["humidity"] = dhtReadSuccess ? currentHumidity : 0.0;
  doc["lowTempThreshold"] = LOW_TEMPERATURE_THRESHOLD;
  doc["oledConnected"] = oledInitialized;
  doc["feedCyclesCount"] = totalFeedCycles;
  doc["feedingIntervalHours"] = feedingIntervalHours;
  doc["uptimeSeconds"] = millis() / 1000;

  String jsonString;
  serializeJson(doc, jsonString);

  int httpCode = http.POST(jsonString);
  if (httpCode > 0) {
    Serial.printf("📡 Telemetry sent to Railway. Status: %d\n", httpCode);
    if (httpCode == 200 || httpCode == 201) {
      String payload = http.getString();
      DynamicJsonDocument resDoc(1024);
      DeserializationError err = deserializeJson(resDoc, payload);
      if (!err && resDoc.containsKey("commands")) {
        JsonArray commands = resDoc["commands"].as<JsonArray>();
        for (JsonObject cmd : commands) {
          const char* action = cmd["action"];
          executeCloudCommand(action);
        }
      }
    }
  } else {
    Serial.printf("❌ Telemetry failed. Error: %s\n", http.errorToString(httpCode).c_str());
  }
  http.end();
}

// ---------------------------------------------------------------------------
// Fast Cloud Command Polling (Every 5 seconds for near-instant control)
// ---------------------------------------------------------------------------
void pollCloudCommands() {
  if (WiFi.status() != WL_CONNECTED || isPortalMode) return;

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  if (!http.begin(client, BACKEND_POLL_URL)) return;

  int httpCode = http.GET();
  if (httpCode == 200) {
    String payload = http.getString();
    DynamicJsonDocument doc(1024);
    DeserializationError err = deserializeJson(doc, payload);
    if (!err && doc.containsKey("commands")) {
      JsonArray commands = doc["commands"].as<JsonArray>();
      if (commands.size() > 0) {
        Serial.printf("📥 Fetched %d command(s) from Railway queue\n", commands.size());
        for (JsonObject cmd : commands) {
          const char* action = cmd["action"];
          executeCloudCommand(action);
        }
        // Report updated state to Railway immediately
        sendTelemetryToBackend();
      }
    }
  }
  http.end();
}

// ---------------------------------------------------------------------------
// Web API Endpoint Handlers
// ---------------------------------------------------------------------------
void handleStatusJSON() {
  unsigned long feedingIntervalMs = feedingIntervalHours * 3600UL * 1000UL;
  unsigned long elapsedMs = millis() - lastFeedTime;
  unsigned long remainingSec = (elapsedMs < feedingIntervalMs) ? ((feedingIntervalMs - elapsedMs) / 1000) : 0;

  StaticJsonDocument<512> doc;
  doc["waterDetected"] = waterDetected;
  doc["pumpActive"] = pumpState;
  doc["heatLampActive"] = heatLampState;
  doc["temperature"] = currentTemp;
  doc["humidity"] = currentHumidity;
  doc["dhtValid"] = dhtReadSuccess;
  doc["lowTempThreshold"] = LOW_TEMPERATURE_THRESHOLD;
  doc["oledConnected"] = oledInitialized;
  doc["isDispensingFood"] = isDispensingFood;
  doc["totalFeedCycles"] = totalFeedCycles;
  doc["feedingIntervalHours"] = feedingIntervalHours;
  doc["feedingDurationMs"] = feedingDurationMs;
  doc["nextFeedInSeconds"] = remainingSec;
  doc["uptime"] = millis() / 1000;

  String res;
  serializeJson(doc, res);
  server.send(200, "application/json", res);
}

void handleFeedNow() {
  dispenseFood("Web Request");
  server.send(200, "application/json", "{\"status\":\"success\",\"message\":\"Food dispensed\"}");
}

void handleFeedConfig() {
  bool updated = false;

  if (server.hasArg("hours")) {
    int h = server.arg("hours").toInt();
    if (h >= 1 && h <= 168) { // Between 1 hour and 168 hours (1 week)
      feedingIntervalHours = (unsigned long)h;
      updated = true;
    }
  }

  if (server.hasArg("duration")) {
    int d = server.arg("duration").toInt();
    if (d >= 1 && d <= 60) { // 1 to 60 seconds duration
      feedingDurationMs = (unsigned long)d * 1000;
      updated = true;
    }
  }

  if (updated) {
    preferences.begin("farm_config", false);
    preferences.putULong("feed_hours", feedingIntervalHours);
    preferences.putULong("feed_dur_ms", feedingDurationMs);
    preferences.end();
    lastFeedTime = millis(); // Reset interval timer so new period takes effect
    Serial.printf("⚙️ Farmer updated feeding schedule: every %lu hours for %lu ms\n", feedingIntervalHours, feedingDurationMs);
  }

  StaticJsonDocument<256> doc;
  doc["status"] = "success";
  doc["message"] = updated ? "Feeding period updated and saved" : "Current feeding configuration";
  doc["feedingIntervalHours"] = feedingIntervalHours;
  doc["feedingDurationMs"] = feedingDurationMs;
  doc["nextFeedInSeconds"] = feedingIntervalHours * 3600UL;

  String res;
  serializeJson(doc, res);
  server.send(200, "application/json", res);
}

void handleTogglePump() {
  pumpState = !pumpState;
  digitalWrite(PUMP_RELAY_PIN, pumpState ? RELAY_ON : RELAY_OFF);
  server.send(200, "application/json", "{\"pumpActive\":" + String(pumpState ? "true" : "false") + "}");
}

void handleToggleHeat() {
  heatLampState = !heatLampState;
  digitalWrite(HEAT_RELAY_PIN, heatLampState ? HEATING_ACTIVE_STATE : HEATING_INACTIVE_STATE);
  server.send(200, "application/json", "{\"heatLampActive\":" + String(heatLampState ? "true" : "false") + "}");
}

// ---------------------------------------------------------------------------
// Captive Portal Handlers
// ---------------------------------------------------------------------------
void handlePortalRoot() {
  String html = "<!DOCTYPE html><html><head><title>NOVARA Poultry Controller Setup</title>";
  html += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  html += "<style>body{font-family:Arial;background:#121212;color:#fff;text-align:center;padding:20px;}";
  html += ".card{background:#1e1e1e;max-width:400px;margin:0 auto;padding:25px;border-radius:10px;}";
  html += "input,select{width:100%;padding:10px;margin:10px 0;box-sizing:border-box;border-radius:5px;border:none;}";
  html += "input[type=submit]{background:#2196F3;color:white;font-weight:bold;cursor:pointer;}";
  html += "</style></head><body>";
  html += "<div class='card'><h2>🐓 NOVARA Poultry Controller Wi-Fi Setup</h2>";
  html += "<p>Configure Wi-Fi credentials for ESP32 Controller</p>";
  html += "<form action='/save' method='POST'>";
  
  int n = WiFi.scanNetworks();
  if (n == 0) {
    html += "<input type='text' name='ssid' placeholder='Wi-Fi SSID' required>";
  } else {
    html += "<select name='ssid'>";
    for (int i = 0; i < n; ++i) {
      html += "<option value='" + WiFi.SSID(i) + "'>" + WiFi.SSID(i) + " (" + String(WiFi.RSSI(i)) + " dBm)</option>";
    }
    html += "</select>";
  }
  
  html += "<input type='password' name='password' placeholder='Wi-Fi Password'><br>";
  html += "<input type='submit' value='Save & Reboot'>";
  html += "</form></div></body></html>";
  server.send(200, "text/html", html);
}

void handlePortalSave() {
  String ssid = server.arg("ssid");
  String password = server.arg("password");

  if (ssid.length() > 0) {
    preferences.begin("wifi_config", false);
    preferences.putString("ssid", ssid);
    preferences.putString("password", password);
    preferences.end();

    server.send(200, "text/html", "<h2>✅ Credentials Saved! Rebooting...</h2>");
    delay(2000);
    ESP.restart();
  } else {
    server.send(400, "text/plain", "Invalid SSID");
  }
}

void handleResetWiFi() {
  preferences.begin("wifi_config", false);
  preferences.clear();
  preferences.end();
  server.send(200, "text/plain", "Wi-Fi settings cleared. Rebooting into Portal Mode...");
  delay(1000);
  ESP.restart();
}

// ---------------------------------------------------------------------------
// Setup & Loop
// ---------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  delay(3000); // 3-second startup delay for Serial Monitor capture
  Serial.println("\n=== NOVARA BOOT START ===");
  Serial.println("=== NOVARA Smart Poultry Controller Starting ===");

  // Initialize GPIO Pins
  pinMode(WATER_SENSOR_PIN, INPUT);
  pinMode(PUMP_RELAY_PIN, OUTPUT);
  pinMode(HEAT_RELAY_PIN, OUTPUT);
  pinMode(RESET_WIFI_BUTTON, INPUT_PULLUP);

  // Set default relay/output states (OFF)
  digitalWrite(PUMP_RELAY_PIN, RELAY_OFF);
  digitalWrite(HEAT_RELAY_PIN, HEATING_INACTIVE_STATE);
  
  // Heating LED Hardware Blink Test on Boot (Blinks 3 times)
  Serial.println("💡 Testing Heating LED on GPIO 27...");
  for (int i = 0; i < 3; i++) {
    digitalWrite(HEAT_RELAY_PIN, HIGH);
    delay(300);
    digitalWrite(HEAT_RELAY_PIN, LOW);
    delay(300);
  }
  Serial.println("=== GPIO INITIALIZED & HEATING LED TESTED (GPIO 27) ===");

  // Initialize DHT Sensor
  dht.begin();
  Serial.println("=== DHT SENSOR INITIALIZED (GPIO 16) ===");

  // Initialize OLED Display (Includes I2C address scanner)
  initOLEDDisplay();

  // Attach Servo with standard 500us - 2400us pulse width
  ESP32PWM::allocateTimer(0);
  feederServo.setPeriodHertz(50);
  feederServo.attach(SERVO_FEEDER_PIN, 500, 2400);
  
  // Startup Servo Test Sweep (Opens briefly then closes)
  Serial.println("🌾 Testing Servo Flap Movement...");
  feederServo.write(SERVO_CLOSED_ANGLE);
  delay(300);
  feederServo.write(SERVO_OPEN_ANGLE);
  delay(800);
  feederServo.write(SERVO_CLOSED_ANGLE);
  Serial.println("=== SERVO INITIALIZED & TESTED (GPIO 18) ===");

  // Load Saved Wi-Fi
  preferences.begin("wifi_config", true);
  String saved_ssid = preferences.getString("ssid", "");
  String saved_pass = preferences.getString("password", "");
  preferences.end();

  // Load Saved Farm Feeding Parameters
  preferences.begin("farm_config", true);
  feedingIntervalHours = preferences.getULong("feed_hours", 6);
  feedingDurationMs = preferences.getULong("feed_dur_ms", 2000); // Default to 2000ms for testing
  preferences.end();
  Serial.printf("📋 Loaded Feeding Config: Every %lu hours (duration %lu ms)\n", feedingIntervalHours, feedingDurationMs);

  bool connected = false;
  if (saved_ssid.length() > 0) {
    Serial.print("Connecting to Wi-Fi: ");
    Serial.println(saved_ssid);
    WiFi.mode(WIFI_STA);
    WiFi.begin(saved_ssid.c_str(), saved_pass.c_str());

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
      delay(500);
      Serial.print(".");
      attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
      connected = true;
      Serial.println("\n✅ Wi-Fi Connected!");
      Serial.print("ESP32 Controller IP Address: ");
      Serial.println(WiFi.localIP());
    }
  }

  // Launch Captive Portal if Wi-Fi not connected
  if (!connected) {
    isPortalMode = true;
    Serial.println("\n⚠️ Launching Captive Portal Setup AP...");
    WiFi.mode(WIFI_AP);
    WiFi.softAP(AP_SSID);

    dnsServer.start(DNS_PORT, "*", WiFi.softAPIP());
    Serial.print("Connect to AP '");
    Serial.print(AP_SSID);
    Serial.print("' at http://");
    Serial.println(WiFi.softAPIP());

    server.on("/", handlePortalRoot);
    server.on("/save", HTTP_POST, handlePortalSave);
    server.onNotFound(handlePortalRoot);
  } else {
    // Main Control Handlers
    server.on("/api/status", handleStatusJSON);
    server.on("/api/feed", handleFeedNow);
    server.on("/api/feed/config", handleFeedConfig);
    server.on("/api/pump/toggle", handleTogglePump);
    server.on("/api/heat/toggle", handleToggleHeat);
    server.on("/reset-wifi", handleResetWiFi);
  }

  Serial.println("=== WIFI INITIALIZATION COMPLETE ===");
  Serial.println("=== STARTING WEB SERVER ===");
  server.begin();
  Serial.println("=== WEB SERVER STARTED ===");
  Serial.println("Web Control Server Ready.");
  lastFeedTime = millis();
}

void loop() {
  // 1. Read DHT sensor & regulate temperature (GPIO 16 -> GPIO 27)
  readDHTAndRegulateTemperature();

  // 2. Update OLED Display every 1000ms
  if (millis() - lastDisplayUpdateTime >= 1000) {
    lastDisplayUpdateTime = millis();
    updateOLEDDisplay();
  }

  // 3. Serial Monitor Diagnostics (every 3 seconds)
  if (millis() - lastSerialDebugTime >= 3000) {
    lastSerialDebugTime = millis();
    Serial.println("\n--- NOVARA FARM MONITOR ---");
    if (dhtReadSuccess) {
      Serial.printf("Temperature: %.1f C\n", currentTemp);
      Serial.printf("Humidity: %.1f %%\n", currentHumidity);
    } else {
      Serial.println("Temperature/Humidity: Sensor Read Error (Check GPIO 16)");
    }
    Serial.printf("Heating Output (GPIO 27): %s (Threshold: %.1f C)\n", 
                  heatLampState ? "ON (Too Cold)" : "OFF (Normal)", LOW_TEMPERATURE_THRESHOLD);
    Serial.printf("Water Level (GPIO 34): %s (Raw ADC: %d)\n", 
                  waterDetected ? "WATER DETECTED" : "NO WATER DETECTED", analogRead(WATER_SENSOR_PIN));
    Serial.printf("Pump State (GPIO 26): %s\n", pumpState ? "ON (Pumping)" : "OFF (Idle)");
    Serial.printf("Food Servo (GPIO 18): %s (Cycles: %d)\n", isDispensingFood ? "FEEDING" : "IDLE", totalFeedCycles);
    Serial.printf("OLED Display: %s (Addr: 0x%02X)\n", oledInitialized ? "ACTIVE" : "NOT INITIALIZED", detectedOledAddress);
    Serial.println("---------------------------");
  }

  // 4. Autonomous Water Management (Runs continuously online or offline)
  checkWaterLevelAndActionPump();

  // 5. Periodic Food Feeding Automation (Runs continuously every 5 seconds)
  unsigned long testingFeedingIntervalMs = 5000UL; // 5 seconds interval for testing
  if (millis() - lastFeedTime >= testingFeedingIntervalMs) {
    dispenseFood("5-Second Periodic Schedule");
  }

  // 6. Network Communication & Portal Handling
  if (isPortalMode) {
    dnsServer.processNextRequest();
  } else {
    // Periodic Command Polling (every 5 seconds)
    if (millis() - lastCommandPollTime >= 5000) {
      pollCloudCommands();
      lastCommandPollTime = millis();
    }

    // Periodic Telemetry POST (every 30 seconds)
    if (millis() - lastTelemetryTime >= 30000) {
      sendTelemetryToBackend();
      lastTelemetryTime = millis();
    }
  }

  server.handleClient();

  // Reset button check
  if (digitalRead(RESET_WIFI_BUTTON) == LOW) {
    delay(50);
    if (digitalRead(RESET_WIFI_BUTTON) == LOW) {
      handleResetWiFi();
    }
  }
}

