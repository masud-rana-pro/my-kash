# Step 29: Savings Deposit Transfer Flow

## 1. Step Title

Step 29-এ SmartKash backend-এ Savings Goal-এ wallet থেকে deposit করার money-changing flow যোগ করা হয়েছে।

## 2. What Was Implemented

নতুন authenticated API:

```http
POST /api/savings/goals/{goalId}/deposit
```

Request example:

```json
{
  "amount": 100.00,
  "pin": "12345",
  "idempotencyKey": "savings-deposit-001",
  "note": "Monthly saving"
}
```

Successful deposit হলে backend:

- authenticated user খুঁজে
- user `ACTIVE` কিনা check করে
- savings goal user-এর নিজের goal কিনা check করে
- goal `ACTIVE` কিনা check করে
- PIN backend-এ verify করে
- idempotency key reserve/validate করে
- user wallet lock করে
- wallet active এবং sufficient balance কিনা check করে
- wallet থেকে amount debit করে
- savings goal-এর `currentAmount` বাড়ায়
- target amount পূরণ হলে goal status `COMPLETED` করে
- `SAVINGS_DEPOSIT` transaction record তৈরি করে
- immutable `DEBIT` ledger entry তৈরি করে
- idempotency key completed করে

## 3. Why This Step Is Needed

Savings Goal তৈরি করা Step 21-এ হয়েছিল, কিন্তু সেখানে goal-এ টাকা জমা দেওয়া যেত না। Step 29 savings deposit যোগ করেছে, যাতে user wallet থেকে টাকা goal savings-এ রাখতে পারে।

এটি money-changing operation, তাই PIN, idempotency, wallet locking, transaction, ledger সব দরকার।

## 4. Files Created Or Changed

Created:

```text
services/backend/src/main/java/com/smartkash/savings/dto/request/SavingsDepositRequest.java
services/backend/src/main/java/com/smartkash/savings/dto/response/SavingsDepositResponse.java
learning/step-29-savings-deposit-transfer-flow.md
```

Changed:

```text
services/backend/src/main/java/com/smartkash/savings/controller/SavingsGoalController.java
services/backend/src/main/java/com/smartkash/savings/entity/SavingsGoal.java
services/backend/src/main/java/com/smartkash/savings/repository/SavingsGoalRepository.java
services/backend/src/main/java/com/smartkash/savings/service/SavingsGoalService.java
services/backend/src/main/java/com/smartkash/savings/service/impl/SavingsGoalServiceImpl.java
docs/backend-api-plan.md
docs/security-plan.md
docs/codex-progress.md
```

## 5. Important Code Snippets

### SavingsDepositRequest

```java
public record SavingsDepositRequest(
        BigDecimal amount,
        String pin,
        String idempotencyKey,
        String note
) {
}
```

Block-by-block explanation:

- `amount`: কত টাকা wallet থেকে savings goal-এ যাবে।
- `pin`: money-changing action confirm করার জন্য।
- `idempotencyKey`: duplicate deposit আটকানোর জন্য unique key।
- `note`: optional note, transaction description-এ যোগ হয়।

### Controller Endpoint

```java
@PostMapping("/{goalId}/deposit")
public ResponseEntity<SavingsDepositResponse> depositToGoal(
        @AuthenticationPrincipal JwtPrincipal principal,
        @PathVariable Long goalId,
        @Valid @RequestBody SavingsDepositRequest request
) {
    return ResponseEntity.ok(savingsGoalService.depositToGoal(principal, goalId, request));
}
```

Explanation:

- URL-এর `{goalId}` দিয়ে কোন savings goal-এ deposit হবে বোঝায়।
- `principal` দিয়ে authenticated user পাওয়া যায়।
- `@Valid` request validation চালায়।
- Controller business logic করে না; service layer-এ পাঠায়।

### SavingsGoal.deposit

```java
public BigDecimal deposit(BigDecimal amount) {
    currentAmount = currentAmount.add(amount);
    if (currentAmount.compareTo(targetAmount) >= 0) {
        status = SavingsGoalStatus.COMPLETED;
    }
    return currentAmount;
}
```

Explanation:

- `currentAmount.add(amount)`: goal-এ জমা amount যোগ করে।
- `compareTo(targetAmount) >= 0`: target পূরণ বা exceed করলে true।
- `status = COMPLETED`: goal complete mark করে।
- Return value future use/debugging-এর জন্য updated current amount দেয়।

### Locked Goal Query

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("select g from SavingsGoal g where g.id = :goalId and g.user.id = :userId")
Optional<SavingsGoal> findByIdAndUserIdForUpdate(@Param("goalId") Long goalId, @Param("userId") Long userId);
```

Explanation:

- `PESSIMISTIC_WRITE`: same goal-এ একসাথে দুই deposit এসে current amount ভুল না করার জন্য lock করে।
- `g.id = :goalId`: requested goal খুঁজে।
- `g.user.id = :userId`: অন্য user-এর goal-এ deposit করা block করে।

### PIN And Idempotency

```java
PinVerificationResponse pinVerification = authService.verifyPin(principal, new VerifyPinRequest(request.pin()));
if (!pinVerification.verified()) {
    return failedResponse("PIN verification failed.", request.amount(), goal);
}

IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(user, request.idempotencyKey(), requestHash);
```

Explanation:

- PIN backend-এ verify হয়।
- PIN wrong হলে wallet debit হয় না।
- Idempotency key duplicate request হলে দ্বিতীয়বার wallet debit হতে দেয় না।

### Wallet Debit And Goal Update

```java
Wallet wallet = walletRepository.findByUserIdForUpdate(user.getId())
        .orElseThrow(() -> new ResourceNotFoundException("User wallet was not found."));
ensureActiveWallet(wallet);
ensureSufficientBalance(wallet, request.amount());

BigDecimal walletBalanceAfter = wallet.debit(request.amount());
goal.deposit(request.amount());
SavingsGoal savedGoal = savingsGoalRepository.save(goal);
```

Explanation:

- `findByUserIdForUpdate`: wallet row lock করে।
- `ensureActiveWallet`: wallet blocked হলে deposit হবে না।
- `ensureSufficientBalance`: balance কম হলে deposit হবে না।
- `wallet.debit`: wallet থেকে টাকা কমায়।
- `goal.deposit`: goal current amount বাড়ায়।
- `save(goal)`: updated goal persist করে।

### Transaction And Ledger

```java
TransactionRecord transaction = transactionRecordRepository.save(new TransactionRecord(
        transactionReference,
        user,
        TransactionType.SAVINGS_DEPOSIT,
        TransactionStatus.SUCCESS,
        request.amount(),
        null,
        description(request.note(), savedGoal)
));
ledgerEntryRepository.save(new LedgerEntry(
        wallet,
        user,
        transactionReference,
        null,
        LedgerEntryType.DEBIT,
        request.amount(),
        walletBalanceAfter,
        "Savings deposit wallet debit"
));
```

Explanation:

- `SAVINGS_DEPOSIT` transaction history-তে deposit দেখাবে।
- Ledger entry wallet debit-এর immutable audit record।
- এখানে receiver wallet নেই, কারণ টাকা user-এর goal balance field-এ যাচ্ছে।
- Wallet balance change ledger ছাড়া করা হয়নি।

## 6. Expected Manual Outputs

Success response:

```json
{
  "success": true,
  "message": "Savings deposit completed successfully.",
  "transactionReference": "SD-ABC123...",
  "status": "SUCCESS",
  "amount": 100.00,
  "walletBalanceAfter": 900.00,
  "goal": {
    "id": 1,
    "name": "Laptop Fund",
    "targetAmount": 1000.00,
    "currentAmount": 300.00,
    "status": "ACTIVE"
  }
}
```

Target পূরণ হলে:

```json
"status": "COMPLETED"
```

Wrong PIN:

```json
{
  "success": false,
  "message": "PIN verification failed.",
  "transactionReference": null,
  "status": "FAILED"
}
```

Duplicate idempotency key with same body:

```text
Expected: no second wallet debit, response says already completed.
```

Same idempotency key with different amount/goal:

```text
Expected: 400 Bad Request
Idempotency key was already used for a different Savings Deposit request.
```

Insufficient balance:

```text
Expected: 400 Bad Request
User wallet has insufficient balance.
```

## 7. Database Expected Output

After successful deposit:

- `wallets.balance` decreases for the user.
- `savings_goals.current_amount` increases.
- `savings_goals.status` becomes `COMPLETED` if target is reached.
- `transactions` gets one `SAVINGS_DEPOSIT` row.
- `ledger_entries` gets one `DEBIT` row.
- `idempotency_keys` gets one `SAVINGS_DEPOSIT` row with `COMPLETED`.

## 8. How This Fits Into SmartKash Flow

Future Flutter savings flow:

1. User savings goal list দেখবে।
2. User একটি goal select করবে।
3. User deposit amount এবং PIN দেবে।
4. App unique idempotency key দিয়ে API call করবে।
5. Backend wallet debit করবে এবং goal current amount বাড়াবে।
6. User transaction history-তে savings deposit দেখবে।
7. Goal target পূরণ হলে completed দেখাবে।

## 9. Common Mistakes And Cautions

- অন্য user-এর goal-এ deposit করা যাবে না।
- Completed বা cancelled goal-এ deposit করা যাবে না।
- PIN wrong হলে wallet debit করা যাবে না।
- Idempotency ছাড়া retry করলে duplicate debit হতে পারে।
- Wallet debit ledger ছাড়া করা যাবে না।
- Savings goal balance আর wallet balance আলাদা concept।
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
SELECT id, user_id, name, target_amount, current_amount, status FROM savings_goals ORDER BY id;
SELECT id, transaction_reference, user_id, type, status, amount FROM transactions WHERE type = 'SAVINGS_DEPOSIT' ORDER BY id DESC LIMIT 10;
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
git add <step-29-files>
git commit -m "step-29: add savings deposit transfer flow"
git push
git status --short --branch
```

## 12. What I Learned

এই step থেকে শিখলাম savings deposit একটি wallet debit operation, কিন্তু receiver অন্য wallet নয়; receiver হলো user's savings goal balance। তাই wallet ledger-এ debit record থাকবে, transaction history-তে `SAVINGS_DEPOSIT` থাকবে, আর savings goal-এর `currentAmount` update হবে।
