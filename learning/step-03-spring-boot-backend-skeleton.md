# Step 03: Spring Boot Backend Skeleton

## 1. Step title

Step 03: SmartKash Spring Boot backend skeleton তৈরি।

## 2. কী implement করা হয়েছে

এই step-এ `services/backend/` folder-এর ভিতরে SmartKash backend skeleton তৈরি করা হয়েছে।

তৈরি করা হয়েছে:

- Maven project file: `pom.xml`
- Java 21 Spring Boot entrypoint: `SmartKashBackendApplication.java`
- base config: `application.yml`
- local placeholder config: `application-local.yml`
- context-load test class
- backend README
- Maven Wrapper files
- planned package structure marker files
- `docs/codex-progress.md` update
- এই Bangla learning file

এই step-এ intentionally তৈরি করা হয়নি:

- business REST API
- Firebase Auth verify logic
- JWT issue/verify logic
- wallet logic
- transaction/ledger logic
- PostgreSQL schema
- Flyway migration scripts
- admin pages
- real security configuration
- controllers/services/repositories/entities/DTOs/mappers/enums

## 3. কেন এই step দরকার

SmartKash backend ভবিষ্যতে Flutter app-এর main API server হবে। Auth, wallet, ledger, transaction, add money, send money, merchant payment, savings, loan, recharge, notification, admin সব backend দিয়ে চলবে।

এই step-এ শুধু backend foundation তৈরি করা হয়েছে, যাতে পরের step-গুলোতে ছোট ছোট অংশে implementation করা যায়:

- Step 04: PostgreSQL এবং Flyway foundation
- Step 05: Firebase Auth foundation
- পরে: JWT, security, user, wallet, ledger, transactions

## 4. Final backend folder/package structure

```text
services/backend/
├── .mvn/wrapper/
│   ├── maven-wrapper.jar
│   └── maven-wrapper.properties
├── mvnw.cmd
├── pom.xml
├── README.md
└── src/
    ├── main/
    │   ├── java/com/smartkash/
    │   │   ├── SmartKashBackendApplication.java
    │   │   ├── addmoney/package-info.java
    │   │   ├── admin/package-info.java
    │   │   ├── audit/package-info.java
    │   │   ├── auth/package-info.java
    │   │   ├── common/package-info.java
    │   │   ├── common/exception/package-info.java
    │   │   ├── common/response/package-info.java
    │   │   ├── common/util/package-info.java
    │   │   ├── config/package-info.java
    │   │   ├── firebase/package-info.java
    │   │   ├── ledger/package-info.java
    │   │   ├── loan/package-info.java
    │   │   ├── merchant/package-info.java
    │   │   ├── notification/package-info.java
    │   │   ├── payment/package-info.java
    │   │   ├── recharge/package-info.java
    │   │   ├── savings/package-info.java
    │   │   ├── security/package-info.java
    │   │   ├── sendmoney/package-info.java
    │   │   ├── transaction/package-info.java
    │   │   ├── user/package-info.java
    │   │   └── wallet/package-info.java
    │   └── resources/
    │       ├── application.yml
    │       └── application-local.yml
    └── test/java/com/smartkash/
        └── SmartKashBackendApplicationTests.java
```

## 5. Files/folders created or changed

Created:

- `services/backend/pom.xml`
- `services/backend/.mvn/wrapper/maven-wrapper.jar`
- `services/backend/.mvn/wrapper/maven-wrapper.properties`
- `services/backend/mvnw.cmd`
- `services/backend/README.md`
- `services/backend/src/main/java/com/smartkash/SmartKashBackendApplication.java`
- `services/backend/src/main/resources/application.yml`
- `services/backend/src/main/resources/application-local.yml`
- `services/backend/src/test/java/com/smartkash/SmartKashBackendApplicationTests.java`
- backend package marker files: `package-info.java`
- `learning/step-03-spring-boot-backend-skeleton.md`

Changed:

- `.gitignore`
- `docs/codex-progress.md`

Removed:

- `services/backend/.gitkeep`, because the backend folder now has real project files.

## 6. Important code/config snippets

### `pom.xml` project identity

```xml
<groupId>com.smartkash</groupId>
<artifactId>smartkash-backend</artifactId>
<version>0.1.0-SNAPSHOT</version>
<name>SmartKash Backend</name>
```

### Java version

```xml
<java.version>21</java.version>
```

