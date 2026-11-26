# 💊 ECHO — Smart Medication Reminder & IoT Pill Dispenser

**ECHO** is an integrated healthcare solution combining a **Flutter mobile application** with an **ESP32-powered automated pill dispenser**. It helps patients manage their medication schedules reliably through real-time cloud synchronization, smart alerts, and automated mechanical dispensing.

---

## ✨ Key Features

### 📱 Mobile Application (Flutter)
* **Smart Medication Scheduling:** Set custom medication reminders with flexible daily schedules and meal-based timing.
* **Seamless Machine Pairing:** Link the physical dispenser to the user's account in seconds using a 6-digit pairing code.
* **Real-Time Dose Tracking:** Monitor dispensed doses and intake confirmation logs synced via Firebase Realtime Database.
* **Secure Authentication:** User account management and password recovery powered by Firebase Auth & EmailJS OTP.

### ⚙️ Automated Hardware Dispenser (ESP32)
* **Precision Dispensing:** Automated compartment rotation driven by a **28BYJ-48 stepper motor (ULN2003 driver)** with limit-switch homing calibration.
* **Multi-Sensory Alerts:** Synchronized active buzzer and vibration motor alerts that automatically stop once the **IR obstacle sensor** detects the medication strip has been taken.
* **Offline Resilience:** Caches alarm schedules locally in flash memory and maintains accurate timekeeping via a **DS3231 RTC** module even without Wi-Fi.
* **Easy Wi-Fi Provisioning:** Captive portal setup (`ECHO-Setup`) via `WiFiManager` for effortless network configuration.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter & Dart
* **Backend & Cloud:** Firebase (Authentication, Realtime Database)
* **Embedded Firmware:** C++ (Arduino Framework for ESP32-WROOM-32)
* **Hardware Components:** ESP32, 28BYJ-48 Stepper + ULN2003, DS3231 RTC, 16x2 I2C LCD, IR Sensor, Limit Switch, Active Buzzer, Vibration Motor

---

## 🚀 Getting Started

### Mobile App
1. Clone the repository:
   ```bash
   git clone [https://github.com/shahdabubakr/MedicationTracker.git](https://github.com/shahdabubakr/MedicationTracker.git)
