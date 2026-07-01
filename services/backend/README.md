# SmartKash Backend

Spring Boot backend skeleton for the SmartKash zero-budget learning MVP.

## Current Scope

Step 03 creates the backend skeleton only:

- Java 21
- Maven
- Spring Boot
- Root package: `com.smartkash`
- Environment-based configuration placeholders
- Package markers for planned modules
- Context-load test

Business APIs, Firebase Auth logic, JWT issuing, wallet/ledger logic, database schema, Flyway migrations, and admin pages are intentionally not implemented yet.

## Verification

```powershell
mvn test
mvn -q -DskipTests package
```

