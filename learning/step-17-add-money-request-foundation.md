# Step 17: Add Money Request Foundation

## 1. Step title

Step 17 - SmartKash Add Money request foundation.

## 2. কী implement করা হয়েছে

এই step-এ customer Add Money request create/list করার foundation তৈরি করা হয়েছে:

- `add_money_requests` table তৈরি করা হয়েছে।
- `AddMoneyStatus` enum তৈরি করা হয়েছে।
- `AddMoneySourceType` enum তৈরি করা হয়েছে।
- `AddMoneyRequest` JPA entity তৈরি করা হয়েছে।
- `AddMoneyRequestRepository` তৈরি করা হয়েছে।
- Request/response DTO তৈরি করা হয়েছে।
- Mapper, service, service implementation তৈরি করা হয়েছে।
- `POST /api/add-money/requests` endpoint তৈরি করা হয়েছে।
- `GET /api/add-money/requests` endpoint তৈরি করা হয়েছে।

এই step-এ admin approval/rejection, wallet credit, ledger entry, transaction record, idempotency record, audit log, FCM notification, বা real bank/payment integration implement করা হয়নি।

## 3. কেন Add Money request foundation দরকার

SmartKash MVP zero-budget learning app। এখানে real bank API বা payment gateway থাকবে না। তাই Add Money flow-এর প্রথম ধাপ হলো customer একটি demo/manual request submit করবে। Admin future step-এ request approve/reject করবে।

এই step শুধু request জমা রাখে:

```text
Customer -> Add Money Request -> PENDING
```

Balance এখনো বাড়ে না।

## 4. Migration snippet

```sql
CREATE TABLE add_money_requests (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    source_type VARCHAR(40) NOT NULL,
    status VARCHAR(32) NOT NULL,
    approved_by BIGINT,
    approved_at TIMESTAMPTZ,
    note VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Block-by-block ব্যাখ্যা:

- `id`: Add Money request-এর primary key।
- `user_id`: কোন customer request করেছে।
- `amount`: customer কত টাকা add করতে চায়।
- `source_type`: demo source, যেমন `DEMO_BANK`।
- `status`: request lifecycle, শুরুতে `PENDING`।
- `approved_by`: future admin approval হলে admin user id থাকবে।
- `approved_at`: future approval time।
- `note`: optional customer note।
- `created_at`: request তৈরির সময়।
- `updated_at`: future status update হলে সময়।

## 5. Constraint snippet

```sql
CONSTRAINT chk_add_money_requests_amount_positive
    CHECK (amount > 0)
```

ব্যাখ্যা:

- Add Money amount অবশ্যই positive হতে হবে।
- Zero বা negative amount request করা যাবে না।

```sql
CONSTRAINT chk_add_money_requests_status
    CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))
