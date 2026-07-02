# SmartKash Flutter App

SmartKash is a Flutter full cross-platform learning MVP app shell.

Supported platform folders:

- `android/`
- `ios/`
- `web/`
- `windows/`
- `linux/`
- `macos/`

Android remains the primary local testing target on the current Windows machine. Web can also be tested locally on Windows. Windows desktop builds require Visual Studio Desktop development with C++ workload. iOS and macOS builds require macOS with Xcode. Linux builds require a Linux environment.

The shared app code lives in `lib/` and keeps the existing Riverpod, go_router, Firebase foundation, and feature-first structure.
