# Step 04: PostgreSQL এবং Flyway Foundation

## 1. Step title

Step 04-এর title: **PostgreSQL এবং Flyway foundation setup**.

এই step-এ SmartKash backend-কে local PostgreSQL database-এর সাথে connect করার foundation তৈরি করা হয়েছে এবং Flyway migration tool enable করা হয়েছে। তবে কোনো business schema, table, wallet, ledger, transaction, API, বা Firebase/JWT feature implement করা হয়নি।

## 2. What was implemented

এই step-এ করা হয়েছে:

- Spring Boot backend থেকে DataSource, JPA, এবং Flyway auto-configuration আবার enable করা হয়েছে।
- Local profile-এর datasource config PostgreSQL database `smartkash_db`-এর জন্য environment-variable based করা হয়েছে।
- Flyway enable করা হয়েছে।
- PostgreSQL 17 support-এর জন্য Flyway PostgreSQL database module যোগ করা হয়েছে।
- Empty Flyway migration folder তৈরি করা হয়েছে।
- `.env.example` update করা হয়েছে, যাতে database username/password এবং active profile-এর variable থাকে।
- Backend README update করা হয়েছে Maven Wrapper verification command দিয়ে।
- `docs/codex-progress.md` update করা হয়েছে Step 04 progress track করার জন্য।
- এই Bangla learning file তৈরি করা হয়েছে।

## 3. Why this step is needed

SmartKash wallet app-এর future features, যেমন Send Money, Add Money, Payment, Savings, Loan request, Mobile Recharge, Transaction Statement, Merchant Payment, Audit Log - সবকিছু শেষ পর্যন্ত backend database-এ persist হবে।

PostgreSQL foundation দরকার কারণ:

- User, wallet, transaction, ledger, merchant, savings, loan, recharge data database-এ থাকবে।
- Wallet balance update করার সময় database transaction এবং locking দরকার হবে।
- Immutable ledger entries database table ছাড়া reliable হবে না।
- Admin panel database থেকে users, transactions, add money requests, loan requests দেখতে পারবে।

Flyway foundation দরকার কারণ:

- Database schema version control করা যায়।
- Manual SQL change কমে যায়।
- Team বা future deployment-এ একই migration repeatable হয়।
- কোন schema কখন তৈরি হয়েছে তা track করা যায়।

এই step-এ business schema তৈরি করা হয়নি, কারণ foundation আগে verify করা দরকার। Business tables future database design step-এ planning অনুযায়ী migration script দিয়ে তৈরি হবে।

## 4. Final backend database/config structure

```text
services/backend/
├── README.md
├── pom.xml
├── mvnw.cmd
└── src/
    ├── main/
    │   ├── java/com/smartkash/
    │   └── resources/
    │       ├── application.yml
    │       ├── application-local.yml
    │       └── db/
    │           └── migration/
    │               └── .gitkeep
    └── test/
        └── java/com/smartkash/SmartKashBackendApplicationTests.java
```

## 5. Files/folders created or changed

- `.env.example`
- `services/backend/pom.xml`
- `services/backend/README.md`
- `services/backend/src/main/resources/application.yml`
- `services/backend/src/main/resources/application-local.yml`
- `services/backend/src/main/resources/db/migration/.gitkeep`
- `docs/codex-progress.md`
- `learning/step-04-postgresql-flyway-foundation.md`

## 6. Important snippets created in this step

### `application.yml`

```yaml
spring:
  application:
    name: smartkash-backend
  profiles:
    default: local
```

### `application-local.yml`

```yaml
spring:
  datasource:
    url: ${DATABASE_URL:jdbc:postgresql://localhost:5432/smartkash_db}
    username: ${DATABASE_USERNAME:smartkash_admin}
    password: ${DATABASE_PASSWORD:}
  jpa:
    hibernate:
      ddl-auto: none
    open-in-view: false
    properties:
      hibernate:
        format_sql: true
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: false
```

### `.env.example`

```env
DATABASE_URL=jdbc:postgresql://localhost:5432/smartkash_db
DATABASE_USERNAME=smartkash_admin
DATABASE_PASSWORD=replace-with-your-local-database-password
SPRING_PROFILES_ACTIVE=local
```

### Flyway folder placeholder

```text
services/backend/src/main/resources/db/migration/.gitkeep
```

### Maven Wrapper verification

