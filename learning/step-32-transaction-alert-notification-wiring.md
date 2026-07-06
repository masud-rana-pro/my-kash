# Step 32: Transaction Alert Notification Wiring

## 1. Step Title

Step 32-এ SmartKash backend money-changing/status flows-এর সাথে FCM transaction alert service wire করা হয়েছে।

## 2. What Was Implemented

Step 31-এ `TransactionAlertService` foundation ছিল। Step 32-এ সেটি important flows-এর success path-এ call করা হয়েছে:

- Add Money approved
- Add Money rejected
- Loan approved
- Loan rejected
- Send Money completed
- Money received
- Merchant Payment completed
- Merchant Payment received
- Savings Deposit completed
- Mobile Recharge completed

`FCM_ENABLED=false` হলে বা Firebase Admin configured না থাকলে alert send skip হবে, কিন্তু main API flow fail হবে না।

## 3. Why This Step Is Needed

Notification module শুধু service বানালেই user alert পাবে না। Successful transaction বা status change হওয়ার পরে business service থেকে notification service call করতে হয়।

এতে controller clean থাকে, business flow complete হওয়ার পরে notification boundary কাজ করে।

## 4. Files Changed

```text
services/backend/src/main/java/com/smartkash/admin/service/impl/AdminAddMoneyDecisionServiceImpl.java
services/backend/src/main/java/com/smartkash/admin/service/impl/AdminLoanDecisionServiceImpl.java
services/backend/src/main/java/com/smartkash/sendmoney/service/impl/SendMoneyTransferServiceImpl.java
services/backend/src/main/java/com/smartkash/payment/service/impl/MerchantPaymentServiceImpl.java
services/backend/src/main/java/com/smartkash/savings/service/impl/SavingsGoalServiceImpl.java
services/backend/src/main/java/com/smartkash/recharge/service/impl/MobileRechargeServiceImpl.java
docs/backend-api-plan.md
docs/notification-plan.md
docs/codex-progress.md
learning/step-32-transaction-alert-notification-wiring.md
```

## 5. Important Code Snippets

### Add Money Alert

```java
transactionAlertService.sendTransactionAlert(
        savedRequest.getUser(),
        NotificationType.ADD_MONEY,
        "Add Money approved",
        "Your Add Money request of BDT " + savedRequest.getAmount() + " was approved.",
        Map.of("transactionReference", transactionReference, "type", TransactionType.ADD_MONEY.name())
);
```

Explanation:

- `savedRequest.getUser()`: যে customer-এর Add Money request approved হয়েছে।
- `NotificationType.ADD_MONEY`: alert category।
- title/body user-visible alert text।
- `Map.of(...)`: notification data payload, future Flutter routing/receipt screen-এ কাজে লাগতে পারে।

### Send Money Sender And Receiver Alerts

```java
transactionAlertService.sendTransactionAlert(
        sender,
        NotificationType.SEND_MONEY,
        "Send Money completed",
        "You sent BDT " + request.amount() + " to " + receiver.getMobileNumber() + ".",
        Map.of("transactionReference", senderTransactionReference, "type", TransactionType.SEND_MONEY.name())
);
transactionAlertService.sendTransactionAlert(
        receiver,
        NotificationType.SEND_MONEY,
        "Money received",
        "You received BDT " + request.amount() + " from " + sender.getMobileNumber() + ".",
        Map.of("transactionReference", senderTransactionReference, "type", TransactionType.RECEIVE_MONEY.name())
);
```

Explanation:

- Sender alert দেখে বুঝবে টাকা পাঠানো complete হয়েছে।
- Receiver alert দেখে বুঝবে টাকা received হয়েছে।
- দুই alert একই transfer reference data বহন করে।
- Duplicate idempotency replay response-এ নতুন alert পাঠানো হয় না।

### Merchant Payment Alerts

