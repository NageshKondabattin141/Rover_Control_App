# Rover Control App

A Flutter app to control a rover using **Bluetooth Classic (HC-05 / HC-06)**.  
You can connect to your rover and control it with directional buttons (Forward, Backward, Left, Right).

---

## Features

- Connect to paired Bluetooth devices via a popup list
- Forward, Backward, Left, Right controls
- Shows connected device name dynamically
- Null-safe and works with Dart 3+ and Flutter 3+
- Easy to extend for sensors (metal detector, camera feed, etc.)

---

## Folder Structure


rover_control_app/
├─ lib/
│ ├─ main.dart # App entry point
│ ├─ rover_remote.dart # Rover control screen with Bluetooth
├─ pubspec.yaml # Dependencies
├─ .gitignore # Ignore build/temp files
├─ README.md # This file
└─ assets/ # Optional images/icons


---

## Prerequisites

- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android device with Bluetooth
- Rover with HC-05 / HC-06 module (paired)

---

## Installation & Run

1. Clone the repo:

```bash
git clone https://github.com/<your-username>/rover_control_app.git
cd rover_control_app

Install dependencies:

flutter pub get

Enable Bluetooth on your phone and turn on your rover module.

Run the app:

flutter run
How to Use

Tap Connect Bluetooth.

Select your rover from the popup list.

Use directional buttons to move the rover:

Up → Forward

Down → Backward

Left → Turn Left

Right → Turn Right

Release buttons to stop. The app shows connection status dynamically.

Dependencies
dependencies:
  flutter:
    sdk: flutter
  flutter_bluetooth_classic_serial: ^1.3.2
  google_fonts: ^3.0.1
Tips

Pair your rover module with your phone before running the app.

Ensure HC-05/06 module is powered and set to default baud rate 9600.

You can add sensors by reading values via Bluetooth and updating the UI.

Contribution

Fork the repo, make changes, and submit a pull request.

License

MIT License – free to use, modify, and share.