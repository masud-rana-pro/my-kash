# Step 14: Idempotency Key Database Foundation

## 1. Step title

Step 14 - SmartKash idempotency key database foundation.

## 2. কী implement করা হয়েছে

এই step-এ duplicate money request আটকানোর জন্য idempotency foundation তৈরি করা হয়েছে:

- `idempotency_keys` table তৈরি করা হয়েছে।
- `IdempotencyStatus` enum তৈরি করা হয়েছে।
- `IdempotencyOperationType` enum তৈরি করা হয়েছে।
- `IdempotencyKey` JPA entity তৈরি করা হয়েছে।
- `IdempotencyKeyRepository` তৈরি করা হয়েছে।
- `IdempotencyKeyService` interface তৈরি করা হয়েছে।
- `IdempotencyKeyServiceImpl` foundation service তৈরি করা হয়েছে।
- Database, backend API, security, এবং progress docs update করা হয়েছে।

এই step-এ কোনো Send Money, Add Money, Payment, Recharge, Savings, Loan, wallet balance mutation, বা money-changing API implement করা হয়নি।

## 3. কেন idempotency money-changing API-এর আগে দরকার

Money-changing API-তে একই request একাধিকবার process হলে user-এর টাকা ভুলভাবে দুইবার কাটা বা দুইবার যোগ হতে পারে। উদাহরণ:

- User Send Money button দুইবার tap করল।
- Network timeout হলো, user আবার retry করল।
- Mobile app একই request আবার পাঠাল।
- Backend প্রথম request process করেছে, কিন্তু client response পায়নি।

এই সমস্যা solve করতে প্রতিটি money-changing request-এর সাথে একটি unique `idempotencyKey` পাঠানো হবে। Backend একই user-এর একই key আবার দেখলে নতুন transaction তৈরি করবে না।

## 4. Duplicate request problem example

ধরা যাক user 500 টাকা send করছে:

```text
Request 1: user_id=10, idempotencyKey=abc-123, amount=500
Request 2: user_id=10, idempotencyKey=abc-123, amount=500
```

Correct behavior:

- প্রথম request process হবে।
- দ্বিতীয় request duplicate হিসেবে ধরা হবে।
- backend নতুন ledger/transaction/wallet update করবে না।
- future step-এ আগের saved response return করা যাবে।

## 5. কেন `user_id + idempotency_key` unique

```sql
CONSTRAINT uk_idempotency_keys_user_key
    UNIQUE (user_id, idempotency_key)
```

Block-by-block ব্যাখ্যা:

- `user_id` বলে key কোন authenticated user-এর।
- `idempotency_key` হলো client-generated unique request key।
- `UNIQUE (user_id, idempotency_key)` একই user-এর একই key দ্বিতীয়বার insert হতে দেয় না।
- আলাদা user একই key string ব্যবহার করলে conflict হবে না, কারণ key user-specific।

## 6. কেন request hash useful

```sql
request_hash VARCHAR(128) NOT NULL
```

ব্যাখ্যা:

- Raw request body store করা risky, কারণ সেখানে PIN বা sensitive data থাকতে পারে।
- Request hash রাখলে future retry-এর সময় বোঝা যাবে একই key দিয়ে একই payload এসেছে কি না।
- একই key কিন্তু different amount/receiver হলে backend future step-এ reject করতে পারবে।
- Hash রাখলে sensitive payload database-এ জমা রাখতে হয় না।

## 7. Operation type কী

```java
public enum IdempotencyOperationType {
    ADD_MONEY,
    SEND_MONEY,
    MERCHANT_PAYMENT,
    MOBILE_RECHARGE,
    SAVINGS_DEPOSIT,
    LOAN_DISBURSEMENT
}
```

ব্যাখ্যা:

- `ADD_MONEY` future admin approval বা add money flow-এর জন্য।
- `SEND_MONEY` registered mobile/QR receiver send money flow-এর জন্য।
- `MERCHANT_PAYMENT` merchant wallet payment-এর জন্য।
- `MOBILE_RECHARGE` demo recharge flow-এর জন্য।
- `SAVINGS_DEPOSIT` wallet থেকে savings goal deposit-এর জন্য।
- `LOAN_DISBURSEMENT` future loan wallet credit থাকলে তার জন্য।

## 8. Status কী

```java
public enum IdempotencyStatus {
    PROCESSING,
    COMPLETED,
    FAILED
}
```

ব্যাখ্যা:

- `PROCESSING`: request reserve হয়েছে, কাজ চলছে।
- `COMPLETED`: request successfully শেষ হয়েছে, duplicate retry এলে saved result ব্যবহার করা যাবে।
- `FAILED`: request fail করেছে; future business rule অনুযায়ী retry handling করা যাবে।

## 9. Migration snippet

```sql
CREATE TABLE idempotency_keys (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    idempotency_key VARCHAR(128) NOT NULL,
    request_hash VARCHAR(128) NOT NULL,
    operation_type VARCHAR(40) NOT NULL,
    status VARCHAR(32) NOT NULL,
    response_body TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL
);
```

Block-by-block ব্যাখ্যা:

- `id`: database primary key।
- `user_id`: কোন user request করেছে, users table-এর সাথে link হবে।
- `idempotency_key`: client থেকে আসা unique key।
- `request_hash`: raw request body নয়, request-এর hash।
- `operation_type`: কোন ধরনের money operation।
- `status`: request processing/completed/failed state।
- `response_body`: future duplicate retry response cache করার placeholder।
- `created_at`: key প্রথম তৈরি হওয়ার সময়।
- `updated_at`: status/response update হলে সময়।
- `expires_at`: পুরোনো idempotency key cleanup করার future boundary।