```java
transactionAlertService.sendTransactionAlert(
        customer,
        NotificationType.PAYMENT,
        "Merchant Payment completed",
        "You paid BDT " + request.amount() + " to " + merchant.getBusinessName() + ".",
        Map.of("transactionReference", customerTransactionReference, "type", TransactionType.MERCHANT_PAYMENT.name())
);
transactionAlertService.sendTransactionAlert(
        merchantUser,
        NotificationType.PAYMENT,
        "Merchant Payment received",
        "You received BDT " + request.amount() + " from " + customer.getMobileNumber() + ".",
        Map.of("transactionReference", customerTransactionReference, "type", TransactionType.MERCHANT_PAYMENT.name())
);
```

Explanation:

- Customer payment complete alert পায়।
- Merchant received payment alert পায়।
- `NotificationType.PAYMENT` payment category হিসেবে থাকে।

### Savings Deposit Alert

```java
transactionAlertService.sendTransactionAlert(
        user,
        NotificationType.SAVINGS,
        "Savings deposit completed",
        "BDT " + request.amount() + " was deposited to " + savedGoal.getName() + ".",
        Map.of("transactionReference", transactionReference, "goalId", String.valueOf(savedGoal.getId()))
);
```

Explanation:

- Savings deposit successful হলে user alert পায়।
- Data payload-এ `goalId` থাকে, future Flutter goal details screen open করতে পারবে।

### Mobile Recharge Alert

```java
transactionAlertService.sendTransactionAlert(
        user,
        NotificationType.RECHARGE,
        "Mobile Recharge completed",
        "BDT " + request.amount() + " recharge to " + request.mobileNumber() + " was completed.",
        Map.of("transactionReference", transactionReference, "rechargeId", String.valueOf(savedRecharge.getId()))
);
```

Explanation:

- Demo recharge successful হলে user alert পায়।
- Real provider নেই, কিন্তু local demo transaction complete হলে alert boundary call হয়।

## 6. How This Works In SmartKash Flow

Example Send Money flow:

1. User `/api/send-money` call করে।
2. Backend PIN, idempotency, wallet lock, ledger, transaction complete করে।
3. Transaction complete হলে `TransactionAlertService` call হয়।
4. FCM enabled/configured হলে device token-এ alert যায়।
5. FCM disabled হলে log করে skip করে, API success response ঠিক থাকে।

## 7. Expected Manual Outputs

With `FCM_ENABLED=false`:

```text
Expected: API flow success থাকবে, backend log-এ "Skipping FCM alert..." দেখা যেতে পারে।
```

With token registered but Firebase Admin missing:

```text
Expected: API flow success থাকবে, FCM send skip হবে।
```

With FCM enabled and Firebase Admin configured:

```text
Expected: registered device token থাকলে FCM notification send attempt হবে।
```

## 8. Common Mistakes And Cautions

- Notification failure যেন money transaction rollback না করে।
- Raw PIN notification data-তে দেওয়া যাবে না।
- FCM token user-supplied user ID দিয়ে save করা যাবে না।
- সব ছোট activity-তে notification পাঠানো যাবে না।
- Local environment-এ notification না যাওয়া অনেক সময় expected।
- Future Flutter notification permission/background handler আলাদা step।

## 9. Manual Verification Commands

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
.\mvnw.cmd spring-boot:run
```

Manual behavior checks:

```text
1. FCM_ENABLED=false রেখে Send Money/Merchant Payment/Savings Deposit/Recharge API call করো।
2. API success response পাওয়া উচিত।
3. Backend log-এ FCM skipped message দেখা যেতে পারে।
4. Transaction/ledger/idempotency records আগের মতো তৈরি হওয়া উচিত।
```

Database:

```powershell
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
SELECT id, user_id, device_type, active FROM firebase_devices ORDER BY id DESC;
SELECT id, transaction_reference, user_id, type, status, amount FROM transactions ORDER BY id DESC LIMIT 10;
```

General:

```powershell
cd /d D:\github\my-kash
git status
```

## 10. Git Commands Used

```powershell
git status --short --branch
git diff --check
git add <step-32-files>
git commit -m "step-32: wire transaction alert notifications"
git push
git status --short --branch
```

## 11. What I Learned

এই step থেকে শিখলাম notification system business flow-এর success point-এ call করা উচিত, কিন্তু notification delivery failure যেন মূল transaction fail না করে। FCM local/dev environment-এ optional থাকতে পারে, আর production/deployment হলে full delivery test করা যাবে।
