# Step 00: Planning Architecture Review

## 1. Step title

SmartKash planning architecture review.

## 2. কী update করা হয়েছে

এই step-এ কোনো Flutter, Spring Boot, database schema, migration, বা feature implementation code লেখা হয়নি। শুধু planning documents update করা হয়েছে, যাতে Step 01 শুরু করার আগে backend এবং frontend architecture পরিষ্কার থাকে।

Updated planning topics:

- Spring Boot backend dependencies
- Backend layered package structure
- Backend coding rules
- Required backend enums
- Flutter Riverpod architecture
- Flutter feature-first folder structure
- Money-changing operation safety rules
- Learning documentation rule reference
- Git/GitHub step workflow
- Progress tracking with `docs/codex-progress.md`

## 3. কেন layered backend architecture দরকার

Layered backend architecture দরকার কারণ wallet app-এ অনেক sensitive business rule থাকে। যেমন Send Money, Merchant Payment, Add Money approval, Savings deposit, Recharge এগুলো balance change করে। এই logic যদি controller, repository, entity সব জায়গায় ছড়িয়ে থাকে, তাহলে bug খুঁজে পাওয়া কঠিন হয় এবং duplicate transaction হওয়ার risk বাড়ে।

Layered architecture ব্যবহার করলে responsibility আলাদা থাকে:

- Controller request নেয় এবং response দেয়।
- Service business logic চালায়।
- Repository database access করে।
- Entity database table represent করে।
- DTO API request/response shape define করে।
- Mapper Entity ও DTO convert করে।
- Exception layer consistent error response দেয়।
- Security layer authentication, authorization, PIN, JWT, Firebase token verify করে।

## 4. DTO, Entity, Repository, Service, Controller কেন আলাদা

Controller সরাসরি Entity return করলে database structure API user-এর কাছে expose হয়ে যায়। পরে database field change করলে API breaking change হতে পারে। তাই DTO ব্যবহার করা দরকার।

Repository শুধু database query করবে। Repository-তে business rule থাকলে test করা কঠিন হয় এবং wallet logic ছড়িয়ে যায়।

Service layer business decision নেয়। যেমন sender balance আছে কিনা, PIN valid কিনা, idempotency key duplicate কিনা, ledger entry কীভাবে হবে - এসব service layer-এ থাকবে।

Entity database table-এর model। Entity API response না হয়ে persistence model হিসেবে থাকবে।

DTO frontend/backend contract। Flutter app কোন request পাঠাবে এবং কোন response পাবে, সেটা DTO দিয়ে clear হবে।

Mapper Entity থেকে DTO এবং DTO থেকে Entity conversion করবে। এতে controller/service clean থাকে।

## 5. Riverpod এবং feature-first Flutter structure কেন ব্যবহার করা হচ্ছে

Riverpod ব্যবহার করলে app state predictable ও testable হয়। Wallet balance, logged-in user, transaction list, loan status, notification state - এগুলো clean provider দিয়ে manage করা যায়।

Feature-first structure ব্যবহার করলে প্রতিটি feature আলাদা থাকে:

- `features/auth`
- `features/wallet`
- `features/send_money`
- `features/payment`
- `features/transactions`
- `features/savings`
- `features/loan`
- `features/recharge`
- `features/qr`

প্রতিটি feature-এ প্রয়োজন অনুযায়ী `data`, `domain`, `presentation`, `providers` folder থাকবে। এতে UI, API call, business model, state management এক জায়গায় গুলিয়ে যায় না।

## 6. Money-changing operation-এ transaction, locking, idempotency, audit log কেন দরকার

Money-changing operation হলো যেসব API wallet balance change করে। যেমন:

- Send Money
- Merchant Payment
- Add Money approval
- Savings deposit
- Mobile Recharge

এই operation-গুলোতে database transaction দরকার, কারণ debit success কিন্তু credit fail হলে balance mismatch হবে।

Safe locking দরকার, কারণ একই user একসাথে দুইটা transaction করলে balance ভুল হতে পারে। Optimistic locking বা অন্য safe strategy দিয়ে wallet update protect করতে হবে।

Idempotency দরকার, কারণ mobile app network retry করলে একই request দুইবার backend-এ যেতে পারে। একই idempotency key থাকলে backend duplicate transaction create করবে না।

Audit log দরকার, কারণ admin action এবং critical money operation trace করা দরকার। Learning MVP হলেও finance-style app বুঝতে audit trail গুরুত্বপূর্ণ।

## 7. কোন files create বা change হয়েছে

Updated planning files:

- `README.md`
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
- `docs/architecture-plan.md`
- `docs/codex-instructions.md`
- `docs/codex-progress.md`
- `learning/README.md`

Created learning file:

- `learning/step-00-planning-architecture-review.md`

## 8. Important planning snippets

Backend root package:

```text
com.smartkash
```

Example backend feature structure:

