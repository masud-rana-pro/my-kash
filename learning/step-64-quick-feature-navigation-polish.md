# Step 64: Quick Feature Navigation Polish

## 1. Step title

এই step-এর নাম: **Step 64: Quick Feature Navigation Polish**।

## 2. কী implement করা হয়েছে

Home screen-এর `Quick Features` অংশ আগে static ছিল। এই step-এ এগুলো actionable করা হয়েছে।

- `History` tap করলে Transactions screen খুলবে।
- `Teletalk` tap করলে Mobile Recharge screen খুলবে।
- `Transfer` tap করলে Send Money screen খুলবে।
- `Goals` tap করলে Savings screen খুলবে।
- `Rewards` এবং `Offers` tap করলে clear MVP scope notice দেখাবে।

## 3. কেন এই step দরকার

Manual demo বা end-to-end test করার সময় user-এর দ্রুত Transaction history, Recharge, Send Money, Savings screen-এ যেতে হয়। আগে Quick Features দেখতে সুন্দর ছিল কিন্তু tap করলে কিছু করত না।

এই step demo-readiness বাড়ায়:

- transaction history সহজে accessible হয়,
- common flows দ্রুত test করা যায়,
- unimplemented feature honest placeholder দেখায়।

## 4. কোন files change হয়েছে

- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-64-quick-feature-navigation-polish.md`

## 5. Important code snippets

### Transaction import

```dart
import '../../transaction/presentation/transaction_list_screen.dart';
```

### Actionable Quick Chip

```dart
_QuickChip(
  icon: Icons.receipt_long_outlined,
  label: 'History',
  routeName: TransactionListScreen.routeName,
)
```

### Actionable Goals card

```dart
_FeatureCard(
  icon: Icons.emoji_events,
  label: 'Goals',
  routeName: SavingsScreen.routeName,
)
```

### Shared tap handler

```dart
void _handleQuickFeatureTap(
  BuildContext context,
  String label,
  String? routeName,
  String? notice,
) {
  if (routeName != null) {
    context.pushNamed(routeName);
    return;
  }

  _showMvpFeatureNotice(
    context,
    title: label,
    message: notice ?? '$label is planned for a later SmartKash MVP step.',
  );
}
```

## 6. Code explanation

### Import

`TransactionListScreen` import করা হয়েছে কারণ History chip এখন transaction screen open করবে।

### QuickChip

`routeName` optional parameter। যদি routeName থাকে, tap করলে route open হবে।

`notice` optional parameter। যদি route না থাকে, notice text bottom sheet-এ দেখানো হবে।

### FeatureCard

Feature card-এও same route/notice logic use করা হয়েছে। এতে code duplicate কমে।

### Shared tap handler

`routeName != null` হলে real screen open হয়।

`return` দেওয়া হয়েছে যাতে route open করার পর notice না দেখায়।

`routeName == null` হলে `_showMvpFeatureNotice` call হয়।

## 7. SmartKash flow-তে কীভাবে কাজ করে

1. User Home screen-এ যায়।
2. `History` tap করে transaction list দেখে।
3. `Teletalk` tap করে recharge flow test করে।
4. `Transfer` tap করে send money flow test করে।
5. `Goals` tap করে savings flow test করে।
6. `Rewards`/`Offers` tap করলে future scope notice দেখে।

## 8. কেন backend change করা হয়নি

এই step navigation polish only। Existing screens/backend APIs already আছে:

- Transactions API
- Mobile Recharge API
- Send Money API
- Savings API

Rewards/Offers-এর backend এখন নেই, তাই fake API বা fake result যোগ করা হয়নি।

## 9. Common mistakes and cautions

- Static card রেখে দিলে user confused হয়।
- Fake Rewards/Offers transaction দেখানো যাবে না।
- Route name ভুল হলে navigation fail করবে।
- Implemented feature হলে notice দেখানো উচিত না; direct route open হওয়া উচিত।

## 10. Manual verification commands

Flutter:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

## 11. Expected output

- `History` tap করলে Transactions screen open হবে।
- `Teletalk` tap করলে Mobile Recharge screen open হবে।
- `Transfer` tap করলে Send Money screen open হবে।
- `Goals` tap করলে Savings screen open হবে।
- `Rewards` tap করলে MVP notice bottom sheet দেখাবে।
- `Offers` tap করলে MVP notice bottom sheet দেখাবে।

## 12. Git commands used

```powershell
git status
git add <step-64-files>
git commit -m "step-64: polish quick feature navigation"
git push
```

## 13. কী শিখলাম

এই step থেকে শিখলাম কীভাবে Home screen-এর repeated UI components reusable navigation/placeholder behavior পায়, এবং MVP app-এ demo flow দ্রুত verify করার জন্য shortcut navigation কতটা দরকারি।
