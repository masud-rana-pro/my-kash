# Step 16: Admin Audit Log Foundation

## 1. Step title

Step 16 - SmartKash admin audit log foundation.

## 2. কী implement করা হয়েছে

এই step-এ future admin action tracking-এর foundation তৈরি করা হয়েছে:

- `admin_audit_logs` table তৈরি করা হয়েছে।
- `AuditAction` enum তৈরি করা হয়েছে।
- `AuditTargetType` enum তৈরি করা হয়েছে।
- `AdminAuditLog` JPA entity তৈরি করা হয়েছে।
- `AdminAuditLogRepository` তৈরি করা হয়েছে।
- `AdminAuditLogService` interface তৈরি করা হয়েছে।
- `AdminAuditLogServiceImpl` internal helper service তৈরি করা হয়েছে।
- Admin, database, backend API, security, এবং progress docs update করা হয়েছে।

এই step-এ কোনো admin API, approval/rejection API, Add Money, Loan, wallet credit/debit, ledger write, transaction write, বা Flutter UI implement করা হয়নি।

## 3. কেন audit log দরকার

Financial-style learning app-এ admin actions track করা জরুরি। যেমন:

- কে Add Money approve করল?
- কে Add Money reject করল?
- কে Loan approve/reject করল?
- কে user বা merchant status change করল?

Audit log থাকলে future debugging, accountability, এবং security review সহজ হয়।

## 4. Migration snippet

```sql
CREATE TABLE admin_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    admin_user_id BIGINT NOT NULL,
    action VARCHAR(64) NOT NULL,
    target_type VARCHAR(64) NOT NULL,
    target_id VARCHAR(128),
    details TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Block-by-block ব্যাখ্যা:

- `id`: audit log row-এর primary key।
- `admin_user_id`: কোন admin action করেছে, `users` table-এর সাথে link।
- `action`: কী action হয়েছে, যেমন `ADD_MONEY_APPROVE`।
- `target_type`: কোন resource-এর উপর action হয়েছে, যেমন `LOAN_REQUEST`।
- `target_id`: target resource-এর id বা reference।
- `details`: extra context, future service চাইলে JSON/text রাখতে পারবে।
- `created_at`: action কখন record হয়েছে।

## 5. Constraints snippet

```sql
CONSTRAINT fk_admin_audit_logs_admin_user_id
    FOREIGN KEY (admin_user_id) REFERENCES users (id)
```

ব্যাখ্যা:

- Audit log সবসময় persisted admin user-এর সাথে linked।
- Unknown/non-existing admin id দিয়ে audit log তৈরি করা যাবে না।

```sql
CONSTRAINT chk_admin_audit_logs_action
    CHECK (action IN (
        'ADD_MONEY_APPROVE',
        'ADD_MONEY_REJECT',
        'LOAN_APPROVE',
        'LOAN_REJECT',
        'USER_STATUS_CHANGE',
        'MERCHANT_STATUS_CHANGE'
    ))
