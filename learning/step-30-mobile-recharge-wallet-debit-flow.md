# Step 30: Mobile Recharge Wallet Debit Flow

## 1. Step Title

Step 30-এ SmartKash backend-এ demo Mobile Recharge-কে wallet debit সহ money-changing flow করা হয়েছে।

## 2. What Was Implemented

Existing endpoint:

```http
POST /api/recharge
```

এখন request body-তে PIN এবং idempotency key লাগবে:

```json
{
  "operator": "GP",
  "mobileNumber": "01712345678",
  "amount": 50.00,
  "pin": "12345",
  "idempotencyKey": "recharge-001",
  "note": "Demo recharge"
}
```

Successful recharge হলে backend:

- authenticated user খুঁজে
- user `ACTIVE` কিনা check করে
- PIN backend-এ verify করে
- idempotency key reserve/validate করে
- user wallet lock করে
- wallet active এবং sufficient balance কিনা check করে
- wallet থেকে recharge amount debit করে
- `MOBILE_RECHARGE` transaction record তৈরি করে
- immutable `DEBIT` ledger entry তৈরি করে
- `mobile_recharges` record `SUCCESS` হিসেবে save করে
- recharge record-এ transaction reference attach করে
- idempotency key completed করে

Important: এটি এখনও zero-budget demo recharge। কোনো real recharge provider/API call করা হয়নি।

## 3. Why This Step Is Needed

আগে mobile recharge শুধু demo record তৈরি করত, wallet balance কমাত না। কিন্তু realistic wallet MVP flow শেখার জন্য recharge একটি money-changing operation হওয়া দরকার।

এই step দেখায় কীভাবে provider integration ছাড়াই safe wallet debit flow তৈরি করা যায়।

## 4. Files Created Or Changed

Created:

```text
learning/step-30-mobile-recharge-wallet-debit-flow.md
```

Changed:

```text
services/backend/src/main/java/com/smartkash/recharge/dto/request/CreateMobileRechargeRequest.java
services/backend/src/main/java/com/smartkash/recharge/entity/MobileRecharge.java
services/backend/src/main/java/com/smartkash/recharge/repository/MobileRechargeRepository.java
services/backend/src/main/java/com/smartkash/recharge/service/impl/MobileRechargeServiceImpl.java
docs/backend-api-plan.md
docs/security-plan.md
docs/codex-progress.md
```

## 5. Important Code Snippets

### CreateMobileRechargeRequest

```java
public record CreateMobileRechargeRequest(
        MobileOperator operator,
        String mobileNumber,
        BigDecimal amount,
        String pin,
        String idempotencyKey,
        String note
) {
}
```

Block-by-block explanation:

- `operator`: GP, ROBI, BANGLALINK, AIRTEL, TELETALK type operator।
- `mobileNumber`: যে mobile number recharge হবে।
- `amount`: wallet থেকে কত টাকা debit হবে।
- `pin`: recharge confirm করার জন্য backend PIN verification।
- `idempotencyKey`: retry/double-click duplicate debit prevent করার key।
- `note`: optional note, transaction description-এ যোগ হয়।

### Transaction Reference Attach

```java
public void attachTransactionReference(String transactionReference) {
    this.transactionReference = transactionReference;
}
```

Explanation:

- Recharge record তৈরি হওয়ার আগে transaction reference generate হয়।
- এই method দিয়ে recharge record transaction-এর সাথে linked হয়।
- পরে transaction history এবং recharge history মিলিয়ে দেখা যায়।

### PIN, Idempotency, Wallet Debit

```java
PinVerificationResponse pinVerification = authService.verifyPin(principal, new VerifyPinRequest(request.pin()));
if (!pinVerification.verified()) {
    throw new IllegalArgumentException("PIN verification failed.");
}

IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(user, request.idempotencyKey(), requestHash);

Wallet wallet = walletRepository.findByUserIdForUpdate(user.getId())
        .orElseThrow(() -> new ResourceNotFoundException("User wallet was not found."));
ensureActiveWallet(wallet);
ensureSufficientBalance(wallet, request.amount());

BigDecimal balanceAfter = wallet.debit(request.amount());
```

Explanation:

- PIN wrong হলে recharge হবে না।
- Idempotency key duplicate request আটকায়।
- `findByUserIdForUpdate` wallet row lock করে।
- Wallet active না হলে recharge হবে না।
- Balance কম হলে recharge হবে না।
- `wallet.debit` wallet balance কমায়।

### Transaction And Ledger

