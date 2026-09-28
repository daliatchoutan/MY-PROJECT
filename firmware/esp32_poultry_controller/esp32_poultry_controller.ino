/*
 * NOVARA Smart Poultry System - ESP32 Main Controller Firmware
 * 
 * Hardware: Standard ESP32 Dev Board (WROOM-32 / 38-Pin)
 * Actuators & Sensors:
 *  1. Water Level Sensor (GPIO 34) -> Triggers Water Pump Relay 1 (GPIO 26) when NO water is detected.
 *  2. Food Dispenser Servo Motor (GPIO 18) -> Periodically opens flap to feed chickens.
 *  3. Heating Lamp Relay 2 (GPIO 27) -> Controls warming bulb for chicks.
 *  4. Captive Portal Wi-Fi Configuration Manager (Access Point: "NOVARA-Poultry-Setup").
 *  5. REST API telemetry reporting to Express backend server.
 */

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <Preferences.h>
#include <ESP32Servo.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// ---------------------------------------------------------------------------
// Hardware GPIO Pin Configurations
// ---------------------------------------------------------------------------
#define WATER_SENSOR_PIN   34  // Input: Water detection sensor (Digital/Analog)
#define PUMP_RELAY_PIN     26  // Output: Relay 1 for Water Pump
#define SERVO_FEEDER_PIN   18  // Output PWM: Servo Motor for Food Supply
#define HEAT_RELAY_PIN     27  // Output: Relay 2 for Heating Bulb
#define RESET_WIFI_BUTTON   4  // Input Pullup: Wi-Fi Reset Button

// ---------------------------------------------------------------------------
// Relay Logic Macros (Change logic level if using Active HIGH relay)
// ---------------------------------------------------------------------------
#define RELAY_ON   LOW
#define RELAY_OFF  HIGH

// ---------------------------------------------------------------------------
// System Parameters & Intervals (Railway Cloud Production Endpoints)
// ---------------------------------------------------------------------------
const char* BACKEND_TELEMETRY_URL = "https://my-project-production-f607.up.railway.app/api/sensors/telemetry";
const char* BACKEND_POLL_URL      = "https://my-project-production-f607.up.railway.app/api/sensors/commands/pending?deviceSerial=ESP32-POULTRY-01";

// Configurable feeding parameters (persisted in NVS Preferences)
unsigned long feedingIntervalHours = 6;  // Feed interval (in hours, default 6 hours)
unsigned long feedingDurationMs = 5000; // Flap open duration (in ms, default 5000ms)

const int SERVO_CLOSED_ANGLE = 0;   // Flap closed
const int SERVO_OPEN_ANGLE   = 90;  // Flap open

// ---------------------------------------------------------------------------
// Global Variables & Objects
// ---------------------------------------------------------------------------
WebServer server(80);
DNSServer dnsServer;
Preferences preferences;
Servo feederServo;

const byte DNS_PORT = 53;
const char* AP_SSID = "NOVARA-Poultry-Setup";

bool isPortalMode = false;
bool waterDetected = false;
bool pumpState = false;
bool heatLampState = false;
bool isDispensingFood = false;