### Spring Boot dependencies

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
```

### Backend app entrypoint

```java
package com.smartkash;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SmartKashBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(SmartKashBackendApplication.class, args);
    }
}
```

### `application.yml`

```yaml
spring:
  application:
    name: smartkash-backend
  profiles:
    default: local
  autoconfigure:
    exclude:
      - org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
      - org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration
      - org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration
```

### `application-local.yml`

```yaml
smartkash:
  security:
    jwt:
      secret: ${JWT_SECRET:change-me-in-local-env}
  firebase:
    project-id: ${FIREBASE_PROJECT_ID:}
    client-email: ${FIREBASE_CLIENT_EMAIL:}
    private-key: ${FIREBASE_PRIVATE_KEY:}
  fcm:
    enabled: ${FCM_ENABLED:false}
```

### Test class

```java
@SpringBootTest
class SmartKashBackendApplicationTests {

    @Test
    void contextLoads() {
    }
}
```

### Package marker example

```java
package com.smartkash.wallet;
```

## 7. Line-by-line বা block-by-block Bangla explanation

### `pom.xml`

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.3.7</version>
</parent>
```

এখানে Spring Boot parent POM ব্যবহার করা হয়েছে। এটি dependency versions এবং Maven plugin defaults manage করে।

```xml
<groupId>com.smartkash</groupId>
```

এটি project-এর Java/Maven group identity। Backend root package `com.smartkash`-এর সাথে মিল রাখা হয়েছে।

```xml
<artifactId>smartkash-backend</artifactId>
```

এটি Maven artifact name। Build করলে jar name এই artifact ID থেকে তৈরি হয়।

```xml
<java.version>21</java.version>
```

Backend Java 21 ব্যবহার করবে, কারণ user requirement ছিল Java 21।

```xml
<firebase-admin.version>9.4.3</firebase-admin.version>
<jjwt.version>0.12.6</jjwt.version>
<springdoc.version>2.6.0</springdoc.version>
```

এই dependencies Spring Boot parent manage করে না, তাই versions property হিসেবে রাখা হয়েছে।

### `SmartKashBackendApplication.java`

```java
package com.smartkash;
```

Backend root package। সব backend package এই root-এর নিচে থাকবে।

```java
@SpringBootApplication
```

এটি Spring Boot app marker annotation। এর মাধ্যমে component scan, auto configuration, এবং configuration support চালু হয়।

```java
SpringApplication.run(SmartKashBackendApplication.class, args);
```

এটি Spring Boot application start করে।

### `application.yml`

```yaml
spring.application.name: smartkash-backend
```

Application name define করে। Logs/actuator-এ backend identify করতে সাহায্য করে।

```yaml
profiles.default: local
```

Default profile local রাখা হয়েছে, যাতে local placeholder config load হয়।

```yaml
autoconfigure.exclude
```

DataSource/JPA/Flyway auto configuration আপাতত exclude করা হয়েছে, কারণ এই step-এ database schema বা real DB connection configure করা হয়নি। Step 04-এ PostgreSQL/Flyway foundation করার সময় এটি revisit করা হবে।

### `application-local.yml`

```yaml
secret: ${JWT_SECRET:change-me-in-local-env}
```

JWT secret environment variable থেকে আসবে। Real secret source code-এ রাখা যাবে না।

```yaml
project-id: ${FIREBASE_PROJECT_ID:}
client-email: ${FIREBASE_CLIENT_EMAIL:}
private-key: ${FIREBASE_PRIVATE_KEY:}
```

Firebase config environment variable placeholder। Step 03-এ Firebase logic implement করা হয়নি।

```yaml
enabled: ${FCM_ENABLED:false}
```

FCM notification default off। Future deployment/config ছাড়া notification send করা হবে না।

```yaml
spring.datasource.url: ${DATABASE_URL:jdbc:postgresql://localhost:5432/smartkash}
```

PostgreSQL URL placeholder। Real database setup Step 04 বা later step-এ হবে।

```yaml
spring.flyway.enabled: false
```

Flyway dependency আছে, কিন্তু migration script এখনো নেই। তাই Step 03-এ Flyway disabled রাখা হয়েছে।

### Test class

```java
@SpringBootTest
```

Spring application context load করে test চালায়।

```java
void contextLoads() {
}
```

এই empty test নিশ্চিত করে backend skeleton start হতে পারে।

### Package markers

`package-info.java` files empty package structure Git-এ রাখার জন্য। এগুলো real business class নয়। Future step-এ একই package-এর ভিতরে controller, service, repository, entity, dto, mapper, enums যোগ হবে।

