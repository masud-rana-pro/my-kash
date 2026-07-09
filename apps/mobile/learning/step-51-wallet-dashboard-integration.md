# ধাপ ৫১: Wallet Home Dashboard Integration (Bangla Learning)

## কী করা হয়েছে

Home screen-এ real wallet balance, user phone number, এবং role দেখানোর জন্য API integration যোগ করা হয়েছে।

## নতুন ফাইল

### 1. `lib/features/wallet/domain/wallet_summary.dart`

Wallet data মডেল। Backend `WalletResponse` থেকে JSON parse করে:

- `id`, `userId`, `balance`, `currency`, `status`
- `balanceFormatted` getter: "১০০০.০০ BDT" ফরম্যাটে ব্যালেন্স দেখায়

### 2. `lib/features/wallet/data/wallet_repository.dart`

`GET /api/wallet/me` কল করে WalletSummary ফেরত দেয়। JWT টোকেন auto-attach হয় `ApiClient` interceptor-এর মাধ্যমে।

### 3. `lib/features/wallet/providers/wallet_providers.dart`

- `walletRepositoryProvider` — Repository provider
- `walletSummaryProvider` — `FutureProvider` যা ব্যালেন্স লোড করে
- `walletRefreshProvider` — Invalidate করে 새로 লোড করতে দেয়

### 4. `lib/features/home/presentation/home_screen.dart`

HomeScreen `ConsumerWidget` → `ConsumerStatefulWidget` এ পরিবর্তিত হয়েছে:

- `initState()`-এ `walletRefreshProvider` কল করে ব্যালেন্স লোড শুরু
- Header-এ `_BalancePanel` যোগ করা হয়েছে যা দেখায়:
  - Loading state: LinearProgressIndicator
  - Data state: "Available Balance" + বড় ফন্টে ব্যালেন্স
  - Error state: "Balance unavailable" text
- Header height 238 → 300 বাড়ানো হয়েছে ব্যালেন্স প্যানেলের জন্য

## ফ্লো

1. User login করে → Home screen opens
2. `_HomeScreenState.initState()` → `walletRefreshProvider()` → `walletSummaryProvider` → `WalletRepository.getMyWallet()` → `GET /api/wallet/me`
3. `WalletResponse` → `WalletSummary` parse → UI তে ব্যালেন্স দেখায়
4. Error হলে "Balance unavailable" দেখায়, loading হলে shimmer effect

## পরীক্ষা

- Login করার পর Home screen-এ ব্যালেন্স দেখাতে হবে
- যদি wallet না থাকে (new user), ০.০০ BDT দেখাবে
- Error handling ঠিক আছে কিনা পরীক্ষা করুন