unsigned long lastFeedTime = 0;
unsigned long lastTelemetryTime = 0;
unsigned long lastCommandPollTime = 0;
int totalFeedCycles = 0;

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
// Water Management & Sensor Logic
// ---------------------------------------------------------------------------
void checkWaterLevelAndActionPump() {
  int rawValue = analogRead(WATER_SENSOR_PIN);
  // Sensor reading logic: HIGH or rawValue > 1000 indicates water present
  waterDetected = (rawValue > 1000);

  if (!waterDetected) {
    // NO WATER -> ACTION PUMP
    if (!pumpState) {
      pumpState = true;
      digitalWrite(PUMP_RELAY_PIN, RELAY_ON);
      Serial.println("⚠️ NO WATER DETECTED! Actioning Water Pump Relay 1 [ON]");
    }
  } else {
    // WATER PRESENT -> STOP PUMP
    if (pumpState) {
      pumpState = false;
      digitalWrite(PUMP_RELAY_PIN, RELAY_OFF);
      Serial.println("✅ Water detected in trough. Water Pump Relay 1 [OFF]");
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
    digitalWrite(HEAT_RELAY_PIN, RELAY_ON);
    Serial.println("🔥 [Action Executed] Heating Lamp Relay -> ON");
  } else if (strcmp(action, "HEATER_OFF") == 0 || strcmp(action, "HEAT_OFF") == 0) {
    heatLampState = false;
    digitalWrite(HEAT_RELAY_PIN, RELAY_OFF);
    Serial.println("🔥 [Action Executed] Heating Lamp Relay -> OFF");
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

  StaticJsonDocument<384> doc;
  doc["deviceId"] = "ESP32-POULTRY-01";
  doc["deviceSerial"] = "ESP32-POULTRY-01";
  doc["waterDetected"] = waterDetected;
  doc["waterLevel"] = waterDetected ? 100.0 : 0.0;
  doc["pumpActive"] = pumpState;
  doc["heatLampActive"] = heatLampState;
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

  StaticJsonDocument<384> doc;
  doc["waterDetected"] = waterDetected;
  doc["pumpActive"] = pumpState;
  doc["heatLampActive"] = heatLampState;
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

void handleFeedNow() {
  dispenseFood("Web Request");
  server.send(200, "application/json", "{\"status\":\"success\",\"message\":\"Food dispensed\"}");
}

void handleTogglePump() {
  pumpState = !pumpState;
  digitalWrite(PUMP_RELAY_PIN, pumpState ? RELAY_ON : RELAY_OFF);
  server.send(200, "application/json", "{\"pumpActive\":" + String(pumpState ? "true" : "false") + "}");
}

void handleToggleHeat() {
  heatLampState = !heatLampState;
  digitalWrite(HEAT_RELAY_PIN, heatLampState ? RELAY_ON : RELAY_OFF);
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
  Serial.println("\n=== NOVARA Smart Poultry Controller Starting ===");

  // Initialize GPIO Pins
  pinMode(WATER_SENSOR_PIN, INPUT);
  pinMode(PUMP_RELAY_PIN, OUTPUT);
  pinMode(HEAT_RELAY_PIN, OUTPUT);
  pinMode(RESET_WIFI_BUTTON, INPUT_PULLUP);

  // Set default relay states (OFF)
  digitalWrite(PUMP_RELAY_PIN, RELAY_OFF);
  digitalWrite(HEAT_RELAY_PIN, RELAY_OFF);

  // Attach Servo
  feederServo.attach(SERVO_FEEDER_PIN);
  feederServo.write(SERVO_CLOSED_ANGLE);

  // Load Saved Wi-Fi
  preferences.begin("wifi_config", true);
  String saved_ssid = preferences.getString("ssid", "");
  String saved_pass = preferences.getString("password", "");
  preferences.end();

  // Load Saved Farm Feeding Parameters
  preferences.begin("farm_config", true);
  feedingIntervalHours = preferences.getULong("feed_hours", 6);
  feedingDurationMs = preferences.getULong("feed_dur_ms", 5000);
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

  server.begin();
  Serial.println("Web Control Server Ready.");
  lastFeedTime = millis();
}

void loop() {
  if (isPortalMode) {
    dnsServer.processNextRequest();
  } else {
    // 1. Monitor water sensor & trigger pump automatically
    checkWaterLevelAndActionPump();

    // 2. Periodic Food Feeding Automation based on farmer configured period
    unsigned long feedingIntervalMs = feedingIntervalHours * 3600UL * 1000UL;
    if (millis() - lastFeedTime >= feedingIntervalMs) {
      dispenseFood("Scheduled Interval Timer");
    }

    // 3. Periodic Command Polling (every 5 seconds for fast cloud response)
    if (millis() - lastCommandPollTime >= 5000) {
      pollCloudCommands();
      lastCommandPollTime = millis();
    }

    // 4. Periodic Telemetry POST (every 30 seconds)
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
