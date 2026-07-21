# SmartKash Mobile App

This folder contains the Flutter app for SmartKash.

SmartKash mobile is a cross-platform Flutter app, with Android as the main local testing target on the current Windows development machine.

## Main Features

- Firebase test OTP login
- Profile completion and PIN setup
- Home dashboard with wallet balance
- Add Money
- Send Money by number, contacts, and QR
- Cash Out through agent
- Merchant Payment
- Pay Bill
- Mobile Recharge
- Savings goals and deposit
- Loan request
- Inbox transaction history and details
- My QR and QR scanner
- Account/profile editing
- Merchant and agent account creation

## Folder Structure

```text
lib/app/              App shell, router, theme, config
lib/core/             API client, storage, errors, utilities
lib/features/         Feature-first modules
lib/shared/           Shared widgets, models, services
android/              Android platform project
ios/                  iOS platform project
web/                  Web platform project
windows/              Windows desktop project
linux/                Linux desktop project
macos/                macOS desktop project
test/                 Flutter tests
```

## Important Config

Backend base URL is controlled by Dart define:

```text
SMARTKASH_API_BASE_URL
```

Firebase app values can be passed with Dart defines, or read from the configured Firebase setup in the app.

Do not commit private Firebase Admin service account JSON files.

## Run On Android Emulator

Start backend first:

```bat
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Run Flutter with emulator backend URL:

```bat
cd /d D:\github\my-kash\apps\mobile
flutter run --dart-define SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

## Run On Real Android Phone

Start backend first:

```bat
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Connect phone with USB debugging enabled, then run:

```bat
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" devices
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080
```

Then:

```bat
cd /d D:\github\my-kash\apps\mobile
flutter run
```

## Common Real Phone Issues

### Cannot Reach Backend

Check:

- Backend is running
- `curl http://localhost:8080/actuator/health` returns `UP`
- USB debugging is enabled
- ADB sees the device
- `adb reverse tcp:8080 tcp:8080` succeeds

### APK Install Blocked

On some Xiaomi/MIUI phones:

- Enable Developer Options
- Enable USB debugging
- Enable Install via USB
- Keep phone unlocked during install

## Manual Verification Commands

```bat
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

## Notes

- Android is the primary local test platform.
- Web can be tested locally if the current Firebase/backend flow supports it.
- iOS/macOS builds require macOS and Xcode.
- Windows desktop builds require Visual Studio Desktop development with C++ workload.
- Linux builds require a Linux environment.
