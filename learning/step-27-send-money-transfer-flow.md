# Step 27: Send Money Transfer Flow

## 1. Step Title

Step 27-এ SmartKash backend-এ actual Send Money wallet-to-wallet transfer flow যোগ করা হয়েছে।

## 2. What Was Implemented

এই step-এ authenticated money-changing API যোগ করা হয়েছে:

```http
POST /api/send-money
```

এই API receiver select করতে পারে:

```json
{
  "mobileNumber": "01712345678",
  "amount": 50.00,
  "pin": "12345",
  "idempotencyKey": "send-money-001",
  "note": "Lunch"
}
```

অথবা QR payload দিয়ে:

```json
{
  "qrPayload": "SMARTKASH_USER:01712345678",
  "amount": 50.00,
  "pin": "12345",
  "idempotencyKey": "send-money-002"
}
```

Successful transfer হলে backend:

- sender user খুঁজে active কিনা validate করে
- receiver mobile/QR থেকে resolve করে
- receiver active কিনা check করে
- self-transfer block করে
- PIN backend-এ verify করে
- idempotency key reserve/validate করে
- sender wallet lock করে
- receiver wallet lock করে
- sender balance sufficient কিনা check করে
- sender wallet debit করে
- receiver wallet credit করে
- sender-এর জন্য `SEND_MONEY` transaction record তৈরি করে
- receiver-এর জন্য `RECEIVE_MONEY` transaction record তৈরি করে
- একই sender transfer reference দিয়ে linked `DEBIT` এবং `CREDIT` ledger entries তৈরি করে
- idempotency key completed করে

## 3. Why This Step Is Needed

Send Money SmartKash-এর core wallet-to-wallet flow। এই feature-এ টাকা এক wallet থেকে আরেক wallet-এ যায়, তাই শুধু API response দিলেই হবে না। Wallet balance, transaction history, ledger history, retry protection, PIN security সব একসাথে ঠিক রাখতে হবে।

এই step-এর আগে receiver validation ছিল, কিন্তু টাকা move করা হতো না। Step 27 সেই actual transfer foundation যোগ করেছে।

## 4. Files Created Or Changed

Created:

```text
services/backend/src/main/java/com/smartkash/sendmoney/dto/request/SendMoneyRequest.java
services/backend/src/main/java/com/smartkash/sendmoney/dto/response/SendMoneyTransferResponse.java
services/backend/src/main/java/com/smartkash/sendmoney/service/SendMoneyTransferService.java
services/backend/src/main/java/com/smartkash/sendmoney/service/impl/SendMoneyTransferServiceImpl.java
learning/step-27-send-money-transfer-flow.md
```

Changed:

```text
services/backend/src/main/java/com/smartkash/sendmoney/controller/SendMoneyReceiverController.java
services/backend/src/main/java/com/smartkash/wallet/entity/Wallet.java
services/backend/src/main/java/com/smartkash/ledger/entity/LedgerEntry.java
docs/backend-api-plan.md
docs/security-plan.md
docs/codex-progress.md
```

## 5. Important Code Snippets

### SendMoneyRequest

```java
public record SendMoneyRequest(
        String mobileNumber,
        String qrPayload,
        BigDecimal amount,
        String pin,
        String idempotencyKey,
        String note
) {
}
```

Block-by-block explanation:

- `mobileNumber`: receiver manually mobile number দিয়ে select করলে এই field ব্যবহার হয়।
- `qrPayload`: QR scan করলে payload এখানে আসে। MVP format: `SMARTKASH_USER:<mobile-number>`।
- `amount`: sender কত টাকা পাঠাবে।
- `pin`: money-changing action confirm করার জন্য backend PIN verification।
- `idempotencyKey`: duplicate request prevent করার জন্য unique key।
- `note`: optional short note, transaction description-এ যোগ হয়।

### Controller Endpoint

```java
@PostMapping
public ResponseEntity<SendMoneyTransferResponse> sendMoney(
        @AuthenticationPrincipal JwtPrincipal principal,
        @Valid @RequestBody SendMoneyRequest request
) {
    return ResponseEntity.ok(sendMoneyTransferService.sendMoney(principal, request));
}
```

