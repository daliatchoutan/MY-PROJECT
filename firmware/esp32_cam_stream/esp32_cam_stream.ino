/*
 * NOVARA Smart Poultry System - ESP32-CAM Video Streaming Server
 * 
 * Hardware: ESP32-CAM (AI-Thinker OV2640 Module)
 * 
 * Features:
 *  1. Captive Portal Wi-Fi Configuration Manager (Access Point: "ESP32CAM-Setup")
 *  2. High-speed MJPEG video streaming at http://<device-ip>/stream
 *  3. Snapshot endpoint at http://<device-ip>/snapshot
 *  4. Flash LED toggle (GPIO 4) for night vision / coop inspection.
 *  5. Periodic Telemetry POST reporting live stream URL to backend API.
 */

#include "esp_camera.h"
#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <Preferences.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "esp_timer.h"
#include "img_converters.h"
#include "fb_gfx.h"
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"

// ---------------------------------------------------------------------------
// Camera Hardware Pin Definition (AI-Thinker ESP32-CAM)
// ---------------------------------------------------------------------------
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27

#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

#define FLASH_LED_PIN      4   // On-board bright LED
#define RESET_WIFI_BUTTON 12   // GPIO 12 connected to GND to clear Wi-Fi settings

// ---------------------------------------------------------------------------
// Global Objects & Configuration
// ---------------------------------------------------------------------------
WebServer server(80);
DNSServer dnsServer;
Preferences preferences;

const byte DNS_PORT = 53;
const char* AP_SSID = "ESP32CAM-Setup";
const char* BACKEND_TELEMETRY_URL = "http://192.168.1.100:5000/api/sensors/telemetry"; // Express Backend

bool isPortalMode = false;
bool flashState = false;
unsigned long lastTelemetryTime = 0;

// ---------------------------------------------------------------------------
// MJPEG Stream Handler
// ---------------------------------------------------------------------------
#define PART_BOUNDARY "123456789000000000000987654321"
static const char* _STREAM_CONTENT_TYPE = "multipart/x-mixed-replace;boundary=" PART_BOUNDARY;
static const char* _STREAM_BOUNDARY = "\r\n--" PART_BOUNDARY "\r\n";
static const char* _STREAM_PART = "Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n";

void handleStream() {
  camera_fb_t * fb = NULL;
  esp_err_t res = ESP_OK;
  size_t _jpg_buf_len = 0;
  uint8_t * _jpg_buf = NULL;
  char part_buf[64];

  WiFiClient client = server.client();

  res = server.sendContent("");
  client.print("HTTP/1.1 200 OK\r\n");
  client.print(_STREAM_CONTENT_TYPE);
  client.print("\r\nAccess-Control-Allow-Origin: *\r\n\r\n");

  while (true) {
    if (!client.connected()) {
      break;
    }
    fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("Camera capture failed");
      res = ESP_FAIL;
    } else {
      if (fb->format != PIXFORMAT_JPEG) {
        bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
        esp_camera_fb_return(fb);
        fb = NULL;
        if (!jpeg_converted) {
          Serial.println("JPEG compression failed");
          res = ESP_FAIL;
        }
      } else {
        _jpg_buf_len = fb->len;
        _jpg_buf = fb->buf;
      }
    }
    if (res == ESP_OK) {
      size_t hlen = snprintf((char *)part_buf, 64, _STREAM_PART, _jpg_buf_len);
      client.write(_STREAM_BOUNDARY, strlen(_STREAM_BOUNDARY));
      client.write(part_buf, hlen);
      client.write((const char *)_jpg_buf, _jpg_buf_len);
    }
    if (fb) {
      esp_camera_fb_return(fb);
      fb = NULL;
      _jpg_buf = NULL;
    } else if (_jpg_buf) {
      free(_jpg_buf);
      _jpg_buf = NULL;
    }
    if (res != ESP_OK) {
      break;
    }
    taskYIELD();
  }
}