```powershell
cd services/backend
$env:DATABASE_URL="jdbc:postgresql://localhost:5432/smartkash_db"
$env:DATABASE_USERNAME="smartkash_admin"
$env:DATABASE_PASSWORD="<your-local-database-password>"
$env:SPRING_PROFILES_ACTIVE="local"
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

### `pom.xml` Flyway PostgreSQL dependency

```xml
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-database-postgresql</artifactId>
</dependency>
```

## 7. Line-by-line or block-by-block Bangla explanation

### `application.yml` explanation

```yaml
spring:
```

এটি Spring Boot-এর main configuration block।

```yaml
  application:
    name: smartkash-backend
```

এখানে backend application-এর নাম `smartkash-backend` রাখা হয়েছে। Actuator, logs, এবং future monitoring-এ এই নাম কাজে লাগতে পারে।

```yaml
  profiles:
    default: local
```

কোনো profile explicitly না দিলে Spring Boot `local` profile use করবে। Local development-এ PostgreSQL config `application-local.yml` থেকে load হবে।

Step 03-এ DataSource/JPA/Flyway auto-configuration exclude করা ছিল। Step 04-এ সেই exclude সরানো হয়েছে, কারণ এখন database ready এবং backend datasource initialize করতে পারবে।

### `application-local.yml` datasource explanation

```yaml
spring:
  datasource:
