# SmartKash

SmartKash is a zero-budget learning MVP for a bKash-like wallet app. The project will be built step by step with a Flutter Android-first user app, a Spring Boot backend, PostgreSQL for business data, Firebase Phone Auth test OTP, and Firebase Cloud Messaging for important transaction alerts.

This repository currently contains planning files only. Do not add Flutter app code, Spring Boot code, database migrations, schemas, or feature implementation until the planning files are accepted and the next implementation step is requested.

## MVP Features

- Add Money with admin approval
- Send Money by registered mobile number
- Send Money by QR-based receiver selection
- Merchant Payment
- Statement and transaction receipts
- Goal-based Savings
- Loan request with admin approval or rejection status
- Demo Mobile Recharge
- Minimal Spring web admin panel
- Bengali learning documentation for every future implementation step

## Tech Scope

- Flutter Android-first app
- Riverpod state management
- Spring Boot REST API and minimal web admin
- Spring Web, Spring Security, Spring Data JPA, Hibernate, Bean Validation
- PostgreSQL Driver, Flyway database migrations, Lombok
- Firebase Admin SDK, JWT library, Spring Boot Actuator, OpenAPI/Swagger
- PostgreSQL database
- Firebase Phone Auth test phone numbers and fixed OTP codes
- Firebase Cloud Messaging for important alerts only
- JWT-based backend API authentication after Firebase token verification

## Architecture Scope

- Backend root package: `com.smartkash`.
- Backend uses clean layered architecture: controller, service, service implementation, repository, entity, DTO, mapper, enums, exception, config, security, firebase, notification, util, and audit.
- Flutter uses a feature-first architecture with `lib/app`, `lib/core`, `lib/features`, and `lib/shared`.
- API calls must stay outside widgets in repository/service classes.
- Entities must not be exposed directly in API responses; request and response DTOs are required.
- Money-changing operations must use database transactions, idempotency keys, audit logs, and a safe wallet locking strategy.

## Important MVP Boundaries

This is a zero-budget learning MVP, not a real licensed financial service.

The MVP will not integrate real bank APIs, payment gateways, recharge providers, KYC providers, real SMS OTP, or real money movement. Firebase Phone Auth must use test phone numbers and fixed OTP codes to avoid SMS billing requirements.

## Wallet And Ledger Rule

Wallet balance will be stored for fast reads, but every balance change must be backed by immutable ledger entries and user-facing transaction records. Ledger entries must never be updated or deleted after creation. Any correction must be done using reversal ledger entries.

Wallet-to-wallet transfers must create linked debit and credit ledger entries under the same transaction reference.

## Learning Rule

Every future implementation step must create or update a Bengali learning file inside `learning/`.

File naming format:

```text
learning/step-XX-topic-name.md
```

See `learning/README.md` and `docs/codex-instructions.md` for the required format.

## Git And Step Workflow

Every implementation step must use Git and GitHub:

1. Check `git status`.
2. Review the relevant planning docs.
3. Make only focused changes for the current step.
4. Update or create the required Bangla learning file in `learning/`.
5. Run relevant verification commands or tests when possible.
6. Check `git status` again.
7. Commit with `step-XX: short action summary`.
8. Push to GitHub.
9. Stop with a short step completion summary.

Track step progress in `docs/codex-progress.md`.

## Environment

Use `.env.example` as the template for local configuration. Do not hardcode database credentials, Firebase credentials, JWT secrets, or environment-specific values in source code.
