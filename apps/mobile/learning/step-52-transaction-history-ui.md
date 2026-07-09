# ধাপ ৫২: Transaction History UI (Bangla Learning)

## কী করা হয়েছে

ব্যবহারকারীর লেনদেন ইতিহাস দেখানোর জন্য সম্পূর্ণ UI তৈরি করা হয়েছে — তালিকা ও বিস্তারিত ভিউ।

## নতুন ফাইল

### 1. `lib/features/transaction/domain/transaction_summary.dart`

Backend `TransactionResponse` থেকে JSON parse করে:

- `id`, `transactionReference`, `type`, `status`, `amount`
- `counterpartyUserId`, `counterpartyMobileNumber`, `description`, `createdAt`
- Helper getters: `typeLabel` (বাংলা লেবেল), `statusLabel`, `isCredit`/`isDebit`, `amountFormatted` (+৳ বা -৳), `formattedDate` (relative time)

### 2. `lib/features/transaction/data/transaction_repository.dart`

- `getMyTransactions()` → `GET /api/transactions` → `List<TransactionSummary>`
- `getTransactionDetail(id)` → `GET /api/transactions/{id}` → `TransactionSummary`

### 3. `lib/features/transaction/providers/transaction_providers.dart`

- `transactionRepositoryProvider` — Repository provider
- `transactionListProvider` — `FutureProvider` লেনদেন তালিকা লোড করে
- `transactionDetailProvider` — `FutureProvider.family` নির্দিষ্ট লেনদেনের বিস্তারিত লোড করে
- `transactionRefreshProvider` — Invalidate করে রিফ্রেশ করতে দেয়

### 4. `lib/features/transaction/presentation/transaction_list_screen.dart`

- Pull-to-refresh সহ লেনদেন তালিকা
- প্রতিটি টাইপের জন্য আলাদা আইকন ও রঙ (Send Money=green, Add Money=purple, ইত্যাদি)
- Empty state: "No transactions yet"
- Error state: "Could not load transactions" + Try Again
- Loading state: CircularProgressIndicator
- Status badge: Success=green, Pending=amber, Failed/Rejected=red

### 5. `lib/features/transaction/presentation/transaction_detail_screen.dart`

- বড় amount দেখায় (credit/debit অনুযায়ী রঙ)
- Status, Reference, Date, Counterparty, Description দেখায়
- White card design with shadow

### 6. `lib/app/router/app_router.dart`

- `/transactions` → `TransactionListScreen`
- `/transactions/:id` → `TransactionDetailScreen`

## ফ্লো

1. User Home screen থেকে "See More" বা অন্য কোথাও থেকে `/transactions` এ যায়
2. `TransactionListScreen.initState()` → `transactionRefreshProvider()` → API কল
3. ListView-এ প্রতিটি transaction দেখায়
4. Tap করলে `/transactions/{id}` → `TransactionDetailScreen`
5. Pull-to-refresh করলে নতুন করে লোড হয়

## পরীক্ষা

- Transaction list correctly loads from backend
- Each type shows correct icon and color
- Detail screen shows all fields
- Pull-to-refresh works
- Empty state shows when no transactions
