# NOVARA Smart Poultry System - Firmware & ESP32-CAM Stream Dashboard

This folder contains the complete firmware sketches for the **NOVARA Smart Poultry System** microcontrollers and a web dashboard to visualize the live ESP32-CAM video stream and monitor/control farm actuators.

---

## 🚀 Key Features

1. **Captive Portal Wi-Fi Configuration**:
   - No hardcoded Wi-Fi passwords! When powered on for the first time or if disconnected, the ESP32 creates its own Wi-Fi Access Point (`NOVARA-Poultry-Setup` or `ESP32CAM-Setup`).
   - Connecting your phone or laptop opens a captive web page (`http://192.168.4.1`) where you scan local Wi-Fi networks, enter your password, and save.
   - Credentials are stored securely in ESP32 non-volatile memory (NVS/Preferences).

2. **Water Distribution System**:
   - Continuous water level monitoring using a water sensor (digital/analog).
   - **Automated Pump Control**: If no water is detected (`sensor == LOW`), Relay 1 is activated automatically to turn ON the water pump until the tank/trough is full.

3. **Scheduled & Manual Food Feeder**:
   - Servo Motor controls the feeder flap.
   - Automatically dispenses food at periodic intervals (e.g., opens for 5 seconds every 6 hours).
   - Manual feed command trigger available via button press or web command.

4. **Heating Lamp System**:
   - Relay 2 controls a high-wattage heat lamp/bulb to warm young chicks and keep the coop at optimal temperatures.

5. **ESP32-CAM Live Wi-Fi Video Stream**:
   - High-speed MJPEG video streaming server powered by the OV2640 camera sensor.
   - Accessible via standard web browser or embedded directly in the included web dashboard.

---

## 🔌 Pinout & Hardware Wiring Diagram

### Option A: Standard ESP32 Controller (`esp32_poultry_controller.ino`)
Recommended setup using a standard ESP32-WROOM / ESP32-38Pin development board for sensor & actuator management.

| Component | Pin Function | ESP32 GPIO Pin | Wire / Module Connection |
| :--- | :--- | :--- | :--- |
| **Water Level Sensor** | Signal Out | `GPIO 34` | Sensor OUT Pin (Analog / Digital) |
| | VCC / GND | 3.3V / GND | Power Pins |
| **Water Pump Relay (Relay 1)** | Signal Control | `GPIO 26` | Relay Module IN1 Pin |
| | VCC / GND | 5V / GND | Relay Power (Use external 5V/12V for pump power) |
| **Food Supply Servo Motor** | PWM Signal | `GPIO 18` | Servo Yellow/Orange Signal Wire |
| | VCC / GND | 5V / GND | Servo Red (5V) & Brown/Black (GND) |
| **Heating Lamp Relay (Relay 2)**| Signal Control | `GPIO 27` | Relay Module IN2 Pin |
| | VCC / GND | 5V / GND | Relay Power (Controls 220V/110V AC Lamp Circuit) |
| **Wi-Fi Reset Button** | Tactile Switch | `GPIO 4` | Connected to GND (Pulls LOW to reset Wi-Fi) |

---

### Option B: ESP32-CAM Module (`esp32_cam_stream.ino`)
AI-Thinker ESP32-CAM module dedicated to Wi-Fi video streaming.

| ESP32-CAM Pin | Connected To | Description |
| :--- | :--- | :--- |
| **5V & GND** | 5V 2A Power Supply | Stable external power required for camera streaming |
| **GPIO 4** | On-Board Flash LED | Flashlight / Night Vision illumination |
| **GPIO 0** | GND (During Flashing) | Connect to GND when uploading code, disconnect for normal boot |
| **U0R & U0T** | FTDI TX & RX | FTDI USB-to-Serial adapter connection |

---

### Option C: All-in-One ESP32-CAM (`esp32_all_in_one.ino`)
If running both camera streaming and actuators on a single ESP32-CAM board:

| Component | ESP32-CAM GPIO Pin | Notes |
| :--- | :--- | :--- |
| **Water Sensor** | `GPIO 13` | Input pin (pull-down) |
| **Water Pump Relay (Relay 1)**| `GPIO 12` | Output pin (Boot caution: keep HIGH during boot if needed) |
| **Food Supply Servo** | `GPIO 14` | PWM output pin |
| **Heating Lamp Relay (Relay 2)**| `GPIO 15` | Output pin |

---

## 🛠️ Software Requirements & Arduino IDE Setup

1. Install [Arduino IDE](https://www.arduino.cc/en/software) (version 2.0+ recommended).
2. Add ESP32 Board Manager URL in Arduino IDE preferences:
   `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
3. Install **ESP32** by Espressif Systems in Board Manager.
4. Install required Arduino Libraries from Library Manager:
   - `ESP32Servo` (by Kevin Harrington) - for servo motor control.
   - `ArduinoJson` (by Benoit Blanchon) - for telemetry reporting.
   - `WiFiManager` (by tzapu) - for captive portal Wi-Fi configuration.

---

## 📲 How to Configure Wi-Fi via Captive Portal

1. Power ON the ESP32 / ESP32-CAM board.
2. Open Wi-Fi settings on your phone or computer.
3. Connect to the network:
   - For Controller: **`NOVARA-Poultry-Setup`**
   - For ESP32-CAM: **`ESP32CAM-Setup`**
4. The **Captive Configuration Portal** web page will automatically pop up (or visit `http://192.168.4.1` in browser).
5. Click **Configure WiFi**.
6. Select your farm/home Wi-Fi SSID from the list, enter the password, and click **Save**.
7. The ESP32 will reboot, connect to your network, and display its IP address on the Arduino Serial Monitor (115200 baud).

> **To Reset Saved Wi-Fi**: Hold down the Wi-Fi Reset button (GPIO 4 connected to GND) for 3 seconds while powering on, or click "Reset Wi-Fi" from the local web interface.

---

## 💻 Web Stream & Control Dashboard (`web_stream_dashboard.html`)

Double-click `web_stream_dashboard.html` to open it in any modern browser (Chrome, Firefox, Edge, Safari).

### Features:
- **Live Video Stream Player**: Enter the IP address of your ESP32-CAM (e.g. `http://192.168.1.120:81/stream` or `http://192.168.1.120/stream`) to view real-time HD video feed.
- **Snapshot Capture**: Take instant snapshots of the poultry video feed.
- **Water Pump & Level Monitor**: View live water sensor status and manual pump trigger.
- **Feeder Control**: Trigger manual food dispensing and configure periodic schedule.
- **Heating Control**: Toggle chicken warming bulb ON/OFF.