```

ব্যাখ্যা:

- Database invalid status allow করবে না।
- Java enum আর database check একই lifecycle মানে।

## 6. Enums

```java
public enum AddMoneyStatus {
    PENDING,
    APPROVED,
    REJECTED
}
```

ব্যাখ্যা:

- `PENDING`: customer request করেছে, admin এখনো review করেনি।
- `APPROVED`: future admin approval।
- `REJECTED`: future admin rejection।

```java
public enum AddMoneySourceType {
    DEMO_BANK,
    DEMO_CARD,
    MANUAL
}
```

ব্যাখ্যা:

- এগুলো real bank/card integration নয়।
- MVP learning/demo source বোঝানোর জন্য রাখা হয়েছে।

## 7. Entity snippet

```java
public AddMoneyRequest(User user, BigDecimal amount, AddMoneySourceType sourceType, String note) {
    this.user = user;
    this.amount = amount;
    this.sourceType = sourceType;
    this.status = AddMoneyStatus.PENDING;
    this.note = note;
}
```

Block-by-block ব্যাখ্যা:

- `User user`: authenticated current user।
- `BigDecimal amount`: টাকা/amount-এর জন্য floating point নয়, `BigDecimal` safe।
- `sourceType`: request source enum।
- `status = PENDING`: নতুন request সবসময় pending।
- `note`: optional note।

## 8. Request DTO snippet

```java
public record CreateAddMoneyRequest(
        @NotNull
        @DecimalMin(value = "1.00")
        BigDecimal amount,

        @NotNull
        AddMoneySourceType sourceType,

        @Size(max = 255)
        String note
) {
}
```

ব্যাখ্যা:

- `@NotNull`: amount/sourceType missing হলে validation error।
- `@DecimalMin("1.00")`: minimum request amount 1 টাকা।
- `@Size(max = 255)`: note অনেক বড় হলে reject হবে।
- DTO ব্যবহার করা হয়েছে যাতে entity সরাসরি API input না হয়।

## 9. Service snippet

```java
User user = currentUser(principal);
AddMoneyRequest addMoneyRequest = new AddMoneyRequest(
        user,
        request.amount(),
        request.sourceType(),
        request.note()
);
return addMoneyRequestMapper.toResponse(addMoneyRequestRepository.save(addMoneyRequest));
```

Block-by-block ব্যাখ্যা:

- `currentUser(principal)`: JWT principal থেকে backend current user resolve করে।
- Request body থেকে user id নেওয়া হয় না।
- Entity তৈরি হয় `PENDING` status নিয়ে।
- Repository save করে।
- Mapper entity থেকে response DTO বানায়।

```java
private void ensureActiveUser(User user) {
    if (user.getStatus() != UserStatus.ACTIVE) {
        throw new IllegalArgumentException("Only active users can create Add Money requests.");
    }
}
```

ব্যাখ্যা:

- Blocked বা pending user Add Money request create করতে পারবে না।
- এই validation wallet balance change করে না।
- Future money-changing approval step-এ আরও কঠিন validation লাগবে।

## 10. Controller snippet

```java
@PostMapping
public ResponseEntity<AddMoneyRequestResponse> createRequest(
        @AuthenticationPrincipal JwtPrincipal principal,
        @Valid @RequestBody CreateAddMoneyRequest request
) {
    return ResponseEntity.status(HttpStatus.CREATED)
            .body(addMoneyRequestService.createCurrentUserRequest(principal, request));
}
```

ব্যাখ্যা:

- Controller thin থাকে।
- Authenticated principal নেয়।
- `@Valid` request DTO validation চালায়।
- Business logic service layer-এ থাকে।
- Successful create হলে `201 Created` response দেয়।

## 11. কেন wallet credit হয়নি

Add Money request create মানে টাকা wallet-এ ঢোকা নয়। টাকা add হবে future admin approval step-এ। তখন লাগবে:

- ADMIN role validation
- idempotency key
- wallet locking
- wallet credit
- ledger entry
- transaction record
- audit log
- optional FCM alert

তাই এই step intentionally safe এবং pending request-only।

## 12. SmartKash flow-তে এটি কীভাবে fit করে

1. Customer login করে backend JWT পাবে।
2. Customer Add Money form submit করবে।
3. Backend request save করবে `PENDING` status দিয়ে।
4. Customer নিজের request list দেখতে পারবে।
5. Future admin step request approve/reject করবে।
6. Approval step wallet credit করলে ledger/transaction/audit/idempotency একসাথে use করবে।

## 13. Common mistakes and cautions

- Add Money request create করেই wallet balance বাড়ানো যাবে না।
- Request body থেকে `userId` নেওয়া যাবে না।
- Real bank/payment gateway call করা যাবে না।
- Raw secret বা credential note/details-এ রাখা যাবে না।
- Admin approval flow এই step-এ add করা যাবে না।
- Idempotency এই step-এ wire করা হয়নি, কারণ request create wallet balance change নয়।

## 14. Manual verification commands

Backend:

```cmd
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Database:

```cmd
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\d add_money_requests
SELECT * FROM flyway_schema_history;
```

API check after backend is running:

```cmd
POST /api/add-money/requests
GET /api/add-money/requests
```

General:

```cmd
cd /d D:\github\my-kash
git status
```

## 15. Git commands used

```cmd
git status --short --branch
git diff --check
git add <step-17-files>
git commit -m "step-17: add add money request foundation"
git push
```

## 16. এই step থেকে কী শিখলাম

এই step থেকে শিখলাম financial flow ধাপে ধাপে ভাগ করা জরুরি। Add Money request create করা আর wallet balance credit করা এক জিনিস নয়। Request pending হিসেবে রাখা safe; wallet credit future admin approval step-এ ledger, transaction, idempotency, audit log, এবং locking সহ করা হবে।
