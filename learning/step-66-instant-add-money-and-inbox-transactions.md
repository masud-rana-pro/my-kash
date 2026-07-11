# Step 66: Instant Add Money And Inbox Transactions

## 1. Step title

এই step-এর নাম: **Step 66: Instant Add Money And Inbox Transactions**।

## 2. What was implemented

এই step-এ SmartKash-এ দুইটা গুরুত্বপূর্ণ পরিবর্তন করা হয়েছে:

- Add Money আর admin approval/pending flow নয়।
- Customer amount দিয়ে submit করলেই wallet balance credit হবে।
- Backend একই সাথে Add Money record, transaction record, ledger entry, এবং idempotency record তৈরি করবে।
- Flutter Add Money screen নতুন করে polish করা হয়েছে।
- Inbox tab এখন reference screenshot-এর মতো `Transactions` এবং `Notifications` tab দেখায়।
- Inbox `Transactions` tab transaction history দেখায়, search করে, row tap করলে receipt bottom sheet খুলে।

## 3. Why this step is needed

আগের flow-তে Add Money submit করলে request `PENDING` থাকত এবং admin approval লাগত। User এখন চেয়েছে Add Money submit করলেই money add হবে, কোনো bank/admin approval থাকবে না। তাই flow সহজ করা হয়েছে।

এই MVP learning project-এ real bank/payment gateway নেই। তাই Add Money হলো demo top-up:

1. User amount দেয়।
2. Backend wallet lock করে।
3. Balance credit করে।
4. Transaction history তৈরি করে।
5. Ledger entry তৈরি করে।
6. User Inbox > Transactions থেকে history দেখতে পারে।

## 4. Files/folders changed

Backend:

- `services/backend/src/main/java/com/smartkash/addmoney/dto/request/CreateAddMoneyRequest.java`
- `services/backend/src/main/java/com/smartkash/addmoney/entity/AddMoneyRequest.java`
- `services/backend/src/main/java/com/smartkash/addmoney/service/impl/AddMoneyRequestServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/admin/controller/AdminAddMoneyDecisionController.java` deleted
- `services/backend/src/main/java/com/smartkash/admin/dto/request/AdminAddMoneyDecisionRequest.java` deleted
- `services/backend/src/main/java/com/smartkash/admin/dto/response/AdminAddMoneyDecisionResponse.java` deleted
- `services/backend/src/main/java/com/smartkash/admin/service/AdminAddMoneyDecisionService.java` deleted
- `services/backend/src/main/java/com/smartkash/admin/service/impl/AdminAddMoneyDecisionServiceImpl.java` deleted

Flutter:

- `apps/mobile/lib/features/add_money/data/add_money_repository.dart`
- `apps/mobile/lib/features/add_money/domain/add_money_summary.dart`
- `apps/mobile/lib/features/add_money/presentation/add_money_screen.dart`
- `apps/mobile/lib/features/notification/presentation/notification_inbox_screen.dart`
- `apps/mobile/lib/features/transaction/domain/transaction_summary.dart`

Docs:

- `docs/product-plan.md`
- `docs/feature-spec.md`
- `docs/ui-screen-plan.md`
- `docs/backend-api-plan.md`
- `docs/database-plan.md`
- `docs/security-plan.md`
- `docs/admin-plan.md`
- `docs/notification-plan.md`
- `docs/development-roadmap.md`
- `docs/test-checklist.md`
- `docs/codex-progress.md`

Learning:

- `learning/step-66-instant-add-money-and-inbox-transactions.md`

## 5. Important backend snippets

### CreateAddMoneyRequest

```java
@NotBlank(message = "Idempotency key is required.")
@Size(max = 120, message = "Idempotency key must be 120 characters or less.")
String idempotencyKey,
```

ব্যাখ্যা:

- `@NotBlank`: Add Money request-এ idempotency key না থাকলে backend reject করবে।
- `@Size(max = 120)`: খুব বড় key পাঠালে validation fail হবে।
- `idempotencyKey`: একই button double tap বা network retry হলে duplicate wallet credit আটকাবে।

### Instant approval method

```java
public void completeInstantly() {
    this.status = AddMoneyStatus.APPROVED;
    this.approvedBy = null;
    this.approvedAt = Instant.now();
}
```

ব্যাখ্যা:

- `status = APPROVED`: Add Money row pending থাকবে না।
- `approvedBy = null`: কোনো admin approve করেনি, customer submit-ই complete করেছে।
- `approvedAt = Instant.now()`: record কখন complete হলো সেটা রাখা হয়।

### Wallet credit, transaction, ledger

```java
BigDecimal balanceAfter = wallet.credit(request.amount());
String transactionReference = uniqueTransactionReference();
TransactionRecord transaction = new TransactionRecord(
        transactionReference,
        user,
        TransactionType.ADD_MONEY,
        TransactionStatus.SUCCESS,
        request.amount(),
        null,
        "Instant Add Money from " + request.sourceType().name()
);
transactionRecordRepository.save(transaction);
ledgerEntryRepository.save(new LedgerEntry(
        wallet,
        user,
        transactionReference,
        null,
        LedgerEntryType.CREDIT,
        request.amount(),
        balanceAfter,
        "Instant Add Money wallet credit"
));
```

Block-by-block ব্যাখ্যা:

