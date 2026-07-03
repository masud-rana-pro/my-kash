# Step 13: Ledger And Transaction Database Foundation

## 1. Step title

Step 13 - SmartKash ledger and transaction database foundation.

## 2. কী implement করা হয়েছে

এই step-এ internal ledger এবং user-facing transaction foundation তৈরি করা হয়েছে:

- `transactions` table তৈরি করা হয়েছে।
- `ledger_entries` table তৈরি করা হয়েছে।
- `TransactionType` enum তৈরি করা হয়েছে।
- `TransactionStatus` enum তৈরি করা হয়েছে।
- `LedgerEntryType` enum তৈরি করা হয়েছে।
- `TransactionRecord` JPA entity তৈরি করা হয়েছে।
- `LedgerEntry` JPA entity তৈরি করা হয়েছে।
- `TransactionRecordRepository` তৈরি করা হয়েছে।
- `LedgerEntryRepository` তৈরি করা হয়েছে।

এই step-এ transaction history API, wallet balance mutation, send money, add money, payment, savings, recharge, loan, idempotency handling, বা money-changing service implement করা হয়নি।

## 3. কেন ledger এবং transaction foundation দরকার

Wallet balance শুধু current amount দেখায়। কিন্তু balance কেন change হলো, কোন operation-এ হলো, debit/credit কীভাবে হলো - এগুলো track করার জন্য ledger লাগে।

SmartKash-এ দুই ধরনের record থাকবে:

- `transactions`: user-facing summary, statement/receipt-এর জন্য।
- `ledger_entries`: internal immutable accounting record, balance correctness-এর জন্য।

## 4. Transaction table

