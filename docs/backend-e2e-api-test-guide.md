# SmartKash Backend E2E API Test Guide

This guide is for local development only. It helps you seed demo data and manually verify the backend API outputs.

Do not use this seed data in production. SmartKash is a zero-budget learning MVP and does not move real money.

## Step 1: Run Backend Verification

From CMD or PowerShell:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
.\mvnw.cmd spring-boot:run
```

Expected output:

- Tests pass.
- Package build passes.
- Backend starts on `http://localhost:8080`.
- Actuator health should be available at `http://localhost:8080/actuator/health`.

## Step 2: Generate A BCrypt PIN Hash

The seed script needs a BCrypt hash for test PIN `12345`. The raw PIN is never stored in the database.

Use any local BCrypt generator you trust, or run a small local command/tool that generates a BCrypt hash for:

```text
12345
```

Expected hash shape:

```text
$2a$10$...
```

or:

```text
$2b$10$...
```

Keep this hash local. It is demo test data only.

## Step 3: Seed Local E2E Data

From the repo root:

```powershell
cd /d D:\github\my-kash
$pinHash = '<PASTE_BCRYPT_HASH_FOR_PIN_12345>'
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db -v seed_pin_hash="'$pinHash'" -f scripts/dev/seed-e2e-data.sql
```

Expected output:

- The script finishes without SQL errors.
- The final result table shows seed row counts.
- Main seed tables should show at least 15 rows.
- `users`, `user_profiles`, and `wallets` show more than 15 rows because the seed includes one admin, 15 customers, and 15 merchants.

Expected count shape:

```text
table_name          | seed_rows
--------------------+----------
add_money_requests  | 15
admin_audit_logs    | 15
firebase_devices    | 15
idempotency_keys    | 15
ledger_entries      | 15
loan_requests       | 15
merchants           | 15
mobile_recharges    | 15
savings_goals       | 15
transactions        | 15
user_profiles       | 31
users               | 31
wallets             | 31
```

## Step 4: Database Count Verification

Open psql:

```powershell
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
```

Run:

```sql
SELECT COUNT(*) FROM users WHERE firebase_uid LIKE 'seed-%';
SELECT COUNT(*) FROM user_profiles;
SELECT COUNT(*) FROM wallets;
SELECT COUNT(*) FROM merchants WHERE merchant_number LIKE 'MERCH-%';
SELECT COUNT(*) FROM transactions WHERE transaction_reference LIKE 'SEED-TXN-%';
SELECT COUNT(*) FROM ledger_entries WHERE transaction_reference LIKE 'SEED-TXN-%';
SELECT COUNT(*) FROM idempotency_keys WHERE idempotency_key LIKE 'seed-idempotency-%';
SELECT COUNT(*) FROM add_money_requests WHERE note LIKE 'seed-add-money-%';
SELECT COUNT(*) FROM loan_requests WHERE purpose LIKE 'Seed loan purpose %';
SELECT COUNT(*) FROM mobile_recharges WHERE mobile_number LIKE '+88019%';
SELECT COUNT(*) FROM savings_goals WHERE name LIKE 'Seed Savings Goal %';
SELECT COUNT(*) FROM firebase_devices WHERE fcm_token LIKE 'seed-fcm-token-%';
SELECT COUNT(*) FROM admin_audit_logs WHERE details LIKE 'Seed admin audit log %';
```

Expected output:

- `users`: `31`
- `user_profiles`: at least `31`
- `wallets`: at least `31`
- every other seed query: `15`

## Step 5: Basic Public API Checks

Health check:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/actuator/health
```

Expected output:

- HTTP status `200`
- body contains `"status":"UP"`

Swagger UI:

```text
http://localhost:8080/swagger-ui/index.html
```

Expected output:

- Swagger UI opens in browser.
- SmartKash API endpoints are visible.

## Step 6: Auth Error Output Checks

Protected API without JWT:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/api/wallet/me
```

Expected output:

- HTTP status `401`
- JSON body `message`: `Authentication is required.`

