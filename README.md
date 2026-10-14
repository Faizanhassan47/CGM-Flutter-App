# Aima CGM Flutter app

This app combines the Aima patient UI, the official Chinese vendor CGM SDK v4, and the Node/Nest backend.

## Run backend (PowerShell window 1)

```powershell
cd "D:\Code\CGM\New app with node backend\Backend_NestJS"
npm install
npm run start:dev
```

## Run Flutter on a USB Android phone (PowerShell window 2)

Enable USB debugging, connect the phone, then run:

```powershell
cd "D:\Code\CGM\Old Backend\Floter new app"
adb reverse tcp:5000 tcp:5000
& & "D:\Code\CGM\.tools\flutter\bin\flutter.bat" pub get
& "D:\Code\CGM\.tools\flutter\bin\flutter.bat" run --dart-define=CGM_API_BASE_URL=http://127.0.0.1:5000/


For the Android emulator, omit `adb reverse` and use the default `http://10.0.2.2:5000/`:

```powershell
& "D:\Code\CGM\.tools\flutter\bin\flutter.bat" run
```

## Build APK

```powershell
cd "D:\Code\CGM\Old Backend\Floter new app"
& "D:\Code\CGM\.tools\flutter\bin\flutter.bat" build apk --debug
```

Output: `build\app\outputs\flutter-apk\app-debug.apk`

BLE activation requires a real Android/iOS phone, Bluetooth, camera permission, and a valid vendor sensor QR code. It cannot be validated using an emulator alone.