## 10. Entity snippet

```java
@Entity
@Table(
        name = "idempotency_keys",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_idempotency_keys_user_key",
                columnNames = {"user_id", "idempotency_key"}
        )
)
public class IdempotencyKey {
}
```

ব্যাখ্যা:

- `@Entity` class-টিকে JPA entity বানায়।
- `@Table(name = "idempotency_keys")` entity-কে database table-এর সাথে map করে।
- `uniqueConstraints` Java side-এও same uniqueness rule document করে।
- Entity সরাসরি API response হিসেবে return করা হবে না।

```java
@ManyToOne(fetch = FetchType.LAZY, optional = false)
@JoinColumn(name = "user_id", nullable = false)
private User user;
```

ব্যাখ্যা:

- অনেক idempotency key এক user-এর হতে পারে।
- `FetchType.LAZY` user data unnecessary load কমায়।
- `nullable = false` বলে key সবসময় user-linked হতে হবে।

```java
public void markCompleted(String responseBody) {
    this.status = IdempotencyStatus.COMPLETED;
    this.responseBody = responseBody;
}
```

ব্যাখ্যা:

- Future money service successful হলে status `COMPLETED` করবে।
- `responseBody` future retry response replay করার জন্য রাখা যাবে।

## 11. Repository snippet

```java
Optional<IdempotencyKey> findByUser_IdAndIdempotencyKey(Long userId, String idempotencyKey);
```

ব্যাখ্যা:

- Existing key খুঁজতে user id এবং key একসাথে ব্যবহার করা হয়।
- শুধু key দিয়ে খোঁজা safe নয়, কারণ key user-specific।
- `Optional` ব্যবহার করা হয়েছে কারণ key থাকতে বা না-ও থাকতে পারে।

```java
boolean existsByUser_IdAndIdempotencyKey(Long userId, String idempotencyKey);
```

ব্যাখ্যা:

- Duplicate key আছে কি না দ্রুত check করতে future service use করতে পারবে।

## 12. Service foundation snippet

```java
@Transactional
public IdempotencyKey reserve(
        User user,
        String idempotencyKey,
        String requestHash,
        IdempotencyOperationType operationType,
        Instant expiresAt
) {
    return idempotencyKeyRepository.save(
            new IdempotencyKey(user, idempotencyKey, requestHash, operationType, expiresAt)
    );
}
```

Block-by-block ব্যাখ্যা:

- `@Transactional`: reserve operation database transaction-এর মধ্যে চলে।
- `User user`: authenticated persisted user।
- `idempotencyKey`: client request key।
- `requestHash`: duplicate retry compare করার জন্য hash।
- `operationType`: কোন money operation reserve হচ্ছে।
- `expiresAt`: key কতদিন valid থাকবে।
- `save(...)`: database-এ `PROCESSING` status দিয়ে key save করে।

## 13. কেন no money-changing API added

Idempotency foundation money API-এর আগে লাগে, কিন্তু এই step-এর কাজ শুধু foundation। এখনো implement করা হয়নি:

- Add Money approval
- Send Money
- Merchant Payment
- Mobile Recharge
- Savings Deposit
- Wallet balance debit/credit
- Ledger entry creation service
- Transaction creation service

কারণ real money-changing flow শুরু করার আগে wallet lifecycle, audit log, validation, locking, PIN confirmation, এবং transaction boundary একসাথে design করতে হবে।

## 14. Future SmartKash flow-তে কীভাবে use হবে

Future Send Money flow:

1. Flutter request পাঠাবে: amount, receiver, PIN, `idempotencyKey`।
2. Backend authenticated user resolve করবে।
3. Backend request hash তৈরি করবে।
4. Backend `idempotency_keys` table-এ same user/key আছে কি না check করবে।
5. না থাকলে key reserve করবে।
6. PIN, balance, receiver, wallet status validate করবে।
7. Wallet update, transaction record, ledger entries এক transaction-এ তৈরি করবে।
8. Idempotency status `COMPLETED` করবে।
9. Same key retry এলে duplicate transaction তৈরি হবে না।

## 15. Common mistakes and cautions

- Raw PIN বা raw sensitive request body idempotency table-এ রাখা যাবে না।
- শুধু `idempotency_key` unique করলে ভুল হবে; user-specific unique করতে হবে।
- Idempotency ছাড়া money API implement করলে double debit/credit risk থাকে।
- Old Flyway migration edit করা যাবে না; নতুন migration file add করতে হবে।
- Idempotency controller expose করা যাবে না; এটি internal backend concern।
- `FAILED` request retry policy future step-এ carefully define করতে হবে।

## 16. Manual verification commands

Backend:

```cmd
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Database:

```cmd
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\d idempotency_keys
SELECT * FROM flyway_schema_history;
```

General:

```cmd
cd /d D:\github\my-kash
git status
```

## 17. Git commands used

```cmd
git status --short --branch
git diff --check
git add <step-14-files>
git commit -m "step-14: add idempotency key foundation"
git push
```

## 18. এই step থেকে কী শিখলাম

এই step থেকে শিখলাম money-changing API safe করতে শুধু PIN বা balance check যথেষ্ট নয়। Retry, double-click, network timeout, এবং duplicate request থেকেও system protect করতে হয়। Idempotency key user-specific unique হলে একই request বারবার এলেও backend duplicate ledger, transaction, বা wallet update তৈরি করবে না।
