# SmartKash Product Plan

## Purpose

SmartKash is a bKash-like zero-budget learning MVP. The goal is to learn how to design and build a wallet system step by step using Flutter, Spring Boot, PostgreSQL, Firebase Phone Auth test OTP, and FCM notifications.

## Target Users

- Customer: uses wallet features such as Add Money, Send Money, Payment, Savings, Loan request, Recharge, and Statement.
- Merchant: receives merchant payments and has a wallet like a normal user.
- Admin: manages minimal operational actions such as Add Money approval, Loan approval or rejection, and viewing records.

## MVP Scope

- Flutter full cross-platform customer app.
- Supported Flutter platforms: Android, iOS, Web, Windows, Linux, and macOS.
- Android remains the primary local testing target on the current Windows machine.
- Web can also be tested locally on Windows.
- Windows desktop builds require Visual Studio Desktop development with C++ workload.
- iOS/macOS builds require macOS with Xcode.
- Linux builds require a Linux environment.
- Riverpod-based Flutter state management.
- Feature-first Flutter folder structure.
- Spring Boot backend with REST APIs.
- Clean layered Spring Boot architecture under `com.smartkash`.
- Minimal Spring web admin panel.
- PostgreSQL database.
- Flyway database migration planning.
- Firebase Phone Auth test phone numbers and fixed OTP codes.
- FCM for important transaction alerts only.
- Stored wallet balance plus immutable ledger entries.
- Idempotency support for all money-changing APIs.
- Bengali learning documentation for every future implementation step.

## Architecture Decisions

- Backend controllers must be thin and delegate business logic to services.
- Major backend modules should use service interfaces and `service.impl` implementation classes.
- Repositories are for database access only.
- Entities are persistence models and must not be returned directly from APIs.
- DTOs are required for request and response payloads.
- Mappers convert between entities and DTOs.
- Enums are required for fixed statuses and types.
- Flutter UI widgets should stay clean; network calls, Firebase logic, and QR logic must live in dedicated feature/core services.

## Out Of Scope For MVP

- Real bank API integration.
- Real payment gateway.
- Real recharge provider.
- Real KYC provider.
- Real SMS OTP billing.
- Real money movement.
- Full analytics dashboard.
- Advanced reports.
- Complex role and permission system.
- Loan disbursement, repayment, and installment tracking.

## Core Assumptions

This is a zero-budget learning MVP, not a real licensed financial service. The system design should be clean enough for learning production-style patterns, but it must not pretend to operate real financial services.
