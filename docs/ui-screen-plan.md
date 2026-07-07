# SmartKash UI Screen Plan

## Flutter Architecture

Use Riverpod for state management and a feature-first folder structure.

SmartKash is planned as a Flutter full cross-platform app for Android, iOS, Web, Windows, Linux, and macOS. Android remains the primary local testing target on Windows, and Web can also be tested locally on Windows. Windows desktop builds require Visual Studio Desktop development with C++ workload. iOS/macOS builds require macOS with Xcode. Linux builds require a Linux environment.

Suggested structure:

```text
android/
ios/
web/
windows/
linux/
macos/
lib/main.dart
lib/app/
lib/app/router/
lib/app/theme/
lib/app/config/
lib/core/
lib/core/constants/
lib/core/errors/
lib/core/network/
lib/core/storage/
lib/core/security/
lib/core/utils/
lib/features/
lib/features/auth/
lib/features/home/
lib/features/wallet/
lib/features/add_money/
lib/features/send_money/
lib/features/payment/
lib/features/transactions/
lib/features/savings/
lib/features/loan/
lib/features/recharge/
lib/features/notification/
lib/features/profile/
lib/features/qr/
lib/shared/
lib/shared/widgets/
lib/shared/models/
lib/shared/services/
```

Each feature should use this structure when needed:

```text
data/
domain/
presentation/
providers/
```

Example:

```text
features/send_money/data/
features/send_money/domain/
features/send_money/presentation/
features/send_money/providers/
```

## Flutter User App

- Splash screen
- Firebase test OTP mobile login screen
- PIN setup screen
- PIN verification screen
- Home dashboard
- Wallet balance view
- Add Money request screen
- Add Money request status screen
- Send Money by mobile number screen
- QR scan Send Money screen
- Send Money confirmation screen
- Merchant Payment screen
- Statement and transaction filter screen
- Transaction receipt screen
- Savings goal list screen
- Savings goal create screen
- Savings deposit screen
- Loan request screen
- Loan status screen
- Mobile Recharge screen
- Profile screen
- FCM notification list or alert view

## Minimal Spring Web Admin

- Admin login screen
- Users list
- Transactions list
- Add Money requests list
- Add Money approval/rejection action
- Loan requests list
- Loan approval/rejection action
- Recharges list
- Payments list
- Audit logs list

## UI Rules

- Customer and merchant users must not access admin screens.
- Admin screens must require authenticated `ADMIN` role.
- Send Money UI must keep both mobile number and QR receiver selection.
- Money-changing confirmation screens must request PIN.
- Receipts should show transaction reference, amount, type, status, date/time, sender or receiver, and notes where applicable.
- Use Riverpod for state management.
- Keep UI widgets clean.
- API calls must stay in repository/service classes, not inside widgets.
- Use DTO/model classes for API payloads.
- Use secure storage for JWT and sensitive tokens.
- Do not store PIN in the Flutter app.
- PIN should be sent only for transaction confirmation over secure API.
- Use a centralized API client.
- Use centralized error handling.
- Use clear route management.
- Use reusable widgets for buttons, input fields, loading states, error states, and transaction cards.
- Keep Firebase Auth logic separated from UI screens.
- Keep QR scan logic inside a dedicated QR feature/module.
- Use the user's provided mobile banking screenshots as reference for layout, spacing, hierarchy, and interaction flow.
- Use original SmartKash visual identity with a different standard color theme from the reference screenshots.
- Do not copy bKash branding, exact colors, logo, or promotional artwork.
- Ask the user for more screen-specific reference images before designing future screens when needed.
- If bitmap assets are needed and cannot be generated directly, request the asset from the user with recommended dimensions and content guidance.