## 8. Dependencies কেন include করা হয়েছে

- Spring Web: REST API এবং future admin/web endpoints তৈরির জন্য।
- Spring Security: Firebase/JWT/PIN security flow future-এ protect করার জন্য।
- Spring Data JPA/Hibernate: PostgreSQL database entity/repository access-এর জন্য।
- PostgreSQL Driver: PostgreSQL database connection-এর জন্য।
- Lombok: boilerplate কমানোর জন্য, যেমন DTO/entity getter/setter future-এ।
- Validation: request DTO validation-এর জন্য।
- Flyway: versioned database migration-এর জন্য।
- Actuator: health check এবং basic operational endpoint-এর জন্য।
- OpenAPI/Swagger: API documentation UI-এর জন্য।
- Firebase Admin SDK: Firebase ID token verify এবং FCM notification future integration-এর জন্য।
- JWT library: backend JWT issue/verify future security flow-এর জন্য।

## 9. কেন business APIs এই step-এ implement করা হয়নি

এই step-এর scope backend skeleton এবং build verification। Business APIs এখন করলে project এক step-এ বড় হয়ে যাবে। SmartKash workflow অনুযায়ী ছোট focused steps দরকার। তাই controller, service, repository, entity, DTO, mapper, enum এখনো তৈরি করা হয়নি।

## 10. SmartKash architecture-এ এই backend skeleton কীভাবে fit করে

Flutter app `apps/mobile/` থেকে future-এ Spring Boot backend call করবে। Backend `services/backend/` থেকে auth, wallet, ledger, transaction, payment, savings, loan, recharge, notification, admin logic চালাবে। PostgreSQL main business database হবে। Firebase শুধু test OTP/auth identity এবং important FCM alerts-এর জন্য থাকবে।

এই skeleton future architecture-এর backend foundation তৈরি করেছে।

## 11. Common mistakes and cautions

- `enum` package name ব্যবহার করা যাবে না; Java keyword হওয়ায় `enums` ব্যবহার করতে হবে।
- Real DB password, Firebase private key, JWT secret config file-এ hardcode করা যাবে না।
- `target/` build output commit করা যাবে না।
- `.env` commit করা যাবে না।
- Firebase service account JSON commit করা যাবে না।
- Step 03-এ Flyway migration script তৈরি করা যাবে না।
- Step 03-এ controller/service/repository/entity business class তৈরি করা যাবে না।
- Spring Security default generated password warning development skeleton-এর জন্য expected; real security config future step-এ হবে।
- Global `mvn` না থাকলে `mvnw.cmd` ব্যবহার করতে হবে।

## 12. কীভাবে verify করতে হবে

Global Maven check:

```powershell
mvn test
```

এই machine-এ `mvn` PATH-এ ছিল না, তাই command fail করেছে।

Maven Wrapper test:

```powershell
.\mvnw.cmd test
```

Spring context-load test pass করেছে। Result: `BUILD SUCCESS`, `Tests run: 1, Failures: 0, Errors: 0`.

Package verification:

```powershell
.\mvnw.cmd -q -DskipTests package
```

Backend jar compile/package verification pass করেছে।

Ignore rule verification:

```powershell
git check-ignore -v services/backend/target/smartkash-backend-0.1.0-SNAPSHOT.jar services/backend/.env firebase-service-account-prod.json
```

এটি confirm করে build output, `.env`, এবং Firebase service JSON ignored।

## 13. Git commands used in this step

```powershell
git status --short
git add .gitignore services/backend docs/codex-progress.md learning/step-03-spring-boot-backend-skeleton.md
git commit -m "step-03: add Spring Boot backend skeleton"
git push
git log -1 --oneline
```

Verification commands:

```powershell
mvn test
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
git check-ignore -v services/backend/target/smartkash-backend-0.1.0-SNAPSHOT.jar services/backend/.env firebase-service-account-prod.json
```

## 14. What I learned from this step

এই step থেকে শিখলাম Spring Boot backend skeleton কীভাবে Maven project হিসেবে তৈরি করতে হয়। `pom.xml` dependency manage করে, `SmartKashBackendApplication` app start করে, `application.yml` base config রাখে, `application-local.yml` environment-based placeholder রাখে, আর package markers future module structure ধরে রাখে। Global Maven না থাকলেও Maven Wrapper দিয়ে build/test চালানো যায়। SmartKash backend এখন buildable skeleton, কিন্তু business feature এখনো implement করা হয়নি।

