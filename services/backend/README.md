# SmartKash Backend

This folder contains the Spring Boot backend for SmartKash.

The backend provides authentication, user/profile management, wallet operations, transaction records, immutable ledger entries, QR-supported transfers, admin reads/actions, notifications, and database persistence through PostgreSQL.

## Tech Stack

- Java 21
- Maven Wrapper
- Spring Boot
- Spring Web
- Spring Security
- Spring Data JPA and Hibernate
- PostgreSQL Driver
- Flyway
- Firebase Admin SDK
- JWT
- Bean Validation
- Actuator
- OpenAPI/Swagger dependencies

## Root Package

```text
com.smartkash
```

## Main API Areas

```text
POST /api/auth/firebase-login
POST /api/auth/set-pin
POST /api/auth/verify-pin

GET  /api/users/me
GET  /api/users/resolve
POST /api/users/me/profile-image
GET  /api/users/profile-images/{imageId}

GET  /api/wallet/me

POST /api/add-money/requests
GET  /api/add-money/requests

POST /api/send-money/resolve-receiver
POST /api/send-money

POST /api/cash-out
GET  /api/agents/resolve
POST /api/agents/me
GET  /api/agents/me

GET  /api/payments/merchant/resolve
POST /api/payments/merchant
POST /api/merchants/me
GET  /api/merchants/me

POST /api/pay-bill

POST /api/recharge
GET  /api/recharge

POST /api/savings/goals
GET  /api/savings/goals
POST /api/savings/goals/{goalId}/deposit

POST /api/loans/requests
GET  /api/loans/requests

GET  /api/transactions
GET  /api/transactions/{id}

POST /api/devices/fcm-token

GET  /admin/users
GET  /admin/transactions
GET  /admin/add-money/requests
GET  /admin/loans/requests
POST /admin/loans/requests/{id}/approve
POST /admin/loans/requests/{id}/reject
GET  /admin/recharges
GET  /admin/payments
GET  /admin/audit-logs
```

## Environment Variables

Use the root `.env.example` as a template.

Required local values:

```text
DATABASE_URL=jdbc:postgresql://localhost:5432/smartkash_db
DATABASE_USERNAME=smartkash_admin
DATABASE_PASSWORD=<your-local-password>
SPRING_PROFILES_ACTIVE=local
JWT_SECRET=<at-least-32-byte-secret>
JWT_EXPIRATION_MINUTES=60
FIREBASE_PROJECT_ID=<firebase-project-id>
FIREBASE_CLIENT_EMAIL=<firebase-service-account-email>
FIREBASE_PRIVATE_KEY=<firebase-private-key>
FCM_ENABLED=false
SERVER_PORT=8080
```

Never hardcode secrets in `application.yml`, `application-local.yml`, or source code.

## Run Locally

```bat
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Health check:

```bat
curl http://localhost:8080/actuator/health
```

Expected:

```json
{"status":"UP"}
```

## Manual Verification

```bat
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

## Database

The backend uses PostgreSQL and Flyway.

Local database used during development:

```text
Database: smartkash_db
User: smartkash_admin
Host: localhost
Port: 5432
```

Check tables:

```bat
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\dt
SELECT * FROM flyway_schema_history;
```

## Money And Ledger Rules

- Wallet balance is stored for fast reads.
- Every balance change must create ledger entries.
- Ledger entries must not be updated or deleted.
- Corrections should use reversal ledger entries.
- Money-changing APIs must use idempotency keys.
- Wallet balance updates must happen inside database transactions.
- PIN verification happens only in backend.

## Current Charge Rules

- Send Money: `Tk 2` per `Tk 1000`
- Cash Out: `Tk 13` per `Tk 1000`

Sender/customer wallet debit:

```text
amount + charge
```

Receiver/agent wallet credit:

```text
amount
```

## Firebase Admin

Firebase Admin SDK verifies Firebase ID tokens during backend login.

The service account JSON must stay outside Git. Use environment variables for:

```text
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY
```

## Security Notes

- JWT secret must be at least 32 bytes.
- Raw PIN must never be stored.
- PIN must be hashed.
- Money-changing APIs require authenticated user and PIN confirmation.
- Admin APIs require ADMIN role.