Protected API with wrong JWT:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/api/wallet/me -Headers @{ Authorization = "Bearer wrong-token" }
```

Expected output:

- HTTP status `401`
- JSON body `message`: `Invalid or expired backend JWT.`

## Step 7: Authenticated API Checks

To test authenticated APIs, you still need a valid backend JWT.

Normal flow:

1. Use Firebase Phone Auth test OTP in Flutter or API testing setup.
2. Send Firebase ID token to:

```http
POST /api/auth/firebase-login
```

3. Copy `accessToken` from the backend response.
4. Use it as:

```text
Authorization: Bearer <accessToken>
```

Expected authenticated read outputs:

- `GET /api/users/me`: returns your persisted user record.
- `GET /api/wallet/me`: returns your wallet balance.
- `GET /api/transactions`: returns only your transaction records.

Important: seeded users use fake Firebase UIDs, so you cannot log in as a seeded user unless your Firebase token subject matches that seeded UID. For API testing, use your real Firebase test login user, then use seeded database rows mainly for admin list/read endpoints and database verification.

## Step 8: Admin API Checks

Admin APIs require a real backend JWT whose persisted user row has:

```sql
role = 'ADMIN'
```

For local testing only, after you log in with Firebase and the backend creates your user, you may promote your own local user:

```sql
UPDATE users
SET role = 'ADMIN', updated_at = CURRENT_TIMESTAMP
WHERE mobile_number = '<YOUR_FIREBASE_TEST_PHONE_NUMBER>';
```

Then log in again to get a new backend JWT with `ADMIN` role.

Admin endpoints to verify:

```text
GET /admin/users
GET /admin/transactions
GET /admin/add-money/requests
GET /admin/loans/requests
GET /admin/recharges
GET /admin/payments
GET /admin/audit-logs
```

Expected output:

- HTTP status `200`
- JSON array response
- seeded rows should appear in list endpoints where matching data exists

If a customer JWT calls admin APIs:

- HTTP status `403`
- JSON body message: `You do not have permission to access this resource.`

## Step 9: Money Flow Manual API Outputs

These APIs require:

- valid backend JWT
- user has PIN set
- active wallet
- enough wallet balance
- unique `idempotencyKey`

Use PIN:

```text
12345
```

if you are testing against users seeded with the matching BCrypt hash.

Expected money API success outputs:

- Send Money: response includes transaction reference, sender/receiver wallet balances, amount, and status.
- Merchant Payment: response includes payment transaction reference, merchant number, amount, and status.
- Savings Deposit: response includes transaction reference, goal ID, deposited amount, and updated goal amount.
- Mobile Recharge: response includes recharge ID, transaction reference, operator, mobile number, amount, and status.
- Add Money Approval: response includes request status, wallet credit transaction reference, amount, and audit-backed approval data.

Expected duplicate idempotency output:

- Same request with same `idempotencyKey` should return the saved response or reject mismatched retry.
- It must not create a duplicate wallet balance change.

## Step 10: Ledger Consistency Checks

After money-changing APIs:

```sql
SELECT transaction_reference, type, status, amount
FROM transactions
ORDER BY id DESC
LIMIT 20;

SELECT transaction_reference, entry_type, amount, balance_after
FROM ledger_entries
ORDER BY id DESC
LIMIT 20;
```

Expected output:

- each money movement creates transaction rows
- wallet-changing operations create ledger entries
- wallet-to-wallet transfers have debit/credit entries linked by transaction reference

## Step 11: FCM Alert Behavior

If local `.env` or `application-local.yml` has:

```text
FCM_ENABLED=false
```

Expected output:

- money-changing APIs still succeed
- backend skips notification delivery safely

If FCM is enabled and Firebase Admin is configured:

- registered FCM device tokens can receive important transaction alerts
- local delivery may still be limited until deployment/device setup is complete

## Step 12: Cleanup Seed Data

Seed data is for local testing. If you want to remove it later, ask Codex to create a safe cleanup script.

Do not manually delete production-like data unless you understand foreign key order. The seed script itself does not delete anything.
