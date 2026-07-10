# Step 63: Home MVP Placeholder Polish

## 1. Step title

এই step-এর নাম: **Step 63: Home MVP Placeholder Polish**।

## 2. কী implement করা হয়েছে

Home screen-এর যেসব action এখনো MVP-তে implement করা হয়নি, সেগুলো tap করলে আগে কোনো feedback দিত না। এই step-এ:

- `Cash Out` tap করলে clear MVP scope notice দেখায়।
- `Pay Bill` tap করলে clear MVP scope notice দেখায়।
- `See More` tap করলে active flows এবং later-scope services explain করে।
- কোনো fake transaction বা backend API call যোগ করা হয়নি।

## 3. কেন এই step দরকার

Mobile banking app-এ button tap করে কিছু না হলে user ভাবে app broken। MVP হলেও user-কে honest feedback দিতে হয়।

এই step user experience improve করে:

- silent tap problem দূর করে,
- কোন feature এখন নেই তা পরিষ্কার করে,
- future scope explain করে,
- ভুল করে fake backend behavior যোগ করে না।

## 4. কোন files change হয়েছে

- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-63-home-mvp-placeholder-polish.md`

## 5. Important code snippets

### See More placeholder

```dart
TextButton.icon(
  onPressed: () => _showMvpFeatureNotice(
    context,
    title: 'More services',
    message:
        'Extra services will be added after the core SmartKash MVP flows are verified. Current active flows are Add Money, Send Money, Payment, Recharge, Savings, Loan, QR, Transactions, Account, and Inbox.',
  ),
  iconAlignment: IconAlignment.end,
  icon: const Icon(Icons.keyboard_arrow_down),
  label: const Text('See More'),
)
```

### Action tile placeholder logic

```dart
if (action.routeName != null) {
  context.pushNamed(action.routeName!);
  return;
}

_showMvpFeatureNotice(
  context,
  title: action.label,
  message: switch (action.label) {
    'Cash Out' =>
      'Cash Out needs agent/counter validation and settlement rules. It is intentionally kept out of this zero-budget MVP phase.',
    'Pay Bill' =>
      'Pay Bill needs a biller/provider catalog and bill reference validation. It is planned for a later focused step.',
    _ =>
      '${action.label} is planned for a later SmartKash MVP step.',
  },
);
```

### Reusable bottom sheet helper

```dart
void _showMvpFeatureNotice(
  BuildContext context, {
  required String title,
  required String message,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              Text(message),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
```

## 6. Code explanation

### See More placeholder

`onPressed` এখন empty নয়। User tap করলে bottom sheet দেখায়।

`title: 'More services'` bottom sheet-এর heading।

`message` user-কে বলে currently কোন flows active আছে এবং extra services later scope।

### Action tile logic

`if (action.routeName != null)` মানে implemented feature হলে existing route open হবে।

`return` দেওয়া হয়েছে যাতে route open হওয়ার পর placeholder bottom sheet না খুলে।

`switch (action.label)` দিয়ে unimplemented action অনুযায়ী আলাদা message দেওয়া হয়েছে।

`Cash Out` message agent/counter settlement-এর কথা বলে।

`Pay Bill` message biller/provider catalog-এর কথা বলে।

### Bottom sheet helper

`showModalBottomSheet` screen-এর নিচ থেকে polished notice দেখায়।

`SafeArea` phone navigation bar/notch overlap এড়ায়।

`showDragHandle: true` modern bottom sheet feel দেয়।

`FilledButton` tap করলে bottom sheet close হয়।

## 7. SmartKash flow-তে কীভাবে কাজ করে

1. User Home screen-এ যায়।
2. Implemented feature যেমন Send Money tap করলে route open হয়।
3. Unimplemented feature যেমন Cash Out tap করলে scope notice দেখায়।
4. User বুঝতে পারে feature planned, কিন্তু current MVP-তে নেই।

## 8. কেন backend change করা হয়নি

Cash Out এবং Pay Bill real provider/agent/biller logic ছাড়া implement করা ঠিক না। এই step শুধুই UI polish। তাই:

- database migration নেই,
- backend API নেই,
- fake transaction নেই,
- wallet balance change নেই।

## 9. Common mistakes and cautions

- Placeholder button tap করে fake success দেখানো যাবে না।
- Wallet balance mutate করা যাবে না।
- Silent no-op রাখা যাবে না।
- Feature later scope হলে UI copy honest হওয়া দরকার।

## 10. Manual verification commands

Flutter:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

## 11. Expected output

- `Cash Out` tap করলে bottom sheet খুলবে।
- `Pay Bill` tap করলে bottom sheet খুলবে।
- `See More` tap করলে active flows/later scope message দেখাবে।
- `Got it` tap করলে bottom sheet close হবে।
- Implemented feature buttons আগের মতো route open করবে।

## 12. Git commands used

```powershell
git status
git add <step-63-files>
git commit -m "step-63: polish home MVP placeholders"
git push
```

## 13. কী শিখলাম

এই step থেকে শিখলাম MVP app-এ unimplemented feature-ও user-friendly হতে পারে। Button silent না রেখে clear scope notice দেখালে user বুঝতে পারে app broken নয়, feature later phase-এর জন্য planned।
