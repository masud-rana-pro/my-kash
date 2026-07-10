# Step 58: Savings Goal UI

## 1. Step title

Step 58-এ SmartKash Flutter app-এ Savings Goal UI তৈরি করা হয়েছে।

## 2. কী implement করা হয়েছে

- Home screen-এর `Savings` action এখন Savings screen খুলে।
- Savings goal create form যোগ করা হয়েছে।
- Existing backend `GET /api/savings/goals` দিয়ে goal list দেখানো হয়েছে।
- Goal progress card যোগ করা হয়েছে।
- Existing backend `POST /api/savings/goals/{goalId}/deposit` দিয়ে wallet-debit savings deposit যুক্ত করা হয়েছে।
- Deposit করার সময় PIN এবং idempotency key পাঠানো হয়েছে।
- Deposit success হলে wallet balance এবং savings goal list refresh করা হয়েছে।

## 3. কেন এই step দরকার

Backend-এ savings goal foundation এবং deposit flow আগে থেকেই ছিল। কিন্তু Flutter UI না থাকলে user app থেকে goal create বা deposit করতে পারত না। এই step frontend থেকে backend savings flow ব্যবহারযোগ্য করেছে।

## 4. কোন files/folders change হয়েছে

- `apps/mobile/lib/features/savings/data/savings_repository.dart`
- `apps/mobile/lib/features/savings/domain/savings_goal.dart`
- `apps/mobile/lib/features/savings/domain/savings_deposit_result.dart`
- `apps/mobile/lib/features/savings/providers/savings_providers.dart`
- `apps/mobile/lib/features/savings/presentation/savings_screen.dart`
- `apps/mobile/lib/app/router/app_router.dart`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-58-savings-goal-ui.md`

## 5. Important code snippets

```dart
Future<SavingsGoal> createGoal({
  required String name,
  required double targetAmount,
  DateTime? targetDate,
}) async {
  final response = await _apiClient.post<Map<String, dynamic>>(
    '/api/savings/goals',
    data: {
      'name': name,
      'targetAmount': targetAmount,
      if (targetDate != null)
        'targetDate': targetDate.toIso8601String().substring(0, 10),
    },
  );

  return SavingsGoal.fromJson(response.data ?? const {});
}
```

Block-by-block ব্যাখ্যা:

- `createGoal`: backend-এ নতুন savings goal create করে।
- `name`: goal-এর নাম।
- `targetAmount`: goal target amount।
- `targetDate`: optional future date; backend `LocalDate` নেয়, তাই `YYYY-MM-DD` পাঠানো হয়।
- `_apiClient.post`: centralized API client JWT token attach করে।
- `SavingsGoal.fromJson`: backend response model class-এ convert করে।

```dart
Future<SavingsDepositResult> deposit({
  required int goalId,
  required double amount,
  required String pin,
  required String idempotencyKey,
  String? note,
}) async {
  final response = await _apiClient.post<Map<String, dynamic>>(
    '/api/savings/goals/$goalId/deposit',
    data: {
      'amount': amount,
      'pin': pin,
      'idempotencyKey': idempotencyKey,
      if (note != null && note.isNotEmpty) 'note': note,
    },
  );

  return SavingsDepositResult.fromJson(response.data ?? const {});
}
```

Block-by-block ব্যাখ্যা:

- `goalId`: কোন savings goal-এ deposit হবে।
- `amount`: wallet থেকে debit হয়ে savings goal current amount-এ যোগ হবে।
- `pin`: Flutter store করে না; শুধু backend confirmation request-এ যায়।
- `idempotencyKey`: duplicate deposit ঠেকানোর জন্য required।
- `note`: optional note।
- Backend PIN verify, wallet debit, transaction, ledger, idempotency সব handle করে।

```dart
double get progress {
  if (targetAmount <= 0) {
    return 0;
  }
  return (currentAmount / targetAmount).clamp(0, 1);
}
```

ব্যাখ্যা:

- `progress` UI progress bar-এর value।
- target amount invalid হলে 0 return করে।
- `clamp(0, 1)` progress bar-এর value 0 থেকে 1-এর মধ্যে রাখে।

```dart
ref.read(walletRefreshProvider)();
ref.read(savingsRefreshProvider)();
```

ব্যাখ্যা:

- Savings deposit wallet balance কমায়।
- তাই wallet provider refresh করা হয়।
- Goal current amount update হয়, তাই savings list refresh করা হয়।

## 6. SmartKash flow-তে কীভাবে কাজ করে

1. User Home থেকে `Savings` চাপবে।
2. Savings screen খুলবে।
3. User goal name, target amount, optional target date দিয়ে goal create করবে।
4. Goal list-এ new goal দেখা যাবে।
5. User active goal select করে deposit amount, PIN, note দেবে।
6. Flutter backend deposit API call করবে।
7. Backend PIN verify করবে, wallet debit করবে, savings goal amount update করবে, transaction/ledger/idempotency record তৈরি করবে।
8. Flutter wallet এবং savings list refresh করবে।

## 7. কেন goal create আর deposit আলাদা

Goal create করলে শুধু target তৈরি হয়, wallet balance change হয় না। Deposit money-changing operation, তাই এতে PIN, idempotency, wallet lock, transaction record, এবং ledger entry লাগে।

## 8. Common mistakes and cautions

- Goal create-কে wallet transaction ভাবা যাবে না।
- Deposit-এর idempotency key retry-তে বদলালে duplicate debit হতে পারে।
- PIN Flutter local storage-এ রাখা যাবে না।
- Target date backend future date চায়; old date দিলে validation error আসবে।
- Savings withdrawal/profit/interest এই step-এর scope না।

## 9. Manual verification commands

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
.\mvnw.cmd spring-boot:run
```

Flutter:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

Database check:

```sql
SELECT id, name, target_amount, current_amount, status, target_date FROM savings_goals ORDER BY id DESC LIMIT 10;
SELECT transaction_reference, type, status, amount FROM transactions ORDER BY id DESC LIMIT 10;
SELECT transaction_reference, entry_type, amount, balance_after FROM ledger_entries ORDER BY id DESC LIMIT 10;
SELECT idempotency_key, operation_type, status FROM idempotency_keys ORDER BY id DESC LIMIT 10;
```

Expected output:

- Home থেকে Savings screen খুলবে।
- Goal create করলে list-এ goal দেখা যাবে।
- Deposit করলে goal progress/current amount বাড়বে।
- Wallet balance কমবে।
- Database-এ savings goal update, transaction, ledger, idempotency completed record দেখা যাবে।

## 10. Git commands used

```powershell
git status --short --branch
dart format <step-58-dart-files>
git diff --check
git add <step-58-files>
git commit -m "step-58: add savings goal UI"
git push
```

## 11. কী শিখলাম

Savings feature-এ create goal এবং deposit আলাদা responsibility। Goal create simple API call, কিন্তু deposit money-changing flow হওয়ায় PIN, idempotency, wallet refresh, goal refresh, transaction, এবং ledger সব মাথায় রাখতে হয়।
