# SmartKash

SmartKash is a zero-budget learning MVP for a mobile banking and wallet app. It is built with a Flutter cross-platform app, a Spring Boot backend, PostgreSQL, Firebase Phone Auth test OTP, JWT security, wallet balance tracking, immutable ledger entries, and transaction history.

This project is for learning and local demonstration only. It is not a licensed financial service and does not move real money.

## Current Status

The project now has working foundations for:

- Firebase test OTP login and backend JWT authentication
- User registration/profile completion with profile image support
- Wallet balance, immutable ledger entries, and transaction records
- Add Money with instant wallet credit
- Send Money by mobile number, contacts, and QR
- Cash Out through agent account and QR
- Merchant Payment through merchant account and QR
- Pay Bill
- Mobile Recharge
- Savings goals and savings deposit
- Loan request/status flow
- Inbox transaction history and transaction details
- Profile/account management
- Agent and merchant account creation from the app
- Flutter Android real-phone development with local Spring Boot backend

## Important MVP Boundaries

- No real bank API
- No real payment gateway
- No real recharge provider
- No real KYC provider
- No real SMS OTP billing flow
- No real money movement
- Firebase Phone Auth should use test phone numbers and fixed OTP codes

## Charges

Current wallet charge rules:

- Send Money: `Tk 2` charge per `Tk 1000`
- Cash Out: `Tk 13` charge per `Tk 1000`

For these flows, the sender/customer wallet is debited by:

```text
amount + charge
```

The receiver, agent, or merchant receives only the main transaction amount.

## Tech Stack

### Mobile

- Flutter cross-platform app
- Android, iOS, Web, Windows, Linux, macOS project structure
- Android is the main local test target on Windows
- Riverpod for state management
- go_router for routing
- Firebase Core/Auth foundation
- QR scanning
- Contact number selection

### Backend

- Java 21
- Spring Boot
- Spring Web
- Spring Security
- Spring Data JPA and Hibernate
- PostgreSQL
- Flyway migrations
- Firebase Admin SDK
- JWT authentication
- Bean Validation
- Actuator
- OpenAPI/Swagger dependencies

### Database

- PostgreSQL
- Flyway-managed migrations
- Wallet balance stored for fast reads
- Ledger entries are immutable
- Corrections should use reversal ledger entries
- Money-changing operations use transactions, idempotency, and wallet locking

## Project Structure

```text
apps/mobile/          Flutter app
services/backend/     Spring Boot backend
docs/                 Planning and workflow docs
learning/             Bangla learning notes from earlier steps
scripts/              Development helper scripts
```

## Local Setup

### 1. Backend Environment

Use `.env.example` as the reference. Do not commit real secrets.

Required local values include:

```text
DATABASE_URL=jdbc:postgresql://localhost:5432/smartkash_db
DATABASE_USERNAME=smartkash_admin
DATABASE_PASSWORD=<your-local-password>
JWT_SECRET=<at-least-32-byte-secret>
JWT_EXPIRATION_MINUTES=60
FIREBASE_PROJECT_ID=<firebase-project-id>
FIREBASE_CLIENT_EMAIL=<firebase-service-account-email>
FIREBASE_PRIVATE_KEY=<firebase-private-key>
SPRING_PROFILES_ACTIVE=local
SERVER_PORT=8080
```

### 2. Run Backend

```bat
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Check health:

```bat
curl http://localhost:8080/actuator/health
```

Expected:

```json
{"status":"UP"}
```

### 3. Real Android Phone Setup

If testing on a real Android phone over USB, keep backend running and use ADB reverse:

```bat
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" devices
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080
```

Then run Flutter:

```bat
cd /d D:\github\my-kash\apps\mobile
flutter run
```

The app can use:

```text
http://127.0.0.1:8080
```

because ADB reverse maps phone port `8080` to the PC backend.

### 4. Android Emulator Setup

For emulator testing, use:

```text
http://10.0.2.2:8080
```

Example:

```bat
cd /d D:\github\my-kash\apps\mobile
flutter run --dart-define SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

## Manual Verification

Backend:

```bat
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Flutter:

```bat
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

## Useful Test Flow

1. Start PostgreSQL.
2. Start Spring Boot backend.
3. Connect real phone and run ADB reverse, or use emulator URL.
4. Run Flutter app.
5. Login/register with Firebase test OTP.
6. Complete profile and set PIN.
7. Add Money.
8. Test Send Money, Cash Out, Payment, Pay Bill, Recharge, Savings, and Loan.
9. Open Inbox and confirm transaction history/details.

## GitHub

Repository:

```text
https://github.com/masud-rana-pro/mobile-banking-app.git
```

Before starting new work:

```bat
git status
git pull
```

After focused changes:

```bat
git status
git add <files>
git commit -m "short meaningful message"
git push
```