Explanation:

- `@PostMapping`: `/api/send-money` endpoint handle করে।
- `JwtPrincipal principal`: authenticated sender-এর JWT data নেয়।
- `@Valid`: request validation চালায়।
- Controller business logic করে না; service layer-এ পাঠায়।

### PIN Verification

```java
PinVerificationResponse pinVerification = authService.verifyPin(principal, new VerifyPinRequest(request.pin()));
if (!pinVerification.verified()) {
    return failedResponse("PIN verification failed.", request.amount(), receiver);
}
```

Explanation:

- PIN verification backend-এ হয়।
- Raw PIN database-এ store হয় না; existing BCrypt hash-এর সাথে match করা হয়।
- PIN wrong হলে wallet debit/credit, ledger, transaction কিছুই হয় না।
- এই response return করলে failed PIN attempt commit হতে পারে, যাতে rate limiting কাজ করে।

### Idempotency

```java
IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(
        sender,
        request.idempotencyKey(),
        requestHash
);
if (idempotencyKey.getStatus() == IdempotencyStatus.COMPLETED) {
    return completedResponse(idempotencyKey, request.amount(), receiver);
}
```

Explanation:

- একই user একই `idempotencyKey` আবার পাঠালে backend duplicate transfer করবে না।
- Request hash same হলে completed response ফেরত দেওয়া যায়।
- Same key দিয়ে different amount/receiver দিলে error হবে।

### Wallet Lock And Balance Change

```java
Wallet senderWallet = walletRepository.findByUserIdForUpdate(sender.getId())
        .orElseThrow(() -> new ResourceNotFoundException("Sender wallet was not found."));
Wallet receiverWallet = walletRepository.findByUserIdForUpdate(receiver.getId())
        .orElseThrow(() -> new ResourceNotFoundException("Receiver wallet was not found."));

ensureSufficientBalance(senderWallet, request.amount());

BigDecimal senderBalanceAfter = senderWallet.debit(request.amount());
BigDecimal receiverBalanceAfter = receiverWallet.credit(request.amount());
```

Explanation:

- `findByUserIdForUpdate`: wallet row lock করে, যাতে same wallet একই সময়ে দুই request ভুল balance update না করে।
- `ensureSufficientBalance`: sender-এর balance কম হলে transfer বন্ধ করে।
- `debit`: sender wallet থেকে amount subtract করে।
- `credit`: receiver wallet-এ amount add করে।
- সবকিছু একই database transaction-এর মধ্যে হয়।

### Transaction Records

```java
TransactionRecord senderTransaction = transactionRecordRepository.save(new TransactionRecord(
        senderTransactionReference,
        sender,
        TransactionType.SEND_MONEY,
        TransactionStatus.SUCCESS,
        request.amount(),
        receiver,
        description
));
transactionRecordRepository.save(new TransactionRecord(
        receiverTransactionReference,
        receiver,
        TransactionType.RECEIVE_MONEY,
        TransactionStatus.SUCCESS,
        request.amount(),
        sender,
        description
));
```

Explanation:

- Sender transaction history-তে `SEND_MONEY` record দেখা যাবে।
- Receiver transaction history-তে `RECEIVE_MONEY` record দেখা যাবে।
- দুই record-এর আলাদা transaction reference আছে, কারণ current database constraint transaction reference unique।
- Ledger entries sender transfer reference দিয়ে linked করা হয়।

### Linked Ledger Entries

```java
LedgerEntry debitEntry = ledgerEntryRepository.save(new LedgerEntry(
        senderWallet,
        sender,
        senderTransactionReference,
        null,
        LedgerEntryType.DEBIT,
        request.amount(),
        senderBalanceAfter,
        "Send Money wallet debit"
));
LedgerEntry creditEntry = ledgerEntryRepository.save(new LedgerEntry(
        receiverWallet,
        receiver,
        senderTransactionReference,
        debitEntry,
        LedgerEntryType.CREDIT,
        request.amount(),
        receiverBalanceAfter,
        "Send Money wallet credit"
));
debitEntry.linkTo(creditEntry);
ledgerEntryRepository.save(debitEntry);
```

