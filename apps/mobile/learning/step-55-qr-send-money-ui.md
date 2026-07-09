# ধাপ ৫৫: QR Send Money Foundation UI (Bangla Learning)

## কী করা হয়েছে

QR Payload ফাউন্ডেশন তৈরি করা হয়েছে: ব্যবহারকারী তার নিজের QR payload (SMARTKASH_USER: ফরম্যাটে) দেখতে এবং কপি করতে পারে, এবং অন্য কারো QR payload পেস্ট করে Send Money স্ক্রিনে যেতে পারে।

## নতুন ফাইল

### `lib/features/qr/domain/qr_payload.dart`

- `QrPayload` ক্লাস: `mobileNumber` থেকে `SMARTKASH_USER:{number}` ফরম্যাটের payload তৈরি করে
- `extractMobileNumber(payload)`: payload থেকে mobile number বের করে
- `isValid(payload)`: payload valid কিনা চেক করে

### `lib/features/qr/presentation/qr_screen.dart`

দুটি অংশ:

1. **My QR Payload**: ব্যবহারকারীর নিজের payload দেখায়, copy button দেয়
2. **Enter Sender QR Payload**: Text field + "Send Money to this QR" button, পেস্ট করা payload validate করে Send Money স্ক্রিনে redirect করে

### `lib/app/router/app_router.dart`

- `/qr` → `QrScreen`

## ফ্লো

1. User Bottom Nav থেকে Scan QR তে যায় → `/qr`
2. নিজের payload দেখে এবং কপি করে
3. অথবা অন্য কারো payload পেস্ট করে → validate → Send Money স্ক্রিনে যায়
4. Camera QR scan (optional, Step 62+ এ যোগ হবে)

## পরীক্ষা

- Copy button কাজ করে
- Invalid payload → error message
- Valid payload → redirects to send money