```java
TransactionRecord transaction = transactionRecordRepository.save(new TransactionRecord(
        transactionReference,
        user,
        TransactionType.MOBILE_RECHARGE,
        TransactionStatus.SUCCESS,
        request.amount(),
        null,
        description(request)
));
ledgerEntryRepository.save(new LedgerEntry(
        wallet,
        user,
        transactionReference,
        null,
        LedgerEntryType.DEBIT,
        request.amount(),
        balanceAfter,
        "Mobile Recharge wallet debit"
));
```

Explanation:

- Transaction history-তে `MOBILE_RECHARGE` record দেখা যাবে।
- Ledger entry wallet debit-এর immutable record।
- Counterparty নেই, কারণ real provider নেই।
- Ledger ছাড়া wallet balance change করা হয়নি।

### Recharge Save

```java
MobileRecharge recharge = new MobileRecharge(
        user,
        request.operator(),
        request.mobileNumber(),
        request.amount()
);
recharge.attachTransactionReference(transaction.getTransactionReference());
MobileRecharge savedRecharge = mobileRechargeRepository.save(recharge);
```

Explanation:

- Recharge record demo `SUCCESS` status নিয়ে তৈরি হয়।
- Transaction reference attach হওয়ায় recharge history এবং transaction history linked থাকে।
- Real recharge provider call করা হয়নি।

## 6. Expected Manual Outputs

Successful API response:

```json
{
  "id": 1,
  "operator": "GP",
  "mobileNumber": "01712345678",
  "amount": 50.00,
  "status": "SUCCESS",
  "transactionReference": "RC-ABC123...",
  "createdAt": "2026-07-05T..."
}
```

Wrong PIN:

```text
Expected: 400 Bad Request
PIN verification failed.
```

Duplicate idempotency key with same body:

```text
Expected: no second wallet debit, same completed recharge record returned.
```

Same idempotency key with different amount/mobile/operator:

```text
Expected: 400 Bad Request
Idempotency key was already used for a different Mobile Recharge request.
```

Insufficient balance:

```text
Expected: 400 Bad Request
User wallet has insufficient balance.
```

## 7. Database Expected Output

After successful recharge:

- `wallets.balance` decreases.
- `mobile_recharges` has one `SUCCESS` row with `transaction_reference`.
- `transactions` has one `MOBILE_RECHARGE` row.
- `ledger_entries` has one `DEBIT` row.
- `idempotency_keys` has one `MOBILE_RECHARGE` row with `COMPLETED`.

## 8. How This Fits Into SmartKash Flow

Future Flutter recharge flow:

1. User operator select করবে।
2. User mobile number and amount দেবে।
3. User PIN দেবে।
4. App unique idempotency key দিয়ে `/api/recharge` call করবে।
5. Backend wallet debit করবে।
6. Recharge history-তে success record দেখাবে।
7. Transaction history-তে recharge transaction দেখাবে।

## 9. Common Mistakes And Cautions

- Real recharge provider integrate করা হয়নি; এটাকে real recharge ভাবা যাবে না।
- PIN ছাড়া wallet debit করা যাবে না।
- Idempotency ছাড়া retry duplicate debit করতে পারে।
- Wallet lock ছাড়া concurrent recharge balance ভুল করতে পারে।
- Recharge record success হলেও provider confirmation নেই, কারণ MVP demo flow।
- Local `application-local.yml` commit করা যাবে না।

## 10. Manual Verification Commands

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
.\mvnw.cmd spring-boot:run
```

Database:

```powershell
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
SELECT id, user_id, balance, status FROM wallets ORDER BY id;
SELECT id, user_id, operator, mobile_number, amount, status, transaction_reference FROM mobile_recharges ORDER BY id DESC LIMIT 10;
SELECT id, transaction_reference, user_id, type, status, amount FROM transactions WHERE type = 'MOBILE_RECHARGE' ORDER BY id DESC LIMIT 10;
SELECT id, wallet_id, user_id, transaction_reference, entry_type, amount, balance_after FROM ledger_entries ORDER BY id DESC LIMIT 10;
SELECT id, user_id, idempotency_key, operation_type, status, response_body FROM idempotency_keys ORDER BY id DESC LIMIT 10;
```

General:

```powershell
cd /d D:\github\my-kash
git status
```

## 11. Git Commands Used

```powershell
git status --short --branch
git diff --check
git add <step-30-files>
git commit -m "step-30: add mobile recharge wallet debit flow"
git push
git status --short --branch
```

## 12. What I Learned

এই step থেকে শিখলাম provider integration ছাড়াও recharge wallet debit flow শেখা যায়। এখানে provider call নেই, কিন্তু wallet security, PIN, idempotency, transaction history, ledger audit trail সব real money-changing style-এ রাখা হয়েছে।