```

এই block Spring Boot database connection configure করে।

```yaml
    url: ${DATABASE_URL:jdbc:postgresql://localhost:5432/smartkash_db}
```

`DATABASE_URL` environment variable থাকলে সেটি use হবে। না থাকলে local fallback হিসেবে `smartkash_db` database URL use হবে। এটি secret নয়, তাই fallback acceptable।

```yaml
    username: ${DATABASE_USERNAME:smartkash_admin}
```

`DATABASE_USERNAME` environment variable থাকলে সেটি use হবে। না থাকলে local fallback হিসেবে `smartkash_admin` use হবে। Username secret নয়, কিন্তু production-এ environment variable use করা উচিত।

```yaml
    password: ${DATABASE_PASSWORD:}
```

Database password environment variable থেকে আসবে। Default blank রাখা হয়েছে, যাতে real password source code বা Git-এ hardcode না হয়।

### JPA explanation

```yaml
  jpa:
    hibernate:
      ddl-auto: none
```

Hibernate যেন নিজে নিজে table create/update না করে। SmartKash-এ database schema Flyway migration দিয়ে version control করা হবে।

```yaml
    open-in-view: false
```

Web request শেষ হওয়া পর্যন্ত database session খোলা রাখা হবে না। এতে service layer-এ data load করার habit তৈরি হয় এবং hidden lazy-loading problem কমে।

```yaml
    properties:
      hibernate:
        format_sql: true
```

Future debugging-এর সময় SQL formatted দেখাবে। এখন business query নেই, কিন্তু later development-এ readable logs helpful হবে।

### Flyway explanation

```yaml
  flyway:
    enabled: true
```

Flyway চালু করা হয়েছে। App startup/test-এর সময় Flyway migration state check করবে।

```yaml
    locations: classpath:db/migration
```

Migration scripts future-এ `src/main/resources/db/migration` folder-এ রাখা হবে।

```yaml
    baseline-on-migrate: false
```

Existing unknown schema ধরে automatic baseline করা হবে না। Learning MVP-তে explicit migration history রাখা safer।

### `.env.example` explanation

```env
DATABASE_URL=jdbc:postgresql://localhost:5432/smartkash_db
```

Spring Boot backend কোন PostgreSQL database-এ connect করবে সেটি define করে।

```env
DATABASE_USERNAME=smartkash_admin
```

Database login user define করে।

```env
DATABASE_PASSWORD=replace-with-your-local-database-password
```

এটি placeholder। Real password `.env.example` বা Git-এ রাখা যাবে না।

```env
SPRING_PROFILES_ACTIVE=local
```

Spring Boot-কে local profile চালাতে বলে।

### `.gitkeep` explanation

```text
services/backend/src/main/resources/db/migration/.gitkeep
```

Git empty folder track করে না। Flyway migration folder এখন empty, কারণ business schema এখনো তৈরি করা হয়নি। `.gitkeep` folder structure Git-এ রাখে, যাতে future step-এ migration file যোগ করার জায়গা ready থাকে।

### `pom.xml` Flyway PostgreSQL dependency explanation

```xml
<dependency>
```

এটি Maven dependency declaration শুরু করে।

```xml
    <groupId>org.flywaydb</groupId>
```

Dependency কোন organization/group থেকে আসছে তা বলে। এখানে Flyway-এর official group।

```xml
    <artifactId>flyway-database-postgresql</artifactId>
```

Flyway core-এর সাথে PostgreSQL database support module যোগ করে। PostgreSQL 17-এর মতো newer database version support করতে এই module দরকার হয়।

```xml
</dependency>
```

Dependency block শেষ করে।

## 8. Why no business schema or migrations were added

এই step-এর scope শুধু PostgreSQL এবং Flyway foundation। তাই তৈরি করা হয়নি:

- `users` table
- `wallets` table
- `ledger_entries` table
- `transactions` table
- `idempotency_keys` table
- `merchants` table
- `mobile_recharges` table
- loan/savings/admin/audit tables

Business schema তৈরি করার আগে database plan অনুযায়ী exact columns, constraints, indexes, ledger rule, idempotency rule, and audit rule implement করতে হবে। তাই Step 04 clean foundation-এ থেমেছে।

## 9. How this structure works in the SmartKash project flow

Future SmartKash flow হবে:

1. Flutter app API call করবে Spring Boot backend-এ।
2. Spring Boot request validate করবে।
3. Money-changing operation হলে service layer database transaction start করবে।
4. Wallet balance update হবে safe locking strategy দিয়ে।
5. Immutable ledger debit/credit entries create হবে।
6. User-facing transaction record create হবে।
7. PostgreSQL data persist করবে।
8. Flyway migration future schema changes version করে রাখবে।

Step 04 এই flow-এর database foundation তৈরি করল। এখন backend PostgreSQL connection এবং Flyway lifecycle verify করতে পারে।

## 10. Common mistakes and cautions

- Real database password `.env.example`, `application.yml`, বা `application-local.yml`-এ hardcode করা যাবে না।
- `.env` file commit করা যাবে না।
- Flyway folder তৈরি করলেই business migration script লিখে ফেলা যাবে না; সেটা future scoped step।
- Hibernate `ddl-auto: update` ব্যবহার করলে schema uncontrolled হয়ে যেতে পারে। SmartKash-এ Flyway migration use করতে হবে।
- Global `mvn` Codex session-এ unavailable হতে পারে, তাই `.\mvnw.cmd` use করতে হবে।
- Database user owner না হলে future migration permission error হতে পারে।
- Flyway `flyway_schema_history` table create করতে পারে; এটা business schema নয়, Flyway-এর internal history table।
- PostgreSQL 17 use করলে শুধু `flyway-core` যথেষ্ট নাও হতে পারে; `flyway-database-postgresql` dependency দরকার হতে পারে।

## 11. How to verify this step

Backend folder থেকে environment variables set করে Maven Wrapper চালাতে হবে:

```powershell
cd services/backend
$env:DATABASE_URL="jdbc:postgresql://localhost:5432/smartkash_db"
$env:DATABASE_USERNAME="smartkash_admin"
$env:DATABASE_PASSWORD="<your-local-database-password>"
$env:SPRING_PROFILES_ACTIVE="local"
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Expected result:

- Spring Boot context load হবে।
- PostgreSQL datasource initialize হবে।
- Flyway migration location check করবে।
- Business table create হবে না।
- Maven build success হবে।

এই step-এর verification-এ Flyway local PostgreSQL 17.10 database detect করেছে। `flyway-database-postgresql` যোগ করার পর build success হয়েছে, তবে Flyway warning দিয়েছে যে installed Flyway version officially PostgreSQL 16 পর্যন্ত tested। Learning MVP-এর foundation হিসেবে test/package pass করেছে, তাই আপাতত acceptable; future production-style project হলে Flyway/Spring Boot version compatibility আবার review করতে হবে।

Git status check:

```powershell
git status --short
```

Commit-এর পরে working tree clean থাকা উচিত।

## 12. Git commands used in this step

```powershell
git status --short
git rev-parse --short HEAD
git add .env.example services/backend/pom.xml services/backend/README.md services/backend/src/main/resources/application.yml services/backend/src/main/resources/application-local.yml services/backend/src/main/resources/db/migration/.gitkeep docs/codex-progress.md learning/step-04-postgresql-flyway-foundation.md
git commit -m "step-04: configure PostgreSQL and Flyway foundation"
git push
git status --short
```

## 13. What I learned from this step

এই step থেকে শিখলাম Spring Boot backend-এ PostgreSQL connection কীভাবে environment variable দিয়ে configure করতে হয়, কেন password hardcode করা যাবে না, কেন Hibernate দিয়ে automatic schema update না করে Flyway দিয়ে migration manage করা ভালো, এবং কেন empty migration folder রাখতে `.gitkeep` দরকার। SmartKash এখন database foundation পেয়েছে, কিন্তু business schema বা feature logic এখনো intentionally implement করা হয়নি।
