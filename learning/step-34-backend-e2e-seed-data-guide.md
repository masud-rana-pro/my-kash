# Step 34: Backend E2E Seed Data And API Verification Guide

## 1. Step title

এই ধাপের নাম: Backend E2E Seed Data And API Verification Guide.

## 2. What was implemented

এই ধাপে backend business logic পরিবর্তন করা হয়নি। নতুন API, migration, wallet mutation rule, বা Flutter UI যোগ করা হয়নি।

যা করা হয়েছে:

- `scripts/dev/seed-e2e-data.sql` তৈরি করা হয়েছে।
- `docs/backend-e2e-api-test-guide.md` তৈরি করা হয়েছে।
- `docs/test-checklist.md` update করা হয়েছে।
- `docs/codex-progress.md` update করা হয়েছে।

Seed script local PostgreSQL database-এ demo data insert করার জন্য। এটি production migration নয়।

## 3. Why this step is needed

SmartKash backend API manually test করতে database-এ enough demo data দরকার।

যেমন:

- Admin list API test করতে users, transactions, add money requests, loans, recharges, audit logs দরকার।
- Transaction history test করতে transaction rows দরকার।
- Wallet screen test করতে wallets দরকার।
- Merchant payment test করতে merchant accounts দরকার।
- Notification token list/check করতে firebase device rows দরকার।

তাই এই step-এ local testing-এর জন্য at least 15 demo rows তৈরি করার script রাখা হয়েছে।

## 4. Why this is not a Flyway migration

Flyway migration production schema তৈরি/পরিবর্তনের জন্য। Demo seed data production schema নয়।

এই কারণে seed file রাখা হয়েছে:

```text
scripts/dev/seed-e2e-data.sql
```

এটি রাখা হয়নি:

```text
services/backend/src/main/resources/db/migration/
```

কারণ migration folder-এ রাখলে application start করার সময় data automatically insert হতে পারে, যা production-like environment-এর জন্য dangerous।

## 5. Files/folders changed

এই step-এ changed files:

- `scripts/dev/seed-e2e-data.sql`
- `docs/backend-e2e-api-test-guide.md`
- `docs/test-checklist.md`
- `docs/codex-progress.md`
- `learning/step-34-backend-e2e-seed-data-guide.md`

## 6. Important seed command snippet

PowerShell থেকে seed run করার recommended pattern:

```powershell
$pinHash = '<BCrypt hash for PIN 12345>'
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db -v seed_pin_hash="'$pinHash'" -f scripts/dev/seed-e2e-data.sql
```

ব্যাখ্যা:

- `$pinHash` variable-এ BCrypt hash রাখা হয়।
- raw PIN `12345` database-এ রাখা হয় না।
- `-v seed_pin_hash="'$pinHash'"` দিয়ে psql variable পাঠানো হয়।
- SQL file-এর ভিতরে `:seed_pin_hash` ব্যবহার করে users table-এর `pin_hash` set করা হয়।
- `-f scripts/dev/seed-e2e-data.sql` script file run করে।

## 7. Important SQL snippet: PIN hash variable check

```sql
\if :{?seed_pin_hash}
\else
\echo 'ERROR: seed_pin_hash psql variable is required.'
\quit 1
\endif
```

Block-by-block ব্যাখ্যা:

- `\if :{?seed_pin_hash}` check করে psql variable দেওয়া হয়েছে কি না।
- variable না থাকলে `\else` block চলে।
- `\echo` terminal-এ error message দেখায়।
- `\quit 1` script stop করে, যাতে broken PIN data insert না হয়।

## 8. Important SQL snippet: seed users

```sql
INSERT INTO users (
    firebase_uid,
    mobile_number,
    role,
    status,
    pin_hash,
    pin_set,
    pin_updated_at
)
SELECT
    'seed-customer-' || lpad(gs::text, 3, '0'),
    '+88017' || lpad(gs::text, 8, '0'),
    'CUSTOMER',
    'ACTIVE',
    :seed_pin_hash,
    TRUE,
    CURRENT_TIMESTAMP
FROM generate_series(1, 15) AS gs
ON CONFLICT (firebase_uid) DO UPDATE
SET role = EXCLUDED.role,
    status = EXCLUDED.status,
    pin_hash = EXCLUDED.pin_hash,
    pin_set = EXCLUDED.pin_set,
    pin_updated_at = EXCLUDED.pin_updated_at,
    updated_at = CURRENT_TIMESTAMP;
```

