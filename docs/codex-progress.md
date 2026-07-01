# SmartKash Codex Progress

## Current Project

- Project name: SmartKash
- MVP type: zero-budget learning MVP
- Current branch: main

## Completed Steps

- Step 00 planning foundation: planning files, architecture rules, Bengali learning workflow, Git/GitHub workflow rules, and progress tracking file prepared.
- Step 00b learning documentation rules: strengthened the Bengali learning file requirements before Step 01.
- Step 01 project structure: created focused root folders for the future Flutter app, Spring Boot backend, helper scripts, and added a project `.gitignore`.
- Step 02 Flutter app skeleton: created the Android-first Flutter shell under `apps/mobile/` with Riverpod, go_router, base theme/config, feature-first folders, and a placeholder home screen.
- Step 03 Spring Boot backend skeleton: created the Maven/Java 21 Spring Boot backend shell under `services/backend/` with base dependencies, environment-based config placeholders, package markers, Maven Wrapper, and context-load test.
- Step 04 PostgreSQL and Flyway foundation: enabled local datasource/JPA/Flyway configuration through environment variables, added the empty Flyway migration folder, and documented Maven Wrapper verification against the local PostgreSQL database.

## Last Commit

- Last commit message: `step-03: add Spring Boot backend skeleton`
- Last commit hash: `58506f9`

## Important Architecture Decisions

- Flutter Android-first app.
- Flutter architecture: Riverpod + feature-first folders.
- Spring Boot backend root package: `com.smartkash`.
- Backend architecture: clean layered feature modules with controller, service, service implementation, repository, entity, DTO, mapper, enums, exception, config, security, firebase, notification, util, and audit.
- Main business database: PostgreSQL.
- Migration tool: Flyway.
- Firebase usage: Phone Auth test OTP and important FCM alerts only.
- Send Money must support both registered mobile number and QR receiver selection.
- Wallet balance is stored for fast reads, backed by immutable ledger entries.
- Money-changing operations require transactions, safe wallet locking, idempotency keys, and audit logs.

## Manual Setup Completed By User

- Repository workspace created at `D:\github\my-kash`.
- Project name changed to SmartKash.
- GitHub remote `origin` is configured and push worked for previous workflow commits.
- Java 21 is available locally.
- Local PostgreSQL database `smartkash_db` is ready.
- Local PostgreSQL owner/user `smartkash_admin` is ready.

## Pending Manual Setup

- Confirm GitHub remote exists and is accessible.
- Configure Firebase test phone numbers later when Firebase setup begins.
- Create real local environment file from `.env.example` later; do not commit secrets.

## Known Issues

- No implementation code exists yet.
- Step 04 configures PostgreSQL/Flyway foundation only; no business APIs, Firebase Auth logic, JWT issuing, wallet, transaction, ledger, business schema, Flyway migration scripts, admin pages, or feature logic exist yet.
- `flutter create` timed out in the sandbox, so the minimal Flutter skeleton was created manually and verified with Flutter tooling.
- Global `mvn` is not available in the Codex session, so backend verification should use Maven Wrapper `.\mvnw.cmd`.
- Flyway works against local PostgreSQL 17.10 after adding `flyway-database-postgresql`, but logs a warning that this Flyway version officially tested support up to PostgreSQL 16.

## Next Recommended Step

- Step 05: configure Firebase Auth foundation with test phone numbers and fixed OTP planning-aware setup, without real SMS billing or business feature implementation.

## Standard Step Completion Format

Every future step must end with:

1. Step completed
2. Changed files
3. Verification commands run
4. Git status summary
5. Commit message
6. Push status
7. Learning file created/updated
8. Next recommended step
