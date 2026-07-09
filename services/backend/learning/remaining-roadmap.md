# SmartKash MVP বাকি রোডম্যাপ (Bangla)

## Overview

Step 50 ইতিমধ্যে committed (Firebase properties fix). নিচে বাকি steps:

### Step 50: Login Final Verification & Cleanup

Firebase OTP → backend JWT → user/wallet create → PIN setup/Home flow full verify. Any login leftovers fix.

### Step 51: Wallet Home Dashboard Integration

Home screen-এ real wallet balance, user name/phone, role, PIN state show.

### Step 52: Transaction History UI

Transaction list/detail screen connect with backend transaction APIs.

### Step 53: Add Money UI

Add Money request create/list UI. Admin approval backend already আছে, frontend customer side লাগবে।

### Step 54: Send Money UI

Mobile number receiver resolve, amount, PIN confirmation, transfer submit, success/fail screen.

### Step 55: QR Send Money Foundation UI

QR payload generate/display and QR receiver selection/scan flow. Camera dependency লাগতে পারে।

### Step 56: Merchant Payment UI

Merchant number lookup/payment form, PIN confirmation, success transaction view.

### Step 57: Mobile Recharge UI

Operator/number/amount form, PIN confirmation, backend recharge API connect.

### Step 58: Savings UI

Goal create/list, deposit flow, PIN confirmation, progress display.

### Step 59: Loan UI

Loan request create/list/status UI. Phase 1 only approve/reject status, no disbursement.

### Step 60: Notification/Profile/Settings Polish

Profile completion, sign out, FCM token registration if needed, basic notification/inbox shell.

### Step 61: Final E2E Testing, Bug Fix, Demo Data

End-to-end manual test: login, PIN, wallet, add money approval, send money, payment, recharge, savings, loan, transaction history. Fix bugs only.

### Optional Steps

- Step 62: Admin Web Minimal UI
- Step 63: UI Polish Against Reference Screens
- Step 64: Release Prep (debug APK, README, troubleshooting)

## Estimate

- Minimum MVP finish: 12 steps
- With admin UI + design polish + release prep: 15 steps
- Very polished app-like UI: 18+ steps
