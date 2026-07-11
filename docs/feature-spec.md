# SmartKash Feature Specification

## Platform Scope

SmartKash is a Flutter full cross-platform MVP for Android, iOS, Web, Windows, Linux, and macOS. The same core user features should be planned for all supported Flutter platforms. Android remains the primary local testing target on Windows, and Web can also be verified locally on Windows.

## Auth

- User signs in with mobile number using Firebase Phone Auth test OTP.
- MVP uses Firebase test phone numbers and fixed OTP codes only.
- Real SMS OTP is not used to avoid billing requirements.
- After Firebase token verification, Spring Boot issues a backend JWT.
- User sets a PIN.
- PIN verification must happen only in the backend.

## Add Money

- Customer enters an amount, selects a demo source, and submits Add Money.
- Add Money is instant in the current SmartKash learning MVP; no admin approval or pending state is required.
- Submit creates wallet credit, immutable ledger entry, and user-facing transaction record in one backend transaction.
- Add Money submit must use an idempotency key to avoid duplicate wallet credit on double tap or retry.
- The saved `add_money_requests` row acts as the user's Add Money/top-up record and should normally be `APPROVED` immediately.

## Send Money

Send Money supports two receiver selection methods:

- Registered mobile number.
- QR-based receiver selection.

QR Send Money rules:

- QR payload must resolve only a registered receiver user/account.
- Backend must validate QR payload.
- Backend must validate receiver account status.
- Backend must validate sender balance.
- Backend must validate PIN.
- Backend must validate idempotency key before processing.

Successful Send Money must:

- Debit sender wallet.
- Credit receiver wallet.
- Create linked debit and credit ledger entries under the same transaction reference.
- Create user-facing transaction records.
- Run inside a database transaction.
- Use a safe wallet locking strategy.
- Use idempotency key to prevent duplicate transfers.

## Merchant Payment

- Merchant is a user with `role = MERCHANT`.
- Merchant has a wallet.
- Customer pays using merchant number/account number.
- Backend debits customer wallet and credits merchant wallet.
- Payment creates linked ledger entries and transaction records.
- Payment must run inside a database transaction and use an idempotency key.

## Statement And Transactions

- User can view transaction history.
- User can filter by date, type, and status.
- User can open transaction details as a receipt.
- The Flutter Inbox tab contains a Transactions view with search and receipt bottom sheet.
- Transaction records are user-facing summaries; ledger entries are internal immutable accounting records.

## Savings

- Customer creates a goal-based savings plan.
- Customer sets target amount and target date.
- Customer deposits from wallet into the savings goal.
- Savings deposit debits wallet, records savings deposit, creates ledger entries, and creates transaction record.
- Savings deposit requires authentication, PIN confirmation, and idempotency key.
- Savings deposit must run inside a database transaction.

## Loan

- Customer submits a loan request.
- Admin can approve or reject the loan request.
- MVP Phase 1 loan approval or rejection only updates loan request status: `PENDING`, `APPROVED`, `REJECTED`.
- Loan disbursement, wallet credit, repayment, and installment tracking are future scope.

## Mobile Recharge

- Customer selects operator, mobile number, and amount.
- MVP recharge is demo success, not admin approval.
- Table name should be `mobile_recharges`.
- Recharge debits wallet, creates ledger entry, user-facing transaction record, and recharge record.
- Recharge requires authentication, PIN confirmation, and idempotency key.
- Recharge must run inside a database transaction.
