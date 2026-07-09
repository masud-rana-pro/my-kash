# ধাপ ৫৪: Send Money UI (Bangla Learning)

## কী করা হয়েছে

ব্যবহারকারী Send Money ফ্লো সম্পূর্ণ করতে পারে: receiver খুঁজা, amount নির্ধারণ, PIN নিশ্চিতকরণ, এবং ফলাফল দেখা। Idempotency key auto-generate হয়।

## নতুন ফাইল

### `lib/features/send_money/domain/send_money_receiver.dart`

দুটি মডেল:

- `SendMoneyReceiver` — Backend `SendMoneyReceiverResponse` থেকে parse করে: `userId`, `mobileNumber`, `displayName`, `role`, `userStatus`, `walletStatus`. `isValid` getter চেক করে user ও wallet active কিনা।
- `SendMoneyResult` — Backend `SendMoneyTransferResponse` থেকে parse করে: `success`, `message`, `transactionReference`, `status`, `amount`, `senderBalanceAfter`, `receiverUserId`, `receiverMobileNumber`, `createdAt`।

### `lib/features/send_money/data/send_money_repository.dart`

- `resolveReceiver(mobileNumber)` → `POST /api/send-money/resolve-receiver`
- `sendMoney(amount, pin, note)` → `POST /api/send-money` (auto-generates idempotency key)

### `lib/features/send_money/providers/send_money_providers.dart`

- `sendMoneyRepositoryProvider`

### `lib/features/send_money/presentation/send_money_screen.dart`

৪-স্টেপ ফ্লো উইজার্ড:

1. **Receiver Step**: Mobile number input → "Find Receiver" button → API call
2. **Amount Step**: Receiver info card (name, number, active status) + Amount field + Note field
3. **PIN Step**: "Confirm with PIN" → 5-digit PIN input → "Send Money" button
4. **Result Step**: Success/fail icon + message + details (amount, receiver, reference, new balance) + "Send Again" button

### `lib/app/router/app_router.dart`

- `/send-money` → `SendMoneyScreen`

## ফ্লো

1. User "Send Money" tile tap → `/send-money`
2. Enter receiver phone → "Find Receiver" → API validate
3. See receiver details → Enter amount + note → Next
4. Enter 5-digit PIN → "Send Money" → API executes transfer
5. Success: "Money Sent!" with details + new balance. Fail: "Transfer Failed" with message
6. "Send Again" → resets to step 1

## পরীক্ষা

- Valid receiver → shows receiver info
- Invalid receiver → error message
- Insufficient balance → API returns error
- Invalid PIN → PIN verification failed message
- Success → shows reference + new balance