Line-by-line ব্যাখ্যা:

- `INSERT INTO users` users table-এ demo user insert করে।
- `firebase_uid` fake local Firebase UID হিসেবে রাখা হয়েছে।
- `mobile_number` unique demo mobile number।
- `role` এখানে `CUSTOMER`।
- `status` `ACTIVE`, তাই APIs active user হিসেবে ধরতে পারবে।
- `pin_hash` raw PIN নয়; BCrypt hash।
- `pin_set = TRUE` মানে user PIN setup complete।
- `generate_series(1, 15)` দিয়ে 15 customer তৈরি হয়।
- `lpad(gs::text, 3, '0')` number-কে `001`, `002` format করে।
- `ON CONFLICT (firebase_uid)` script আবার run করলে duplicate error না দিয়ে existing seed user update করে।

## 9. Important SQL snippet: wallets

```sql
INSERT INTO wallets (user_id, balance, currency, status)
SELECT
    id,
    CASE
        WHEN role = 'CUSTOMER' THEN 10000.00 + CAST(right(firebase_uid, 3) AS INTEGER)
        WHEN role = 'MERCHANT' THEN 5000.00 + CAST(right(firebase_uid, 3) AS INTEGER)
        ELSE 0.00
    END,
    'BDT',
    'ACTIVE'
FROM users
WHERE firebase_uid = 'seed-admin-001'
   OR firebase_uid LIKE 'seed-customer-%'
   OR firebase_uid LIKE 'seed-merchant-user-%'
ON CONFLICT (user_id) DO UPDATE
SET balance = EXCLUDED.balance,
    currency = EXCLUDED.currency,
    status = EXCLUDED.status,
    updated_at = CURRENT_TIMESTAMP;
```

ব্যাখ্যা:

- প্রত্যেক seed user-এর wallet তৈরি হয়।
- customer wallet balance বেশি রাখা হয়েছে যাতে money API manually test করা যায়।
- merchant wallet balance আলাদা রাখা হয়েছে।
- admin wallet balance `0.00`।
- `currency` always `BDT`।
- `status` `ACTIVE`।
- `ON CONFLICT (user_id)` rerun করলে duplicate wallet হবে না।

## 10. Important SQL snippet: transactions and ledger entries

```sql
INSERT INTO transactions (
    transaction_reference,
    user_id,
    type,
    status,
    amount,
    counterparty_user_id,
    description,
    created_at
)
SELECT
    'SEED-TXN-' || lpad(gs::text, 3, '0'),
    c.id,
    CASE (gs - 1) % 6
        WHEN 0 THEN 'ADD_MONEY'
        WHEN 1 THEN 'SEND_MONEY'
        WHEN 2 THEN 'MERCHANT_PAYMENT'
        WHEN 3 THEN 'SAVINGS_DEPOSIT'
        WHEN 4 THEN 'MOBILE_RECHARGE'
        ELSE 'RECEIVE_MONEY'
    END,
    'SUCCESS',
    100.00 + gs,
    m.id,
    'Seed transaction ' || lpad(gs::text, 3, '0'),
    CURRENT_TIMESTAMP - (gs || ' days')::INTERVAL
FROM generate_series(1, 15) AS gs
JOIN users c ON c.firebase_uid = 'seed-customer-' || lpad(gs::text, 3, '0')
JOIN users m ON m.firebase_uid = 'seed-merchant-user-' || lpad(gs::text, 3, '0')
ON CONFLICT (transaction_reference) DO NOTHING;
```

ব্যাখ্যা:

