# ধাপ ৫৩: Add Money UI (Bangla Learning)

## কী করা হয়েছে

ব্যবহারকারী Add Money request তৈরি করতে এবং তার পূর্বের requests দেখতে পারে। Admin approval প্রয়োজন (backend already আছে)।

## নতুন ফাইল

### `lib/features/add_money/domain/add_money_summary.dart`

Backend `AddMoneyRequestResponse` থেকে JSON parse করে:

- `id`, `amount`, `sourceType`, `status`, `note`, `approvedAt`, `createdAt`
- `sourceLabel`: DEMO_BANK=Bank Transfer, DEMO_CARD=Card, MANUAL=Manual Deposit
- `statusLabel`: Pending, Approved, Rejected
- Booleans: `isApproved`, `isRejected`, `isPending`

### `lib/features/add_money/data/add_money_repository.dart`

- `createRequest(amount, sourceType, note)` → `POST /api/add-money/requests`
- `getMyRequests()` → `GET /api/add-money/requests`

### `lib/features/add_money/providers/add_money_providers.dart`

- `addMoneyRepositoryProvider`, `addMoneyRequestsProvider`, `addMoneyRefreshProvider`

### `lib/features/add_money/presentation/add_money_screen.dart`

- Amount input field with ৳ prefix
- Source dropdown (Bank Transfer, Card, Manual Deposit)
- Optional note field
- Submit button with loading state
- "My Requests" section showing all past requests with status badges

### `lib/app/router/app_router.dart`

- `/add-money` → `AddMoneyScreen`

## ফ্লো

1. User Add Money tile tap করে → `/add-money`
2. Amount, source, note fill করে → Submit
3. Backend request creates → "submitted for admin approval" message
4. Requests list auto-refreshes → new entry shows as Pending
5. Admin approve করলে status Approved হয়

## পরীক্ষা

- Submit empty amount → validation error
- Submit valid request → success message
- List shows all past requests with correct status