// ---------------------------------------------------------------------------
// Single Snapshot Handler
// ---------------------------------------------------------------------------
void handleSnapshot() {
  camera_fb_t * fb = esp_camera_fb_get();
  if (!fb) {
    server.send(500, "text/plain", "Camera capture failed");
    return;
  }
  
  WiFiClient client = server.client();
  client.print("HTTP/1.1 200 OK\r\n");
  client.print("Content-Type: image/jpeg\r\n");
  client.print("Content-Disposition: inline; filename=snapshot.jpg\r\n");
  client.print("Access-Control-Allow-Origin: *\r\n");
  client.print("Content-Length: " + String(fb->len) + "\r\n\r\n");
  client.write(fb->buf, fb->len);
  
  esp_camera_fb_return(fb);
}

// ---------------------------------------------------------------------------
// Flash Light Toggle Handler
// ---------------------------------------------------------------------------
void handleFlashToggle() {
  flashState = !flashState;
  digitalWrite(FLASH_LED_PIN, flashState ? HIGH : LOW);
  server.send(200, "application/json", "{\"flash\":" + String(flashState ? "true" : "false") + "}");
}

// ---------------------------------------------------------------------------
// Root Page Handler
// ---------------------------------------------------------------------------
void handleRoot() {
  String html = "<!DOCTYPE html><html><head><title>NOVARA ESP32-CAM</title>";
  html += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  html += "<style>body{font-family:Arial,sans-serif;background:#0d1117;color:#c9d1d9;text-align:center;padding:20px;}";
  html += ".container{max-width:600px;margin:0 auto;background:#161b22;padding:20px;border-radius:12px;border:1px solid #30363d;}";
  html += "img{width:100%;border-radius:8px;border:2px solid #238636;}";
  html += "button{background:#238636;color:white;border:none;padding:12px 24px;margin:10px;font-size:16px;border-radius:6px;cursor:pointer;}";
  html += "button:hover{background:#2ea043;}</style></head><body>";
  html += "<div class='container'>";
  html += "<h2>🐓 NOVARA ESP32-CAM Live Stream</h2>";
  html += "<img src='/stream' alt='Live Video Stream'>";
  html += "<br><br>";
  html += "<button onclick=\"fetch('/flash').then(r=>r.json()).then(d=>alert('Flash LED: ' + d.flash))\">💡 Toggle Flash LED</button>";
  html += "<button onclick=\"window.location.href='/snapshot'\">📸 Take Snapshot</button>";
  html += "<button style='background:#da3633;' onclick=\"if(confirm('Clear Wi-Fi and reboot?')) fetch('/reset-wifi').then(()=>location.reload())\">⚙️ Reset Wi-Fi</button>";
  html += "</div></body></html>";
  server.send(200, "text/html", html);
}

