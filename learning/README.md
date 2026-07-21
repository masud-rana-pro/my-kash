# SmartKash শেখার নোট

এই `learning/` folder-এ SmartKash project তৈরি করার আগের ধাপগুলোর বাংলা learning note রাখা হয়েছে।

এই নোটগুলোর উদ্দেশ্য হলো project-এর code, config, folder structure, backend flow, Flutter flow, database design, security, wallet/ledger logic, Firebase setup, এবং Git workflow ধাপে ধাপে বোঝা।

## বর্তমান নিয়ম

Project-এর আগের workflow অনুযায়ী প্রতিটি implementation step-এর জন্য বাংলা learning file তৈরি বা update করা হতো।

User পরে বলেছেন এখন থেকে নতুন learning file তৈরি বা update করার দরকার নেই, তাই বর্তমান development-এ learning file বাধ্যতামূলক নয়। তবে প্রয়োজন হলে বা user চাইলে নতুন learning note যোগ করা যেতে পারে।

## File Naming Format

```text
learning/step-XX-topic-name.md
```

Examples:

```text
learning/step-01-project-structure.md
learning/step-02-flutter-app-skeleton.md
learning/step-03-spring-boot-backend-skeleton.md
learning/step-07-user-profile-database-foundation.md
```

## একটি ভালো Learning File-এ যা থাকা উচিত

1. Step title
2. কী implement করা হয়েছে
3. কেন এই step দরকার
4. কোন files/folders/classes/config তৈরি বা পরিবর্তন হয়েছে
5. Important code snippets
6. Important config snippets
7. Code/config-এর বাংলা explanation
8. প্রতিটি গুরুত্বপূর্ণ file/folder/class/config কেন আছে
9. SmartKash app flow-তে এই step কীভাবে connect করে
10. Common mistakes and cautions
11. কীভাবে test বা verify করতে হবে
12. Git commands used
13. কী শেখা হলো তার short summary

## Manual Verification Workflow

Execution limit এবং সময় বাঁচানোর জন্য heavy verification command সবসময় Codex থেকে চালানো হয় না।

User চাইলে locally run করবে:

Flutter:

```bat
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

Backend:

```bat
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

## এই Folder কীভাবে ব্যবহার করবে

- কোনো পুরনো step কীভাবে করা হয়েছিল বুঝতে learning file পড়ো।
- একই ধরনের নতুন কাজ করার আগে related learning note দেখে নাও।
- কোনো concept বুঝতে সমস্যা হলে সেই step-এর code snippet আর explanation মিলিয়ে পড়ো।
- চাইলে ভবিষ্যতে project শেখার জন্য নতুন Bangla note যোগ করা যাবে।
