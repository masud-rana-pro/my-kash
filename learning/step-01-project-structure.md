# Step 01: SmartKash Project Structure

## 1. Step title

Step 01: SmartKash root project structure তৈরি।

## 2. কী implement করা হয়েছে

এই step-এ শুধু root-level project structure তৈরি করা হয়েছে। কোনো Flutter app generate করা হয়নি, কোনো Spring Boot project generate করা হয়নি, কোনো database schema, migration, Firebase Auth, API, wallet, transaction, বা business feature implement করা হয়নি।

এই step-এ তৈরি করা হয়েছে:

- `apps/mobile/` - future Flutter Android-first app রাখার জায়গা
- `services/backend/` - future Spring Boot backend রাখার জায়গা
- `scripts/` - helper scripts রাখার জায়গা
- `.gitignore` - secrets, build output, IDE files, logs, Flutter/Java generated files ignore করার rule
- `.gitkeep` placeholder files - empty folders Git-এ রাখার জন্য
- `docs/codex-progress.md` update
- এই Bangla learning file

## 3. কেন এই step দরকার

SmartKash project-এ frontend, backend, docs, learning notes, এবং helper scripts আলাদা রাখা দরকার। শুরুতেই structure পরিষ্কার করলে পরে Flutter code, Spring Boot code, PostgreSQL/Flyway setup, Firebase test OTP setup, admin panel, এবং learning notes একসাথে গুলিয়ে যাবে না।

এই structure future step-গুলোকে ছোট এবং focused রাখতে সাহায্য করবে:

- Step 02-তে Flutter app skeleton শুধু `apps/mobile/`-এ যাবে।
- Step 03-তে Spring Boot backend skeleton শুধু `services/backend/`-এ যাবে।
- Future helper scripts `scripts/`-এ যাবে।
- Planning docs `docs/`-এ থাকবে।
- Bangla learning docs `learning/`-এ থাকবে।

## 4. Final folder structure

```text
SmartKash repository
├── apps/
│   └── mobile/
│       └── .gitkeep
├── services/
│   └── backend/
│       └── .gitkeep
├── docs/
│   ├── architecture-plan.md
│   ├── backend-api-plan.md
│   ├── codex-instructions.md
│   ├── codex-progress.md
│   └── ...
├── learning/
│   ├── README.md
│   ├── step-00-planning-architecture-review.md
│   └── step-01-project-structure.md
├── scripts/
│   └── .gitkeep
├── .env.example
├── .gitignore
└── README.md
```

## 5. Files/folders created or changed

Created:

- `.gitignore`
- `apps/mobile/.gitkeep`
- `services/backend/.gitkeep`
- `scripts/.gitkeep`
- `learning/step-01-project-structure.md`

Changed:

- `docs/codex-progress.md`

## 6. Important snippets created in this step

### Root app/service folders

```text
apps/mobile/
services/backend/
scripts/
```

### Placeholder files

```text
apps/mobile/.gitkeep
services/backend/.gitkeep
scripts/.gitkeep
```

### `.gitignore` secrets section

```gitignore
# Environment and secrets
.env
.env.*
!.env.example
firebase-service-account*.json
serviceAccountKey.json
google-services.json
GoogleService-Info.plist
*.pem
*.key
```

### `.gitignore` Flutter section

```gitignore
# Flutter and Dart
.dart_tool/
.packages
.flutter-plugins
.flutter-plugins-dependencies
build/
coverage/
apps/mobile/.dart_tool/
apps/mobile/build/
apps/mobile/android/.gradle/
apps/mobile/android/local.properties
apps/mobile/ios/Pods/
apps/mobile/ios/.symlinks/
apps/mobile/ios/Flutter/Flutter.framework
apps/mobile/ios/Flutter/Flutter.podspec
```

### `.gitignore` Java/Maven section

```gitignore
# Java, Maven, and Spring Boot
target/
*.class
*.jar
*.war
*.ear
services/backend/target/
services/backend/.mvn/wrapper/maven-wrapper.jar
```

## 7. Snippet explanation: line-by-line বা block-by-block

### Root folders explanation

```text
apps/mobile/
```

এই folder future Flutter Android-first mobile app-এর জন্য। Flutter app generate করলে `lib/`, `android/`, `pubspec.yaml` ইত্যাদি এই folder-এর ভিতরে থাকবে।

```text
services/backend/
```

এই folder future Spring Boot backend-এর জন্য। Spring Boot app generate করলে `src/main/java/com/smartkash`, `pom.xml`, `src/main/resources` ইত্যাদি এই folder-এর ভিতরে থাকবে।

```text
scripts/
```

এই folder helper scripts রাখার জন্য। Future-এ setup, verification, local helper command, বা developer utility script দরকার হলে এখানে রাখা যাবে।

### Placeholder explanation

```text
.gitkeep
```

Git empty folder track করে না। তাই empty folder রাখতে `.gitkeep` placeholder ব্যবহার করা হয়েছে। পরে যখন actual Flutter বা Spring Boot files আসবে, `.gitkeep` রাখা বা remove করা যাবে।

### Secrets section explanation

