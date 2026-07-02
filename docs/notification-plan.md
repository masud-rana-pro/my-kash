# SmartKash Notification Plan

## Purpose

Use Firebase Cloud Messaging for important transaction alerts only.

Notification logic should live in a dedicated backend notification module, not inside controllers. The module should receive event-like service calls after successful transactions and should respect `FCM_ENABLED`.

FCM platform support should be added carefully per Flutter platform. Android remains the primary local notification testing target; full platform-specific notification verification can happen later when each platform is configured.

## MVP Notification Events

- Add Money approved.
- Add Money rejected.
- Send Money completed.
- Merchant Payment completed.
- Savings deposit completed.
- Mobile Recharge completed.
- Loan request approved.
- Loan request rejected.

## Firebase OTP Note

Firebase Phone Auth will use test phone numbers and fixed OTP codes for the MVP. Real SMS OTP will not be used to avoid billing requirements.

## Local Testing Note

If the backend is running locally, FCM notification testing may be limited. Full FCM testing can be done after backend deployment.

## Non-Goals

- Do not send notification for every small user/admin activity in the MVP.
- Do not use paid notification services.
- Do not build a complex notification preference system in MVP Phase 1.