```text
com.smartkash.wallet.controller
com.smartkash.wallet.service
com.smartkash.wallet.service.impl
com.smartkash.wallet.repository
com.smartkash.wallet.entity
com.smartkash.wallet.dto.request
com.smartkash.wallet.dto.response
com.smartkash.wallet.mapper
com.smartkash.wallet.enums
```

Example Flutter feature structure:

```text
lib/features/send_money/data/
lib/features/send_money/domain/
lib/features/send_money/presentation/
lib/features/send_money/providers/
```

Money-changing API rule:

```text
Authenticated user + PIN + idempotency key + transaction boundary + safe wallet locking
```

Step workflow rule:

```text
git status -> review docs -> focused change -> learning note -> verify -> git status -> commit -> push -> summary
```

## 9. Bangla explanation of snippets

`com.smartkash` হলো backend root package। সব backend code এই namespace-এর নিচে থাকবে।

`controller` package request receive করবে। এখানে business logic রাখা যাবে না।

`service` package interface রাখবে। এতে controller নির্দিষ্ট implementation-এর উপর directly depend করবে না।

`service.impl` package actual business logic রাখবে।

`repository` package database access করবে।

`entity` package database table model রাখবে।

`dto.request` frontend থেকে আসা request body define করবে।

`dto.response` frontend-এ পাঠানো response body define করবে।

`mapper` entity ও DTO conversion করবে।

`enums` fixed status/type রাখবে। Java-তে `enum` keyword, তাই package name হিসেবে `enums` ব্যবহার করা হবে।

Flutter-এর `data` layer API/repository কাজ করবে। `domain` layer model/business concept রাখবে। `presentation` UI screen/widget রাখবে। `providers` Riverpod state রাখবে।

Step workflow snippet-টা বোঝায় যে প্রতিটি future implementation step শুরু হবে repo status check দিয়ে এবং শেষ হবে commit/push দিয়ে। এতে কাজ ছোট, traceable, এবং organized থাকবে।

## 10. SmartKash app flow-তে এই step কীভাবে কাজ করে

এই planning review future implementation-এর map হিসেবে কাজ করবে। Step 01-এ project setup করার সময় backend dependencies, package names, Flutter folders, Riverpod setup, environment rules, এবং learning note requirement আগে থেকেই clear থাকবে।

Send Money বা Payment implement করার সময় service layer balance validation করবে, repository database update করবে, ledger immutable entry তৈরি হবে, transaction record user statement-এ যাবে, আর idempotency duplicate request আটকাবে।

Git workflow update-এর কারণে Step 01 থেকে প্রতিটি কাজের progress `docs/codex-progress.md`-এ track হবে, learning note update হবে, তারপর commit এবং push করা হবে।

## 11. Common mistakes and cautions

- Controller-এ business logic লিখে ফেলা যাবে না।
- Entity সরাসরি API response হিসেবে return করা যাবে না।
- Flutter widget-এর ভিতরে API call লেখা যাবে না।
- PIN Flutter app-এ store করা যাবে না।
- Ledger entry update/delete করা যাবে না।
- Money-changing API idempotency ছাড়া implement করা যাবে না।
- Admin API `ADMIN` role ছাড়া accessible করা যাবে না।
- Java package হিসেবে `enum` ব্যবহার করা যাবে না; `enums` ব্যবহার করতে হবে।
- Commit না করে বা push না করে implementation step শেষ করা যাবে না।
- `docs/codex-progress.md` update করা ভুলে গেলে project context হারানোর risk থাকবে।

## 12. কীভাবে test করতে হবে

এই planning step-এর জন্য manual verification:

- Docs-এ Spring Boot dependencies আছে কিনা check করতে হবে।
- Backend package structure `com.smartkash` দিয়ে আছে কিনা check করতে হবে।
- Flutter folder structure এবং Riverpod mention আছে কিনা check করতে হবে।
- Wallet transaction, locking, idempotency, audit log rules আছে কিনা check করতে হবে।
- Learning rule এখনও `docs/codex-instructions.md` এবং `learning/README.md`-এ আছে কিনা check করতে হবে।
- Git/GitHub workflow rules `docs/codex-instructions.md`, `docs/development-roadmap.md`, এবং `README.md`-এ আছে কিনা check করতে হবে।
- `docs/codex-progress.md` তৈরি হয়েছে কিনা check করতে হবে।

## 13. এই step থেকে কী শিখলাম

এই step থেকে শিখলাম যে বড় app শুরু করার আগে architecture plan clear করা জরুরি। Backend-এ layer আলাদা রাখলে code maintain করা সহজ হয়। Flutter-এ feature-first structure app বড় হলেও organized রাখে। Wallet app-এ transaction, locking, idempotency, immutable ledger, এবং audit log না থাকলে balance ভুল হওয়ার risk থাকে। Git workflow এবং progress tracking থাকলে প্রতিটি step history সহ পরিষ্কারভাবে follow করা যায়।