```sql
CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    transaction_reference VARCHAR(64) NOT NULL,
    user_id BIGINT NOT NULL,
    type VARCHAR(40) NOT NULL,
    status VARCHAR(32) NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    counterparty_user_id BIGINT,
    description VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Block-by-block Bangla ব্যাখ্যা:

- `transactions` user-facing record রাখে।
- `transaction_reference` unique business reference।
- `user_id` কোন user-এর transaction তা বোঝায়।
- `type` transaction kind, যেমন `SEND_MONEY`।
- `status` transaction state, যেমন `SUCCESS`।
- `amount` transaction amount।
- `counterparty_user_id` receiver/sender/merchant user হতে পারে।
- `description` short note।
- `created_at` transaction তৈরি হওয়ার সময়।

## 5. Ledger table

```sql
CREATE TABLE ledger_entries (
    id BIGSERIAL PRIMARY KEY,
    wallet_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    transaction_reference VARCHAR(64) NOT NULL,
    linked_entry_id BIGINT,
    entry_type VARCHAR(32) NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    balance_after NUMERIC(19, 2) NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Block-by-block Bangla ব্যাখ্যা:

- `ledger_entries` internal accounting entries রাখে।
- `wallet_id` কোন wallet-এর entry তা বোঝায়।
- `user_id` wallet owner user।
- `transaction_reference` transaction-এর সাথে ledger link করে।
- `linked_entry_id` debit-credit pair link করতে future transfer flow-তে ব্যবহার হবে।
- `entry_type` debit/credit/reversal।
- `amount` entry amount।
- `balance_after` entry create হওয়ার পর wallet balance কত হলো।
- `created_at` immutable creation time।

## 6. Important constraints

```sql
CONSTRAINT uk_transactions_reference UNIQUE (transaction_reference)
```

ব্যাখ্যা:

- প্রতিটি transaction reference unique।
- Ledger entries এই reference দিয়ে user-facing transaction-এর সাথে link হবে।

```sql
CONSTRAINT fk_ledger_entries_transaction_reference
FOREIGN KEY (transaction_reference) REFERENCES transactions (transaction_reference)
```

ব্যাখ্যা:

- Ledger entry কোনো transaction record ছাড়া তৈরি হবে না।
- Money movement হলে user-facing transaction এবং ledger একসাথে থাকতে হবে।

```sql
CONSTRAINT fk_ledger_entries_linked_entry_id
FOREIGN KEY (linked_entry_id) REFERENCES ledger_entries (id)
```

ব্যাখ্যা:

- Send Money/Payment-এর মতো wallet-to-wallet transfer-এ debit entry এবং credit entry link করা যাবে।

```sql
CONSTRAINT chk_ledger_entries_amount_positive CHECK (amount > 0)
```

ব্যাখ্যা:

- Ledger amount always positive থাকে।
- Debit/Credit বোঝানো হয় `entry_type` দিয়ে।

## 7. Enums

```java
public enum TransactionType {
    ADD_MONEY,
    SEND_MONEY,
    RECEIVE_MONEY,
    MERCHANT_PAYMENT,
    SAVINGS_DEPOSIT,
    MOBILE_RECHARGE,
    LOAN_REQUEST
}
```

ব্যাখ্যা:

- Fixed transaction types code-level enum হিসেবে রাখা হয়েছে।
- Typo কমে এবং API/data consistency বাড়ে।

```java
public enum TransactionStatus {
    PENDING,
    SUCCESS,
    FAILED,
    REJECTED,
    CANCELLED
}
```

ব্যাখ্যা:

- Transaction lifecycle state বোঝায়।

```java
public enum LedgerEntryType {
    DEBIT,
    CREDIT,
    REVERSAL
}
```

ব্যাখ্যা:

- `DEBIT` wallet থেকে amount বের হয়।
- `CREDIT` wallet-এ amount ঢোকে।
- `REVERSAL` correction entry।

## 8. TransactionRecord entity

```java
@Entity
@Table(name = "transactions")
public class TransactionRecord {
    @Column(name = "transaction_reference", nullable = false, unique = true, length = 64)
    private String transactionReference;
}
```

ব্যাখ্যা:

- `TransactionRecord` class `transactions` table map করে।
- `transactionReference` business reference হিসেবে unique।
- Entity directly API response হিসেবে return করা হবে না।

## 9. LedgerEntry entity

```java
@Entity
@Table(name = "ledger_entries")
public class LedgerEntry {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "wallet_id", nullable = false)
    private Wallet wallet;
}
```

ব্যাখ্যা:

- `LedgerEntry` wallet-এর সাথে linked।
- এক wallet-এর অনেক ledger entry থাকতে পারে।
- `FetchType.LAZY` unnecessary data load কমায়।

```java
@OneToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "linked_entry_id")
private LedgerEntry linkedEntry;
```

ব্যাখ্যা:

- debit-credit pair বা reversal relation future flow-তে link করতে ব্যবহার হবে।

## 10. Repositories

```java
public interface TransactionRecordRepository extends JpaRepository<TransactionRecord, Long> {
    Optional<TransactionRecord> findByTransactionReference(String transactionReference);
    List<TransactionRecord> findByUserIdOrderByCreatedAtDesc(Long userId);
    boolean existsByTransactionReference(String transactionReference);
}
```

ব্যাখ্যা:

- `findByTransactionReference` receipt/details lookup-এর জন্য।
- `findByUserIdOrderByCreatedAtDesc` future statement list-এর জন্য।
- `existsByTransactionReference` duplicate reference prevent করতে কাজে লাগবে।

```java
public interface LedgerEntryRepository extends JpaRepository<LedgerEntry, Long> {
    List<LedgerEntry> findByWalletIdOrderByCreatedAtDesc(Long walletId);
    List<LedgerEntry> findByTransactionReferenceOrderByCreatedAtAsc(String transactionReference);
}
```

ব্যাখ্যা:

- wallet ledger history এবং transaction-linked ledger entries খুঁজতে future service use করবে।

## 11. কেন API/service তৈরি করা হয়নি

এই step foundation only। Ledger/transaction record create করা money-changing operation-এর অংশ। সেটা করার আগে লাগবে:

- wallet creation lifecycle
- idempotency key
- wallet locking strategy
- transaction boundary
- audit log
- feature-specific validation

তাই এখন শুধু schema/entity/repository।

## 12. Immutable ledger rule

Ledger entries update/delete করা যাবে না। Correction করতে হলে reversal ledger entry লাগবে। এই step entity-তে setters দেয়নি, যাতে accidental mutation কমে। Future service layer-এও ledger update/delete operation রাখা যাবে না।

## 13. SmartKash flow-তে এটি কীভাবে fit করে

1. Wallet table balance read model রাখে।
2. Future Add Money/Send Money/Payment wallet balance change করবে।
3. একই database transaction-এ user-facing `transactions` row তৈরি হবে।
4. একই transaction reference দিয়ে one or more `ledger_entries` তৈরি হবে।
5. Wallet balance, ledger, transaction একসাথে consistent থাকবে।

## 14. Common mistakes and cautions

- Ledger entry amount negative রাখা যাবে না।
- Debit/Credit বোঝাতে negative amount নয়, `entry_type` ব্যবহার করতে হবে।
- Transaction record ছাড়া ledger entry তৈরি করা যাবে না।
- Ledger update/delete করা যাবে না।
- Balance update ledger ছাড়া করা যাবে না।
- এই step-এ API না থাকায় manual API test নেই।

## 15. Manual verification commands

Backend:

```cmd
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Optional runtime check:

```cmd
.\mvnw.cmd spring-boot:run
```

Database check:

```cmd
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\d transactions
\d ledger_entries
SELECT * FROM transactions;
SELECT * FROM ledger_entries;
SELECT * FROM flyway_schema_history;
```

General:

```cmd
cd /d D:\github\my-kash
git status
```

## 16. Git commands used

```cmd
git status --short --branch
git diff --check
git add <step-13-files>
git commit -m "step-13: add ledger transaction foundation"
git push
```

## 17. এই step থেকে কী শিখলাম

এই step-এ শিখলাম wallet balance system শুধু balance column দিয়ে safe হয় না। User-facing transaction record আর internal immutable ledger entry আলাদা রাখা দরকার। Ledger accounting correctness দেয়, আর transaction statement/receipt-এর জন্য user-friendly summary দেয়।