- `transactions` table user-facing transaction history দেখানোর জন্য।
- `transaction_reference` unique reference।
- `type` বিভিন্ন transaction type cycle করে।
- `status` demo data-তে `SUCCESS`।
- `counterparty_user_id` merchant user-এর সাথে relation দেখায়।
- `ON CONFLICT DO NOTHING` transaction record immutable রাখার ধারণার সাথে align করে; existing seed transaction update করে না।

## 11. Why seeded users cannot directly login through Firebase

Seeded users fake `firebase_uid` ব্যবহার করে:

```text
seed-customer-001
seed-merchant-user-001
seed-admin-001
```

Firebase real ID token-এর subject এই fake UID হবে না। তাই seeded user দিয়ে direct Firebase login করা যাবে না।

Authenticated API test করার জন্য:

1. Firebase test OTP দিয়ে real test user login করতে হবে।
2. `POST /api/auth/firebase-login` থেকে backend JWT নিতে হবে।
3. দরকার হলে local DB-তে সেই real test user-এর role temporarily `ADMIN` করতে হবে।

## 12. Manual verification commands

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
.\mvnw.cmd spring-boot:run
```

Seed:

```powershell
cd /d D:\github\my-kash
$pinHash = '<BCrypt hash for PIN 12345>'
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db -v seed_pin_hash="'$pinHash'" -f scripts/dev/seed-e2e-data.sql
```

Database count:

```sql
SELECT COUNT(*) FROM users WHERE firebase_uid LIKE 'seed-%';
SELECT COUNT(*) FROM merchants WHERE merchant_number LIKE 'MERCH-%';
SELECT COUNT(*) FROM transactions WHERE transaction_reference LIKE 'SEED-TXN-%';
SELECT COUNT(*) FROM ledger_entries WHERE transaction_reference LIKE 'SEED-TXN-%';
SELECT COUNT(*) FROM add_money_requests WHERE note LIKE 'seed-add-money-%';
```

Expected output:

- seed users: `31`
- merchants: `15`
- transactions: `15`
- ledger entries: `15`
- add money requests: `15`

## 13. API output verification

Health check:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/actuator/health
```

Expected:

- HTTP `200`
- body contains `UP`

No JWT:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/api/wallet/me
```

Expected:

- HTTP `401`
- message `Authentication is required.`

Wrong JWT:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/api/wallet/me -Headers @{ Authorization = "Bearer wrong-token" }
```

Expected:

- HTTP `401`
- message `Invalid or expired backend JWT.`

## 14. Common mistakes and cautions

- Seed script production database-এ run করা যাবে না।
- raw PIN database-এ insert করা যাবে না।
- BCrypt hash ছাড়া seed script run করলে script stop করবে।
- PowerShell double quotes-এর ভিতরে `$2a...` hash দিলে `$` expansion problem হতে পারে। তাই `$pinHash` variable ব্যবহার করা safer।
- Seeded fake Firebase UID দিয়ে Firebase login হবে না।
- Admin API test করতে real logged-in user-এর role local DB-তে `ADMIN` করতে হবে এবং তারপর নতুন JWT নিতে হবে।
- Seed script delete করে না; cleanup দরকার হলে আলাদা safe cleanup script বানাতে হবে।

## 15. Git commands used

```powershell
git status --short --branch
git diff --check
git add scripts/dev/seed-e2e-data.sql docs/backend-e2e-api-test-guide.md docs/test-checklist.md docs/codex-progress.md learning/step-34-backend-e2e-seed-data-guide.md
git commit -m "step-34: add backend e2e seed data guide"
git push
git status --short --branch
```

## 16. What I learned from this step

এই step থেকে শিখলাম:

- local seed data production migration থেকে আলাদা রাখা উচিত।
- API E2E testing-এর জন্য realistic demo data দরকার।
- PIN hash ছাড়া money API ঠিকভাবে test করা যায় না।
- raw PIN কখনও database-এ রাখা যাবে না।
- seed data দিয়ে admin/read APIs এবং database consistency সহজে verify করা যায়।
- authenticated API test করতে real Firebase login এবং backend JWT এখনও দরকার।
