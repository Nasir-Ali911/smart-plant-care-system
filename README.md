# 🌱 Smart Plant Care System with AI-Based Monitoring and Mobile App

A smart IoT-based plant monitoring and care system developed as a Final Year Project (FYP) for the Virtual University of Pakistan.

The system combines **IoT sensors, esp8622, Firebase, Flutter, and AI-based monitoring concepts** to help users monitor plant environmental conditions and manage plant information through a mobile application.

---

## 📌 Project Overview

The **Smart Plant Care System** is designed to provide real-time monitoring of important plant-growth parameters such as:

* 🌡️ Temperature
* 💧 Soil moisture
* 💦 Humidity
* ☀️ Light intensity

Sensor readings are transmitted through an IoT device and synchronized with **Firebase Realtime Database**, allowing the Flutter mobile application to display current environmental conditions.

The application also provides plant management features, including adding plants, editing plant information, uploading plant images, and viewing plant details.

---

## 🎯 Project Objectives

The main objectives of the project are:

* Develop an IoT-based plant monitoring system.
* Monitor soil moisture and environmental conditions in real time.
* Provide plant information through an Android mobile application.
* Synchronize IoT sensor data with Firebase.
* Provide a user-friendly interface for plant management.
* Establish a foundation for AI-based plant monitoring and intelligent recommendations.
* Integrate agriculture and computer science technologies into a practical smart agriculture solution.

---

## ✨ Key Features

### 📱 Mobile Application

* User registration and login
* Dashboard
* Plant management
* Add new plants
* Edit plant information
* Delete plants
* Plant profile and details
* Plant image upload
* Live environmental monitoring
* Firebase-based data synchronization

### 🌱 Plant Monitoring

The system monitors:

| Parameter       | Sensor                          |
| --------------- | ------------------------------- |
| Soil Moisture   | Capacitive Soil Moisture Sensor |
| Temperature     | DHT22                           |
| Humidity        | DHT22                           |
| Light Intensity | LDR                             |

### ☁️ Cloud Integration

* Firebase Authentication
* Firebase Realtime Database
* Cloud-based sensor data synchronization
* Cloudinary-based plant image storage

---

## 🔧 Hardware Components

The prototype uses the following hardware components:

* ESP8622 Development Board
* Capacitive Soil Moisture Sensor v1.2
* DHT22 Temperature & Humidity Sensor
* LDR Module
* Breadboard
* Jumper Wires
* USB Cable

Additional hardware such as a relay and water pump can be integrated in future development phases.

---

## 💻 Software & Technologies

### Mobile Application

* Flutter
* Dart
* Android

### Backend / Cloud

* Firebase Authentication
* Firebase Realtime Database
* Cloudinary

### IoT

* ESP8622
* Arduino IDE
* C/C++

### Development Tools

* Visual Studio Code
* Git
* GitHub

---

## 🏗️ System Architecture

```text
             ┌─────────────────────┐
             │     Plant / Soil    │
             └──────────┬──────────┘
                        │
                        ▼
        ┌────────────────────────────┐
        │       IoT Sensors          │
        │                            │
        │ Soil Moisture │ DHT22 │ LDR│
        └───────────────┬────────────┘
                        │
                        ▼
                ┌──────────────┐
                │     esp8622    │
                └──────┬───────┘
                       │ Wi-Fi
                       ▼
              ┌──────────────────┐
              │ Firebase Realtime│
              │    Database      │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │ Flutter Android  │
              │   Mobile App     │
              └──────────────────┘
```

---

## 📱 Mobile Application Modules

The Flutter application contains the following major screens/modules:

* Splash Screen
* Login Screen
* Registration Screen
* Dashboard
* My Plants
* Add Plant
* Edit Plant
* Plant Details
* Live Monitoring
* User Profile

---

## 🌐 Firebase Data Flow

The ESP8622 collects sensor readings from the connected sensors and sends the data through Wi-Fi to Firebase Realtime Database.

The Flutter application retrieves the stored data and presents it to the user through the Live Monitoring interface.

```text
Sensors
   ↓
esp8622
   ↓
Wi-Fi
   ↓
Firebase Realtime Database
   ↓
Flutter Mobile Application
   ↓
User
```

---

## 📂 Project Structure

```text
smart-plant-care-system/
│
├── android/
│
├── arduino/
│   └── smart_plant_care/
│
├── lib/
│   ├── screens/
│   ├── models/
│   ├── services/
│   └── widgets/
│
├── assets/
│
├── .github/
│   └── workflows/
│
├── firebase.json
├── pubspec.yaml
├── README.md
└── .gitignore
```

---

## 🚀 Installation

### Prerequisites

Install:

* Flutter SDK
* Dart SDK
* Android Studio or Visual Studio Code
* Arduino IDE
* Git

### Clone the Repository

```bash
git clone https://github.com/Nasir-Ali911/smart-plant-care-system.git
cd smart-plant-care-system
```

### Install Flutter Dependencies

```bash
flutter pub get
```

### Run the Application

```bash
flutter run
```

For Android release testing:

```bash
flutter run --release
```

---

## 🔌 Arduino / ESP8622 Setup

1. Open the Arduino project located in:

```text
arduino/smart_plant_care/
```

2. Configure the esp8622 board in Arduino IDE.
3. Connect the required sensors.
4. Configure Wi-Fi credentials locally.
5. Upload the firmware to the esp8622.
6. Open the Serial Monitor to verify sensor readings.
7. Verify that readings are synchronized with Firebase.

**Important:** Actual Wi-Fi passwords, Firebase credentials, API keys, and other secrets should not be committed to this repository.

---

## 📦 Prototype APK

A release APK has been generated and tested on a physical Android phone.

The application package is:

```text
smart_plant_care.apk
```

The APK provides the Android implementation of the Smart Plant Care System prototype.

---

## 📸 Screenshots

Screenshots of the following interfaces can be added here:

* Login / Registration
* Dashboard
* My Plants
* Add Plant
* Plant Details
* Live Monitoring
* Firebase sensor data
* Hardware prototype
* ESP8622 and sensor connections

Example:

```text
screenshots/
├── login.png
├── dashboard.png
├── plants.png
├── plant_details.png
├── live_monitoring.png
└── hardware.png
```

---

## 🔮 Future Enhancements

Future versions of the system may include:

* AI-based plant disease detection
* Camera-based disease identification
* Automated irrigation using relay and water pump
* AI-generated plant-care recommendations
* Weather API integration
* Plant disease prediction
* Notification and alert system
* Advanced historical sensor analytics

---

## 📊 Project Status

### Prototype Phase

**Status: Completed / Functional Prototype**

The current prototype includes:

* ✅ Flutter mobile application
* ✅ Android APK
* ✅ Firebase integration
* ✅ ESP8622 IoT module
* ✅ Soil moisture monitoring
* ✅ Temperature monitoring
* ✅ Humidity monitoring
* ✅ Light intensity monitoring
* ✅ Plant management
* ✅ Plant image upload
* ✅ Live monitoring interface
* ✅ GitHub source-code repository

Further development and refinement will continue during the final deliverable phase.

---

## 🎓 Academic Project

**Project:** Smart Plant Care System with AI-Based Monitoring and Mobile App

**Degree:** BS Computer Science

**Institution:** Virtual University of Pakistan

**Project Type:** Final Year Project (FYP)
**Project Supervisor:** Waqar Ahmad

---

## 👨‍💻 Author

**Nasir Ali**

BS Computer Science
Virtual University of Pakistan

---

## 📄 License

This project was developed for academic and educational purposes as part of a Final Year Project.
