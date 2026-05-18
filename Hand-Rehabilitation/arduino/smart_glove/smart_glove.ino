/*
 * Smart Assistive Glove - PRO VERSION (ULTRA-STABLE DATA FLOW)
 * Includes: OLED Display, Auto-Calibration, 5-Finger Haptics, and Two-Way App Control
 */

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <SoftwareSerial.h>

// ================= PIN DEFINITIONS =================
SoftwareSerial btSerial(2, 3); // RX (D2), TX (D3)

int flexPins[5] = {A0, A1, A2, A3, A6};
int forcePin    = A7; 
int vibPins[5]  = {11, 10, 9, 6, 5}; // Thumb, Index, Middle, Ring, Pinky

// ================= CONFIG & THRESHOLDS =================
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

int flexON[5]  = {40, 40, 40, 40, 40};
int flexOFF[5] = {15, 15, 15, 15, 15};
const int FORCE_THRESHOLD = 50; 

// ================= VARIABLES =================
int flexBase[5];
bool vibState[5] = {false, false, false, false, false};
const char* fingerName[5] = {"Thumb", "Index", "Middle", "Ring", "Pinky"};
bool oledActive = false;

unsigned long lastSendTime = 0;
const int SEND_INTERVAL = 100; // 10Hz transmission for real-time smoothness
unsigned long lastDisplayTime = 0;
#define DISPLAY_INTERVAL 200 

// Command Buffer
const byte numChars = 32;
char receivedChars[numChars];
bool newData = false;

void setup() {
  Serial.begin(115200);  
  
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("OLED fail (check 0x3C/0x3D)"));
    oledActive = false;
  } else {
    Serial.println(F("OLED Initialized"));
    oledActive = true;
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(WHITE);
    display.setCursor(0, 0);
    display.println(F("NERVELINK GLOVE"));
    display.println(F("v2.0 STABLE"));
    display.println(F(""));
    display.println(F("CALIBRATING..."));
    display.println(F("Keep hand FLAT"));
    display.display();
  }

  for (int i = 0; i < 5; i++) {
    pinMode(vibPins[i], OUTPUT);
    digitalWrite(vibPins[i], LOW);
  }

  delay(3000); 
  captureBaseline();

  if (oledActive) {
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println(F("SYSTEM ACTIVE"));
    display.display();
  }

  // Initialize Bluetooth at the very end
  btSerial.begin(9600);
}

void loop() {
  int forceVal = analogRead(forcePin);
  bool forceActive = (forceVal > FORCE_THRESHOLD); 
  
  // 1. Handle incoming commands from App (Two-way communication)
  recvWithStartEndMarkers();
  if (newData) {
    handleVibrationCommand(receivedChars);
    newData = false;
  }

  // 2. Process Sensors & Haptics
  for (int i = 0; i < 5; i++) {
    int flexVal = analogRead(flexPins[i]);
    int delta = abs(flexVal - flexBase[i]);
    
    if (forceActive) {
        digitalWrite(vibPins[i], HIGH);
        vibState[i] = true; 
    } 
    else {
        if (!vibState[i] && delta >= flexON[i]) {
            vibState[i] = true;
            digitalWrite(vibPins[i], HIGH);
        }
        else if (vibState[i] && delta <= flexOFF[i]) {
            vibState[i] = false;
            digitalWrite(vibPins[i], LOW); 
        }
    }
  }

  // 3. PERFECT DATA FLOW: Efficient CSV Transmission
  if (millis() - lastSendTime >= SEND_INTERVAL) {
    String dataString = "";
    for (int i = 0; i < 5; i++) {
      int flexVal = analogRead(flexPins[i]);
      int delta = abs(flexVal - flexBase[i]);
      int angle = constrain(map(delta, 0, 150, 0, 90), 0, 90);
      
      btSerial.print(angle);
      btSerial.print(",");
      
      dataString += String(angle) + ",";
    }
    btSerial.println(forceVal); // Final value + Newline Frame
    
    // Also print to USB Serial for debugging
    Serial.print(F("USB Debug: "));
    Serial.print(dataString);
    Serial.println(forceVal);
    
    lastSendTime = millis();
  }

  // 4. Update OLED Display
  if (millis() - lastDisplayTime >= DISPLAY_INTERVAL) {
    updateOLED(forceActive);
    lastDisplayTime = millis();
  }
}

void captureBaseline() {
  for (int i = 0; i < 5; i++) {
    flexBase[i] = analogRead(flexPins[i]);
  }
}

void recvWithStartEndMarkers() {
    static bool recvInProgress = false;
    static byte ndx = 0;
    char startMarker = '<';
    char endMarker = '>';
    char rc;

    while (btSerial.available() > 0 && newData == false) {
        rc = btSerial.read();
        if (recvInProgress == true) {
            if (rc != endMarker) {
                receivedChars[ndx] = rc;
                ndx++;
                if (ndx >= numChars) ndx = numChars - 1;
            } else {
                receivedChars[ndx] = '\0';
                recvInProgress = false;
                ndx = 0;
                newData = true;
            }
        } else if (rc == startMarker) {
            recvInProgress = true;
        }
    }
}

void handleVibrationCommand(char* cmd) {
    String input = String(cmd);
    if (!input.startsWith("VIB:")) return;
    String params = input.substring(4);
    int sep = params.indexOf(',');
    if (sep == -1) return;
    String target = params.substring(0, sep);
    int state = params.substring(sep + 1).toInt();

    if (target == "ALL") {
        for (int i = 0; i < 5; i++) {
            digitalWrite(vibPins[i], state ? HIGH : LOW);
            vibState[i] = (state != 0);
        }
    } else {
        int idx = target.toInt() - 1;
        if (idx >= 0 && idx < 5) {
            digitalWrite(vibPins[idx], state ? HIGH : LOW);
            vibState[idx] = (state != 0);
        }
    }
}

void updateOLED(bool p) {
    if (!oledActive) return;
    display.clearDisplay();
    display.setCursor(0, 0);
    display.setTextSize(1);
    display.println(F("--- GLOVE STATUS ---"));
    
    for (int i = 0; i < 5; i++) {
        int flexVal = analogRead(flexPins[i]);
        int delta = abs(flexVal - flexBase[i]);
        int angle = constrain(map(delta, 0, 150, 0, 90), 0, 90);
        
        display.print(fingerName[i]);
        display.print(F(": "));
        display.print(angle);
        display.print(F("d "));
        display.println(vibState[i] ? F("ON") : F("OFF"));
    }
    
    display.drawLine(0, 50, 128, 50, WHITE);
    display.setCursor(0, 54);
    display.print(F("PRESSURE: "));
    display.print(analogRead(forcePin));
    display.print(p ? " (ACT)" : " (---)");
    display.display();
}