Explanation:

- Debit entry sender wallet থেকে টাকা বের হওয়া record করে।
- Credit entry receiver wallet-এ টাকা ঢোকা record করে।
- দুই ledger entry একই `senderTransactionReference` ব্যবহার করে।
- `creditEntry` debit entry-কে link করে।
- `debitEntry.linkTo(creditEntry)` দিয়ে opposite direction-ও link করা হয়।
- Ledger entries update/delete করা যাবে না; এখানে link set করা create flow-এর অংশ।

## 6. How This Fits Into SmartKash Flow

Future Flutter Send Money flow:

1. User receiver mobile number লিখবে বা QR scan করবে।
2. App `/api/send-money/resolve-receiver` দিয়ে receiver verify করবে।
3. User amount এবং PIN দেবে।
4. App unique `idempotencyKey` দিয়ে `/api/send-money` call করবে।
5. Backend wallet transfer complete করবে।
6. Sender wallet balance কমবে।
7. Receiver wallet balance বাড়বে।
8. Transaction history-তে sender/receiver দুইজনই record দেখবে।
9. Ledger history audit trail হিসেবে থাকবে।

## 7. Expected Manual Outputs

Success response example:

```json
{
  "success": true,
  "message": "Send Money completed successfully.",
  "transactionReference": "SM-ABC123...",
  "status": "SUCCESS",
  "amount": 50.00,
  "senderBalanceAfter": 950.00,
  "receiverUserId": 2,
  "receiverMobileNumber": "01712345678",
  "createdAt": "2026-07-04T..."
}
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

Duplicate request with same idempotency key and same body:

```text
Expected: no second debit, response says request was already completed.
```

Same idempotency key with different amount/receiver:

```text
Expected: 400 Bad Request
Idempotency key was already used for a different Send Money request.
```

Insufficient balance:

```text
Expected: 400 Bad Request
Sender wallet has insufficient balance.
```

Database expected output after successful transfer:

- `wallets`: sender balance decreases, receiver balance increases.
- `transactions`: one `SEND_MONEY` row for sender, one `RECEIVE_MONEY` row for receiver.
- `ledger_entries`: one `DEBIT` row and one `CREDIT` row with same sender transfer reference.
- `idempotency_keys`: one `SEND_MONEY` row with `COMPLETED` status.

## 8. Common Mistakes And Cautions

- PIN verify না করে wallet debit করা যাবে না।
- Idempotency ছাড়া transfer করলে double-click বা retry-তে duplicate debit হতে পারে।
- Sender এবং receiver wallet lock না করলে concurrent request balance ভুল করতে পারে।
- Ledger entry ছাড়া wallet balance change করা যাবে না।
- Transaction record ছাড়া user history empty থাকবে।
- QR payload সরাসরি বিশ্বাস করা যাবে না; registered receiver resolve করতে হবে।
- Same idempotency key দিয়ে different request allow করা যাবে না।
- Local `application-local.yml` commit করা যাবে না।

## 9. Manual Verification Commands

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
SELECT id, transaction_reference, user_id, type, status, amount, counterparty_user_id FROM transactions ORDER BY id DESC LIMIT 10;
SELECT id, wallet_id, user_id, transaction_reference, linked_entry_id, entry_type, amount, balance_after FROM ledger_entries ORDER BY id DESC LIMIT 10;
SELECT id, user_id, idempotency_key, operation_type, status, response_body FROM idempotency_keys ORDER BY id DESC LIMIT 10;
```

General:

```powershell
cd /d D:\github\my-kash
git status
```

## 10. Git Commands Used

```powershell
git status --short --branch
git diff --check
git add <step-27-files>
git commit -m "step-27: add send money transfer flow"
git push
git status --short --branch
```

## 11. What I Learned

এই step থেকে শিখলাম money-changing API বানাতে শুধু balance update করলেই হয় না। PIN security, idempotency, wallet locking, transaction record, immutable ledger entry, duplicate request protection, আর manual verification output একসাথে design করতে হয়। Send Money flow এখন backend foundation হিসেবে usable, কিন্তু Flutter UI এবং FCM alert এখনো future scope।
