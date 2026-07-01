# SmartKash Backend

Spring Boot backend skeleton for the SmartKash zero-budget learning MVP.

## Current Scope

Step 04 keeps the backend foundation focused on PostgreSQL and Flyway only:

- Java 21
- Maven
- Spring Boot
- Root package: `com.smartkash`
- Environment-based configuration placeholders
- Package markers for planned modules
- PostgreSQL connection through environment variables
- Flyway enabled with an empty migration folder

Business APIs, Firebase Auth logic, JWT issuing, wallet/ledger logic, business database schema, Flyway migration scripts, and admin pages are intentionally not implemented yet.

## Verification

Use Maven Wrapper from the backend folder. Set local environment variables before running verification:

```powershell
cd services/backend
$env:DATABASE_URL="jdbc:postgresql://localhost:5432/smartkash_db"
$env:DATABASE_USERNAME="smartkash_admin"
$env:DATABASE_PASSWORD="<your-local-database-password>"
$env:SPRING_PROFILES_ACTIVE="local"
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```