- `wallet.credit(...)`: wallet balance বাড়ায়।
- `uniqueTransactionReference()`: unique transaction ID তৈরি করে।
- `TransactionRecord`: user-facing transaction history তৈরি করে।
- `TransactionType.ADD_MONEY`: transaction type বলে দেয় এটা Add Money।
- `TransactionStatus.SUCCESS`: successful transaction।
- `LedgerEntryType.CREDIT`: ledger অনুযায়ী wallet-এ credit entry।
- `balanceAfter`: transaction-এর পরে wallet balance কত হলো সেটা ledger-এ থাকে।
- একই `transactionReference` transaction এবং ledger দুই জায়গায় link হিসেবে থাকে।

### Idempotency complete

```java
idempotencyKeyService.markCompleted(idempotencyKey, "ADD_MONEY:" + savedRequest.getId());
```

ব্যাখ্যা:

- request successful হলে idempotency record `COMPLETED` হয়।
- response body-তে Add Money record id রাখা হয়।
- same idempotency key আবার এলে backend পুরোনো record return করবে, নতুন credit করবে না।

## 6. Important Flutter snippets

### Add Money repository payload

```dart
data: {
  'amount': amount,
  'sourceType': sourceType,
  'idempotencyKey': idempotencyKey,
  if (note != null && note.isNotEmpty) 'note': note,
},
```

ব্যাখ্যা:

- `amount`: কত টাকা add হবে।
- `sourceType`: demo bank/card/manual source।
- `idempotencyKey`: duplicate submit prevent করে।
- `note`: optional reference note।

### Add Money success refresh

```dart
ref.read(walletRefreshProvider)();
ref.read(addMoneyRefreshProvider)();
ref.read(transactionRefreshProvider)();
```

ব্যাখ্যা:

- wallet refresh করলে Home balance update হবে।
- Add Money history refresh করলে recent top-ups update হবে।
- transaction refresh করলে Inbox > Transactions list update হবে।

### Inbox tab layout

```dart
_selectedTab == 0
    ? _TransactionInboxTab(...)
    : const _NotificationOffersTab()
```

ব্যাখ্যা:

- tab 0 হলে transaction history দেখায়।
- tab 1 হলে notifications/offers দেখায়।
- reference screenshot-এর মতো Inbox-এর ভিতরে দুইটা tab রাখা হয়েছে।

### Receipt bottom sheet

```dart
showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
  ),
  builder: (context) => _TransactionReceiptSheet(transaction: transaction),
);
```

ব্যাখ্যা:

- transaction row tap করলে bottom sheet open হয়।
- `isScrollControlled`: content বড় হলে scroll support করে।
- rounded top corner reference design-এর মতো receipt feel দেয়।
- `_TransactionReceiptSheet`: account/time/amount/charge/TrxID/reference দেখায়।

## 7. How this works in SmartKash flow

1. User login করে Home screen-এ যায়।
2. User Add Money open করে amount দেয়।
3. User source select করে `Add Money Now` tap করে।
4. Flutter backend-এ amount, source, idempotency key পাঠায়।
5. Backend active user এবং active wallet validate করে।
6. Backend wallet credit করে।
7. Backend transaction এবং ledger entry তৈরি করে।
8. Flutter wallet, Add Money history, transaction history refresh করে।
9. User Inbox > Transactions-এ transaction দেখতে পারে।
10. Row tap করলে receipt bottom sheet খুলে।

## 8. Common mistakes and cautions

- Same idempotency key different amount/source দিয়ে reuse করা যাবে না।
- Backend migration edit করা হয়নি, কারণ committed Flyway migration বদলালে local DB ভেঙে যেতে পারে।
- `add_money_requests` নামটা historical, কিন্তু current MVP-এ এটা Add Money/top-up record হিসেবে use হচ্ছে।
- Admin approval route active রাখা হয়নি; Add Money customer API থেকেই complete হয়।
- Real bank/payment gateway নেই, তাই এটা real money movement নয়।
- Flutter UI reference screenshot থেকে layout idea নিয়েছে, কিন্তু SmartKash color/branding আলাদা রাখা হয়েছে।

## 9. How to manually verify this step

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
mvn spring-boot:run
```

Flutter:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

App output check:

- Login করে Home screen-এ যান।
- Add Money খুলুন।
- Amount যেমন `500` দিন।
- Source select করুন।
- `Add Money Now` tap করুন।
- Expected output:
  - success snackbar দেখাবে।
  - recent Add Money list-এ success row দেখাবে।
  - Home balance refresh করলে balance বাড়বে।
  - Inbox > Transactions-এ `Add Money` row দেখাবে।
  - row tap করলে receipt bottom sheet খুলবে।

Database check:

```sql
SELECT id, amount, status, approved_by, approved_at
FROM add_money_requests
ORDER BY id DESC
LIMIT 5;

SELECT transaction_reference, type, status, amount
FROM transactions
ORDER BY id DESC
LIMIT 5;

SELECT transaction_reference, entry_type, amount, balance_after
FROM ledger_entries
ORDER BY id DESC
LIMIT 5;
```

Expected DB output:

- `add_money_requests.status` হবে `APPROVED`।
- `approved_by` null থাকতে পারে, কারণ admin approval নেই।
- `transactions.type` হবে `ADD_MONEY`।
- `ledger_entries.entry_type` হবে `CREDIT`।

## 10. Git commands used

```powershell
git status --short --branch
git diff --check
git add ...
git commit -m "step-66: make add money instant and polish inbox transactions"
git push
```

## 11. What I learned

এই step-এ শিখলাম কীভাবে একটা pending/admin approval flow-কে instant money-changing flow বানাতে হয়। Wallet balance direct update করলেও ledger entry এবং transaction record ছাড়া করা ঠিক নয়। Idempotency key duplicate credit prevent করে, আর Inbox transaction history user-এর জন্য clear receipt experience দেয়।
