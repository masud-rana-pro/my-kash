# Step 18: Merchant Profile Foundation

## 1. Step title

Step 18 - SmartKash merchant profile foundation.

## 2. কী implement করা হয়েছে

এই step-এ merchant profile foundation তৈরি করা হয়েছে:

- `merchants` table তৈরি করা হয়েছে।
- `MerchantStatus` enum তৈরি করা হয়েছে।
- `Merchant` JPA entity তৈরি করা হয়েছে।
- `MerchantRepository` তৈরি করা হয়েছে।
- Merchant request/response DTO তৈরি করা হয়েছে।
- Mapper, service, service implementation তৈরি করা হয়েছে।
- `POST /api/merchants/me` endpoint তৈরি করা হয়েছে।
- `GET /api/merchants/me` endpoint তৈরি করা হয়েছে।
- Current user merchant profile create করলে `users.role` `MERCHANT` করা হচ্ছে।

এই step-এ merchant payment, wallet debit/credit, ledger entry, transaction record, settlement, QR payment, বা admin merchant management implement করা হয়নি।

## 3. কেন merchant foundation দরকার

SmartKash-এ merchant payment করার আগে merchant account model দরকার। Plan অনুযায়ী:

```text
users.role = MERCHANT
wallets.user_id -> users.id
merchants.user_id -> users.id
```

অর্থাৎ merchant আলাদা auth identity নয়; merchant-ও একধরনের user, যার role `MERCHANT` এবং business-specific info `merchants` table-এ থাকে।

## 4. Migration snippet

```sql
CREATE TABLE merchants (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    business_name VARCHAR(120) NOT NULL,
    merchant_number VARCHAR(32) NOT NULL,
    business_type VARCHAR(80) NOT NULL,
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Block-by-block ব্যাখ্যা:

- `id`: merchant row primary key।
- `user_id`: merchant কোন user account-এর সাথে linked।
- `business_name`: দোকান/ব্যবসার নাম।
- `merchant_number`: payment করার সময় merchant identify করার number।
- `business_type`: ব্যবসার ধরন।
- `status`: merchant active/inactive/blocked state।
- `created_at`, `updated_at`: record timing।

## 5. Constraints

```sql
CONSTRAINT uk_merchants_user_id UNIQUE (user_id)
```

ব্যাখ্যা:

- এক user-এর একটিই merchant profile থাকবে।

```sql
CONSTRAINT uk_merchants_merchant_number UNIQUE (merchant_number)
```

ব্যাখ্যা:

- merchant number unique না হলে payment receiver resolve করা যাবে না।

## 6. Entity and role snippet

```java
public void makeMerchant() {
    this.role = UserRole.MERCHANT;
}
```

ব্যাখ্যা:

- User entity-তে role update করার ছোট method।
- Merchant profile create হলে user role `MERCHANT` হয়।
- Complex role/permission system যোগ করা হয়নি।

```java
public Merchant(User user, String businessName, String merchantNumber, String businessType, MerchantStatus status) {
    this.user = user;
    this.businessName = businessName;
    this.merchantNumber = merchantNumber;
    this.businessType = businessType;
    this.status = status;
}
```

ব্যাখ্যা:

- Merchant business-specific data রাখে।
- Wallet data এখানে নেই; wallet আলাদা `wallets` table-এ থাকে।

## 7. Service flow snippet

```java
User user = currentUser(principal);
ensureActiveUser(user);
ensureMerchantDoesNotExist(user.getId());
ensureMerchantNumberIsUnique(request.merchantNumber());

user.makeMerchant();
userRepository.save(user);
```

ব্যাখ্যা:

- Current authenticated user resolve করা হয়।
- blocked/pending user merchant হতে পারে না।
- একই user-এর duplicate merchant profile আটকানো হয়।
- merchant number duplicate হলে reject করা হয়।
- user role `MERCHANT` করা হয়।

## 8. Controller snippet

```java
@PostMapping("/me")
public ResponseEntity<MerchantResponse> createCurrentUserMerchant(
        @AuthenticationPrincipal JwtPrincipal principal,
        @Valid @RequestBody CreateMerchantRequest request
) {
    return ResponseEntity.status(HttpStatus.CREATED)
            .body(merchantService.createCurrentUserMerchant(principal, request));
}
```

ব্যাখ্যা:

- Controller thin।
- User id request body থেকে নেওয়া হয় না।
- DTO validation হয়।
- Business logic service layer-এ থাকে।

## 9. কেন payment implement করা হয়নি

Merchant profile তৈরি করা আর merchant payment করা আলাদা ব্যাপার। Payment future money-changing operation, যেখানে লাগবে:

- payer wallet validation
- merchant wallet validation
- PIN confirmation
- idempotency key
- wallet locking
- debit/credit ledger entries
- transaction records

এই step শুধু merchant identity/business profile foundation।

## 10. Manual verification commands

Backend:

```cmd
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Database:

```cmd
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\d merchants
SELECT * FROM flyway_schema_history;
```

API check after backend is running:

```cmd
POST /api/merchants/me
GET /api/merchants/me
```

Expected API create body:

```json
{
  "businessName": "Masud Store",
  "merchantNumber": "12345678",
  "businessType": "Retail"
}
```

## 11. Expected output

- `.\mvnw.cmd test` should show `BUILD SUCCESS`.
- `.\mvnw.cmd -q -DskipTests package` should finish without errors.
- `\d merchants` should show columns: `id`, `user_id`, `business_name`, `merchant_number`, `business_type`, `status`, `created_at`, `updated_at`.
- Successful merchant create response should return `status: "ACTIVE"` and the same `merchantNumber`.
- Repeating the same create request should fail because one user can have only one merchant profile.
- `git status` should show only local `application-local.yml` if it remains changed.

## 12. Git commands used

```cmd
git status --short --branch
git diff --check
git add <step-18-files>
git commit -m "step-18: add merchant profile foundation"
git push
```

## 13. এই step থেকে কী শিখলাম

এই step থেকে শিখলাম merchant user আলাদা auth system নয়। একই `users` row role `MERCHANT` পায়, আর business-specific data `merchants` table-এ থাকে। Payment এখনও করা হয়নি, কারণ payment money-changing operation এবং সেটার জন্য ledger, transaction, idempotency, PIN, locking একসাথে লাগবে।