```

ব্যাখ্যা:

- Database level-এ allowed action list define করা হয়েছে।
- Typo বা invalid action insert হওয়ার risk কমে।

## 6. AuditAction enum

```java
public enum AuditAction {
    ADD_MONEY_APPROVE,
    ADD_MONEY_REJECT,
    LOAN_APPROVE,
    LOAN_REJECT,
    USER_STATUS_CHANGE,
    MERCHANT_STATUS_CHANGE
}
```

ব্যাখ্যা:

- Admin কোন ধরনের action করেছে তা enum দিয়ে fixed রাখা হয়েছে।
- Future service code string typo না করে enum ব্যবহার করবে।
- MVP admin scope-এর গুরুত্বপূর্ণ state-changing action রাখা হয়েছে।

## 7. AuditTargetType enum

```java
public enum AuditTargetType {
    ADD_MONEY_REQUEST,
    LOAN_REQUEST,
    USER,
    MERCHANT
}
```

ব্যাখ্যা:

- `ADD_MONEY_REQUEST`: add money approval/rejection target।
- `LOAN_REQUEST`: loan approval/rejection target।
- `USER`: user status change target।
- `MERCHANT`: merchant status change target।

## 8. AdminAuditLog entity snippet

```java
@Entity
@Table(name = "admin_audit_logs")
public class AdminAuditLog {
}
```

ব্যাখ্যা:

- `@Entity` JPA entity হিসেবে class register করে।
- `@Table` database table mapping করে।
- Entity সরাসরি API response হিসেবে expose করা হবে না।

```java
@ManyToOne(fetch = FetchType.LAZY, optional = false)
@JoinColumn(name = "admin_user_id", nullable = false)
private User adminUser;
```

ব্যাখ্যা:

- অনেক audit log এক admin user-এর হতে পারে।
- `FetchType.LAZY` unnecessary user data load কমায়।
- `nullable = false` audit log কে admin user ছাড়া save হতে দেয় না।

```java
@PrePersist
void prePersist() {
    createdAt = Instant.now();
}
```

ব্যাখ্যা:

- Entity save হওয়ার আগে Java side থেকে creation time set করে।
- Database default থাকলেও entity object-এর `createdAt` value consistent থাকে।

## 9. Repository snippet

```java
List<AdminAuditLog> findByAdminUser_IdOrderByCreatedAtDesc(Long adminUserId);
```

ব্যাখ্যা:

- কোনো admin-এর action history দেখার জন্য future admin API use করতে পারবে।

```java
List<AdminAuditLog> findByTargetTypeAndTargetIdOrderByCreatedAtDesc(
        AuditTargetType targetType,
        String targetId
);
```

ব্যাখ্যা:

- নির্দিষ্ট Add Money request বা Loan request-এর audit trail খুঁজতে কাজে লাগবে।

## 10. Service snippet

```java
@Transactional
public AdminAuditLog recordAdminAction(
        User adminUser,
        AuditAction action,
        AuditTargetType targetType,
        String targetId,
        String details
) {
    return adminAuditLogRepository.save(
            new AdminAuditLog(adminUser, action, targetType, targetId, details)
    );
}
```

Block-by-block ব্যাখ্যা:

- `@Transactional`: audit log save database transaction-এর মধ্যে হয়।
- `adminUser`: authenticated admin user entity।
- `action`: admin কী করেছে।
- `targetType`: কোন ধরনের resource target ছিল।
- `targetId`: target resource id/reference।
- `details`: optional extra information।
- `save(...)`: audit log database-এ persist করে।

## 11. কেন admin API implement করা হয়নি

এই step foundation only। এখনো তৈরি করা হয়নি:

- `GET /admin/audit-logs`
- Add Money approval/rejection API
- Loan approval/rejection API
- Admin web pages
- Admin role-protected route integration

কারণ আগে audit log storage foundation দরকার, তারপর feature-specific admin flows ধাপে ধাপে যুক্ত করা হবে।

## 12. SmartKash flow-তে এটি কীভাবে fit করে

Future Add Money approval flow:

1. Admin authenticated হবে।
2. Backend admin role validate করবে।
3. Add Money request pending কি না check করবে।
4. Wallet credit/ledger/transaction/idempotency safe flow হবে।
5. `AdminAuditLogService.recordAdminAction(...)` call হবে।
6. `admin_audit_logs` table-এ record থাকবে কে approve করেছে।

Future Loan rejection flow:

1. Admin loan request reject করবে।
2. Loan status update হবে।
3. Audit log record হবে।

## 13. Common mistakes and cautions

- Customer/Merchant user দিয়ে admin audit action record করা যাবে না; future service-এ ADMIN role validate করতে হবে।
- Audit log edit/delete করা উচিত নয়।
- Sensitive data, raw PIN, JWT, Firebase private key, বা secret details field-এ রাখা যাবে না।
- Audit foundation থাকলেই admin API তৈরি হয়ে যায় না।
- Money-changing flow-এর audit log ledger/transaction/idempotency-এর replacement নয়; এগুলো একসাথে কাজ করবে।

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
\d admin_audit_logs
SELECT * FROM flyway_schema_history;
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
git add <step-16-files>
git commit -m "step-16: add admin audit log foundation"
git push
```

## 16. এই step থেকে কী শিখলাম

এই step থেকে শিখলাম admin action tracking financial-style system-এর accountability বাড়ায়। Audit log future approval/rejection flow-এ কে কী action করেছে তা ধরে রাখবে। তবে audit log money ledger-এর replacement নয়; wallet balance change হলে ledger, transaction, idempotency, PIN validation, এবং audit log একসাথে ব্যবহার করতে হবে।
