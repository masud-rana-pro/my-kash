# Step 59: Loan Request UI

## 1. Step title

Step 59-এ SmartKash Flutter app-এ Loan request/status UI তৈরি করা হয়েছে।

## 2. কী implement করা হয়েছে

- Home screen-এর `Loan` action এখন Loan screen খুলে।
- Loan amount এবং purpose দিয়ে request submit করার form যোগ করা হয়েছে।
- Existing backend `POST /api/loans/requests` API call করা হয়েছে।
- Existing backend `GET /api/loans/requests` দিয়ে current user-এর loan requests list দেখানো হয়েছে।
- Loan status `PENDING`, `APPROVED`, `REJECTED` UI-তে আলাদা রঙে দেখানো হয়েছে।

## 3. কেন এই step দরকার

Backend-এ loan request foundation আগে তৈরি ছিল। কিন্তু Flutter UI না থাকলে user app থেকে loan request submit বা status দেখতে পারত না। এই step loan feature-এর MVP Phase 1 user-facing flow যুক্ত করেছে।

## 4. কোন files/folders change হয়েছে

- `apps/mobile/lib/features/loan/data/loan_repository.dart`
- `apps/mobile/lib/features/loan/domain/loan_request_summary.dart`
- `apps/mobile/lib/features/loan/providers/loan_providers.dart`
- `apps/mobile/lib/features/loan/presentation/loan_screen.dart`
- `apps/mobile/lib/app/router/app_router.dart`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-59-loan-request-ui.md`

## 5. Important code snippets

```dart
Future<LoanRequestSummary> createRequest({
  required double amount,
  required String purpose,
}) async {
  final response = await _apiClient.post<Map<String, dynamic>>(
    '/api/loans/requests',
    data: {
      'amount': amount,
      'purpose': purpose,
    },
  );

  return LoanRequestSummary.fromJson(response.data ?? const {});
}
```

Block-by-block ব্যাখ্যা:

- `createRequest`: backend-এ loan request create করে।
- `amount`: user যে loan amount চাইছে।
- `purpose`: কেন loan দরকার সেটার কারণ।
- `_apiClient.post`: centralized API client ব্যবহার হয়, তাই backend JWT automatically attach হয়।
- `LoanRequestSummary.fromJson`: backend response model class-এ convert করে।

```dart
Future<List<LoanRequestSummary>> getMyRequests() async {
  final response = await _apiClient.get<List<dynamic>>('/api/loans/requests');
  final data = response.data ?? const [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(LoanRequestSummary.fromJson)
      .toList();
}
```

ব্যাখ্যা:

- `GET /api/loans/requests` current authenticated user-এর loan request list দেয়।
- `whereType<Map<String, dynamic>>()` list-এর JSON object গুলো নেয়।
- প্রতিটি JSON `LoanRequestSummary` model-এ convert হয়।

```dart
final statusColor = switch (request.status) {
  'APPROVED' => const Color(0xFF2E7D32),
  'REJECTED' => const Color(0xFFC62828),
  _ => const Color(0xFFE08B2D),
};
```

ব্যাখ্যা:

- `APPROVED` হলে green।
- `REJECTED` হলে red।
- অন্য status, যেমন `PENDING`, হলে amber।
- এতে user দ্রুত status বুঝতে পারে।

## 6. SmartKash flow-তে কীভাবে কাজ করে

1. User Home থেকে `Loan` চাপবে।
2. Loan screen খুলবে।
3. User amount এবং purpose লিখে request submit করবে।
4. Backend `loan_requests` table-এ `PENDING` request তৈরি করবে।
5. Flutter list refresh করে নতুন request দেখাবে।
6. Admin পরে approve/reject করলে status update হবে।

## 7. Loan MVP Phase 1 scope

এই step এবং current backend loan flow status-only। এখানে কোনো wallet credit/disbursement, repayment, installment, interest calculation, বা loan schedule নেই। Approval/rejection শুধু status update করে। এটা project plan-এর সাথে মিলেছে।

## 8. Common mistakes and cautions

- Loan approval মানেই wallet credit নয়।
- Loan request UI money-changing screen না, তাই PIN/idempotency লাগছে না।
- Disbursement future step হলে আলাদা money-changing flow হবে।
- Purpose empty হলে backend validation error আসবে।
- Local `.env` বা `application-local.yml` commit করা যাবে না।

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
SELECT id, user_id, amount, purpose, status, reviewed_at, created_at FROM loan_requests ORDER BY id DESC LIMIT 10;
```

Expected output:

- Home থেকে Loan screen খুলবে।
- Amount + purpose submit করলে success message দেখাবে।
- New request list-এ `PENDING` status সহ দেখা যাবে।
- Database-এ নতুন `loan_requests` row তৈরি হবে।
- Wallet balance change হবে না।

## 10. Git commands used

```powershell
git status --short --branch
dart format <step-59-dart-files>
git diff --check
git add <step-59-files>
git commit -m "step-59: add loan request UI"
git push
```

## 11. কী শিখলাম

Loan request feature status-tracking flow। এটা wallet money-changing flow না, তাই Send Money/Recharge/Savings Deposit-এর মতো PIN, ledger, idempotency লাগে না। ভবিষ্যতে disbursement যোগ করলে সেটা আলাদা safe money-changing step হবে।