```gitignore
.env
.env.*
```

Local environment file ignore করে, যাতে real database password, JWT secret, Firebase secret commit না হয়।

```gitignore
!.env.example
```

`.env.example` commit করা যাবে, কারণ এতে real secret থাকে না; এটা শুধু template।

```gitignore
firebase-service-account*.json
serviceAccountKey.json
google-services.json
GoogleService-Info.plist
```

Firebase service account এবং platform config file accidentally commit হওয়া আটকায়। SmartKash MVP Firebase test OTP/FCM ব্যবহার করবে, কিন্তু secret files GitHub-এ রাখা যাবে না।

```gitignore
*.pem
*.key
```

Private key বা certificate file commit হওয়া আটকায়।

### Flutter section explanation

```gitignore
.dart_tool/
build/
coverage/
```

Flutter/Dart generated cache, build output, এবং coverage output ignore করে। এগুলো source code না।

```gitignore
apps/mobile/android/local.properties
```

Android local SDK path থাকে, যা machine-specific। এটা commit করলে অন্য developer-এর machine-এ mismatch হবে।

```gitignore
apps/mobile/ios/Pods/
apps/mobile/ios/.symlinks/
```

iOS dependency/generated files ignore করে। যদিও app Android-first, future iOS support রাখলে এগুলো useful হবে।

### Java/Maven section explanation

```gitignore
target/
services/backend/target/
```

Maven build output ignore করে। Spring Boot build করলে compiled files `target/`-এ যায়।

```gitignore
*.class
*.jar
*.war
*.ear
```

Compiled Java artifacts ignore করে। এগুলো source code না, build command দিয়ে আবার generate করা যায়।

```gitignore
services/backend/.mvn/wrapper/maven-wrapper.jar
```

Maven wrapper jar generated binary হিসেবে ignore করা হয়েছে। Future Step 03-এ wrapper strategy final করলে দরকার হলে এই rule revisit করা যাবে।

## 8. SmartKash project flow-তে এই structure কীভাবে কাজ করে

SmartKash flow হবে:

1. Flutter app `apps/mobile/` থেকে user login, wallet, Send Money, QR, Payment, Savings, Recharge UI চালাবে।
2. Flutter app Spring Boot API call করবে।
3. Spring Boot backend `services/backend/` থেকে auth, wallet, ledger, transaction, admin logic চালাবে।
4. PostgreSQL backend-এর main business database হবে।
5. Firebase Phone Auth test OTP এবং FCM backend/mobile integration future step-এ configure হবে।
6. Admin panel Spring Boot backend-এর অংশ হিসেবে future step-এ থাকবে।
7. প্রতিটি implementation step-এর Bangla explanation `learning/` folder-এ থাকবে।
8. Helper scripts future-এ `scripts/` folder থেকে run করা যাবে।

এই step foundation তৈরি করেছে, যেন future implementation clean জায়গায় বসানো যায়।

## 9. Common mistakes and cautions

- এই step-এ Flutter project generate করা যাবে না, কারণ scope শুধু structure।
- Spring Boot skeleton বা `pom.xml` এই step-এ তৈরি করা যাবে না।
- Database migration বা schema তৈরি করা যাবে না।
- Firebase config বা real service account file commit করা যাবে না।
- `.env` file commit করা যাবে না।
- `.gitkeep` placeholder-কে business code ভাবা যাবে না; এটি শুধু empty folder track করার জন্য।
- `.gitignore`-এ `.env.example` ignore করা যাবে না, কারণ এটি safe template।

## 10. কীভাবে verify করতে হবে

এই step verify করার জন্য commands:

```powershell
git status --short
```

কোন files changed/staged আছে তা দেখায়।

```powershell
Test-Path apps/mobile/.gitkeep
Test-Path services/backend/.gitkeep
Test-Path scripts/.gitkeep
Test-Path .gitignore
Test-Path learning/step-01-project-structure.md
```

প্রতিটি expected file/folder আছে কিনা check করে।

```powershell
rg "apps/mobile|services/backend|firebase-service-account|target/|.env" .gitignore learning/step-01-project-structure.md docs/codex-progress.md
```

`.gitignore`, learning note, এবং progress file-এ important Step 01 references আছে কিনা check করে।

## 11. Git commands used in this step

```powershell
git status --short
git add .gitignore apps services scripts docs/codex-progress.md learning/step-01-project-structure.md
git commit -m "step-01: add project structure"
git push
git log -1 --oneline
```

এই commands দিয়ে status check, changes stage, commit, GitHub push, এবং final commit verify করা হয়েছে বা হবে।

## 12. What I learned from this step

এই step থেকে শিখলাম যে বড় project শুরু করার আগে root structure ঠিক করা খুব গুরুত্বপূর্ণ। Flutter app, Spring Boot backend, scripts, docs, এবং learning notes আলাদা রাখলে project maintain করা সহজ হয়। `.gitignore` secrets ও generated files protect করে। `.gitkeep` empty folder Git-এ রাখতে সাহায্য করে। SmartKash-এর future implementation এখন clean foundation-এর উপর করা যাবে।