// ---------------------------------------------------------------------------
// Captive Portal HTML & Handlers
// ---------------------------------------------------------------------------
void handlePortalRoot() {
  String html = "<!DOCTYPE html><html><head><title>ESP32-CAM Wi-Fi Setup</title>";
  html += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  html += "<style>body{font-family:Arial;background:#121212;color:#fff;text-align:center;padding:20px;}";
  html += ".card{background:#1e1e1e;max-width:400px;margin:0 auto;padding:25px;border-radius:10px;}";
  html += "input,select{width:100%;padding:10px;margin:10px 0;box-sizing:border-box;border-radius:5px;border:none;}";
  html += "input[type=submit]{background:#4CAF50;color:white;font-weight:bold;cursor:pointer;}";
  html += "</style></head><body>";
  html += "<div class='card'><h2>🐓 ESP32-CAM Wi-Fi Setup</h2>";
  html += "<p>Select your farm Wi-Fi network and enter the password.</p>";
  html += "<form action='/save' method='POST'>";
  html += "<label>SSID:</label><br>";
  
  int n = WiFi.scanNetworks();
  if (n == 0) {
    html += "<input type='text' name='ssid' placeholder='Wi-Fi Network Name' required>";
  } else {
    html += "<select name='ssid'>";
    for (int i = 0; i < n; ++i) {
      html += "<option value='" + WiFi.SSID(i) + "'>" + WiFi.SSID(i) + " (" + String(WiFi.RSSI(i)) + " dBm)</option>";
    }
    html += "</select>";
  }
  
  html += "<label>Password:</label><br><input type='password' name='password' placeholder='Wi-Fi Password'><br>";
  html += "<input type='submit' value='Connect & Save'>";
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

    String html = "<html><body style='background:#121212;color:white;text-align:center;font-family:Arial;padding:50px;'>";
    html += "<h2>✅ Wi-Fi Credentials Saved!</h2>";
    html += "<p>ESP32-CAM is restarting and connecting to <b>" + ssid + "</b>...</p>";
    html += "</body></html>";
    server.send(200, "text/html", html);

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
// Send Camera IP Telemetry to Express Backend API
// ---------------------------------------------------------------------------
void sendCameraTelemetryToBackend() {
  if (WiFi.status() != WL_CONNECTED || isPortalMode) return;

  HTTPClient http;
  http.begin(BACKEND_TELEMETRY_URL);
  http.addHeader("Content-Type", "application/json");

  String streamUrl = "http://" + WiFi.localIP().toString() + "/stream";

  StaticJsonDocument<256> doc;
  doc["deviceSerial"] = "ESP32-CAM-01";
  doc["type"] = "ESP32-CAM";
  doc["streamUrl"] = streamUrl;
  doc["ipAddress"] = WiFi.localIP().toString();
  doc["flashState"] = flashState;

  String jsonString;
  serializeJson(doc, jsonString);

  int httpCode = http.POST(jsonString);
  if (httpCode > 0) {
    Serial.printf("📡 ESP32-CAM Telemetry sent. Status: %d\n", httpCode);
  }
  http.end();
}

// ---------------------------------------------------------------------------
// Camera Setup Initialization
// ---------------------------------------------------------------------------
bool initCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  
  if (psramFound()) {
    config.frame_size = FRAMESIZE_VGA;
    config.jpeg_quality = 10;
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_QVGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x\n", err);
    return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Arduino Setup & Loop
// ---------------------------------------------------------------------------
void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0); // Disable brownout detector for stability
  
  Serial.begin(115200);
  Serial.println("\n--- NOVARA ESP32-CAM Stream Server Starting ---");

  pinMode(FLASH_LED_PIN, OUTPUT);
  digitalWrite(FLASH_LED_PIN, LOW);
  pinMode(RESET_WIFI_BUTTON, INPUT_PULLUP);

  if (!initCamera()) {
    Serial.println("FATAL: Camera hardware failure!");
  }

  // Load saved Wi-Fi credentials
  preferences.begin("wifi_config", true);
  String saved_ssid = preferences.getString("ssid", "");
  String saved_pass = preferences.getString("password", "");
  preferences.end();

  bool connected = false;
  if (saved_ssid.length() > 0) {
    Serial.print("Connecting to saved Wi-Fi: ");
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
      Serial.print("Stream URL: http://");
      Serial.print(WiFi.localIP());
      Serial.println("/stream");
    }
  }

  // Launch Captive Portal if not connected
  if (!connected) {
    isPortalMode = true;
    Serial.println("\n⚠️ Launching Captive Portal Access Point...");
    WiFi.mode(WIFI_AP);
    WiFi.softAP(AP_SSID);
    
    dnsServer.start(DNS_PORT, "*", WiFi.softAPIP());
    Serial.print("Connect phone to AP '");
    Serial.print(AP_SSID);
    Serial.print("' and visit http://");
    Serial.println(WiFi.softAPIP());

    server.on("/", handlePortalRoot);
    server.on("/save", HTTP_POST, handlePortalSave);
    server.onNotFound(handlePortalRoot);
  } else {
    // Normal Operating Mode handlers
    server.on("/", handleRoot);
    server.on("/stream", handleStream);
    server.on("/snapshot", handleSnapshot);
    server.on("/flash", handleFlashToggle);
    server.on("/reset-wifi", handleResetWiFi);

    sendCameraTelemetryToBackend();
  }

  server.begin();
  Serial.println("HTTP Web Server Started.");
}

void loop() {
  if (isPortalMode) {
    dnsServer.processNextRequest();
  } else {
    // Send IP telemetry heartbeat every 30 seconds
    if (millis() - lastTelemetryTime >= 30000) {
      sendCameraTelemetryToBackend();
      lastTelemetryTime = millis();
    }
  }
  server.handleClient();

  // Check hardware reset button
  if (digitalRead(RESET_WIFI_BUTTON) == LOW) {
    delay(50);
    if (digitalRead(RESET_WIFI_BUTTON) == LOW) {
      Serial.println("Wi-Fi Reset button pressed. Clearing credentials...");
      handleResetWiFi();
    }
  }
}
