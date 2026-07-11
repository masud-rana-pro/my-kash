# Step 65: Local Demo Seed Data

## 1. Step title

এই step-এর নাম: **Step 65: Local Demo Seed Data**।

## 2. কী করা হয়েছে

এই step-এ local PostgreSQL database `smartkash_db`-তে demo/E2E test data insert করা হয়েছে।

Existing script run করা হয়েছে:

```text
scripts/dev/seed-e2e-data.sql
```

Seed PIN:

```text
12345
```

## 3. কেন এই step দরকার

App-এর সব screen manually test করতে হলে database-এ valid related data দরকার:

- users
- user_profiles
- wallets
- merchants
- transactions
- ledger_entries
- add_money_requests
- loan_requests
- mobile_recharges
- savings_goals
- idempotency_keys
- firebase_devices
- admin_audit_logs

Empty database হলে Home, Transactions, Recharge, Savings, Merchant Payment, Admin/API testing পুরো flow দেখা কঠিন হয়।

## 4. কোন files/folders/classes/config change হয়েছে

এই step-এ app code বা database schema change করা হয়নি।

Only documentation updated:

- `docs/codex-progress.md`
- `learning/step-65-local-demo-seed-data.md`

Actual data local PostgreSQL database-এ insert করা হয়েছে।

## 5. Important command snippets

### BCrypt hash generate

```powershell
java -cp "<spring-security-crypto.jar>;<spring-jcl.jar>;%TEMP%" SmartKashBcryptTool
```

### Seed script run

```powershell
$env:PGPASSWORD='root'
$hash='<BCrypt hash for PIN 12345>'
& 'C:\Program Files\PostgreSQL\17\bin\psql.exe' `
  -h localhost `
  -p 5432 `
  -U smartkash_admin `
  -d smartkash_db `
  -v "seed_pin_hash='$hash'" `
  -f scripts\dev\seed-e2e-data.sql
```

## 6. Command explanation

`$env:PGPASSWORD='root'` psql command-কে database password দেয়।

`$hash='<BCrypt hash for PIN 12345>'` demo users-এর PIN hash variable।

`-h localhost` local PostgreSQL host।

`-p 5432` PostgreSQL port।

`-U smartkash_admin` database user।

`-d smartkash_db` target database।

`-v "seed_pin_hash='$hash'"` SQL script-এর `:seed_pin_hash` variable set করে।

`-f scripts\dev\seed-e2e-data.sql` seed SQL file run করে।

## 7. Inserted seed output

Seed script output:

```text
add_money_requests | 15
admin_audit_logs   | 15
firebase_devices   | 15
idempotency_keys   | 15
ledger_entries     | 15
loan_requests      | 15
merchants          | 15
mobile_recharges   | 15
savings_goals      | 15
transactions       | 15
user_profiles      | 31
users              | 31
wallets            | 31
```

`users`, `user_profiles`, এবং `wallets` বেশি কারণ seed data-তে admin, customers, এবং merchants লাগে।

## 8. SmartKash app flow-তে কীভাবে কাজে লাগবে

- Transaction screen-এ seed transactions দেখা যাবে।
- Merchant Payment test করার জন্য seed merchants আছে।
- Recharge history test করার জন্য mobile recharge records আছে।
- Savings screen test করার জন্য savings goals আছে।
- Loan screen test করার জন্য loan requests আছে।
- Wallet balance test করার জন্য wallets আছে।

## 9. Common mistakes and cautions

- এই data real money নয়।
- Production database-এ এই script run করা যাবে না।
- Seed PIN `12345` learning/demo purpose only।
- Firebase OTP login real Firebase user-এর জন্য; seed users সরাসরি Firebase login account নয়।
- Local-only config/secrets commit করা যাবে না।

## 10. Manual verification commands

```powershell
cd /d D:\github\my-kash
$env:PGPASSWORD='root'
& 'C:\Program Files\PostgreSQL\17\bin\psql.exe' -h localhost -p 5432 -U smartkash_admin -d smartkash_db
```

Then run:

```sql
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM user_profiles;
SELECT COUNT(*) FROM wallets;
SELECT COUNT(*) FROM merchants;
SELECT COUNT(*) FROM transactions;
SELECT COUNT(*) FROM ledger_entries;
SELECT COUNT(*) FROM add_money_requests;
SELECT COUNT(*) FROM loan_requests;
SELECT COUNT(*) FROM mobile_recharges;
SELECT COUNT(*) FROM savings_goals;
SELECT COUNT(*) FROM idempotency_keys;
SELECT COUNT(*) FROM firebase_devices;
SELECT COUNT(*) FROM admin_audit_logs;
```

## 11. Expected output

Main seed tables should show at least `10` rows. Current seed output shows at least `15` rows for main business tables.

## 12. Git commands used

```powershell
git status
git add docs/codex-progress.md learning/step-65-local-demo-seed-data.md
git commit -m "step-65: document local demo seed data"
git push
```

## 13. কী শিখলাম

এই step থেকে শিখলাম local demo data শুধু app testing-এর জন্য। Proper related seed data থাকলে wallet, transaction, merchant, recharge, savings, loan, admin read screens/manual API flow সহজে verify করা যায়।
