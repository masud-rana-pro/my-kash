\if :{?seed_pin_hash}
\else
\echo 'ERROR: seed_pin_hash psql variable is required.'
\echo 'Example: psql -v seed_pin_hash="''<BCrypt hash for PIN 12345>''" -f scripts/dev/seed-e2e-data.sql'
\quit 1
\endif

BEGIN;

INSERT INTO users (
    firebase_uid,
    mobile_number,
    role,
    status,
    pin_hash,
    pin_set,
    pin_updated_at
)
VALUES (
    'seed-admin-001',
    '+8801600000001',
    'ADMIN',
    'ACTIVE',
    :seed_pin_hash,
    TRUE,
    CURRENT_TIMESTAMP
)
ON CONFLICT (firebase_uid) DO UPDATE
SET role = EXCLUDED.role,
    status = EXCLUDED.status,
    pin_hash = EXCLUDED.pin_hash,
    pin_set = EXCLUDED.pin_set,
    pin_updated_at = EXCLUDED.pin_updated_at,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO users (
    firebase_uid,
    mobile_number,
    role,
    status,
    pin_hash,
    pin_set,
    pin_updated_at
)
SELECT
    'seed-customer-' || lpad(gs::text, 3, '0'),
    '+88017' || lpad(gs::text, 8, '0'),
    'CUSTOMER',
    'ACTIVE',
    :seed_pin_hash,
    TRUE,
    CURRENT_TIMESTAMP
FROM generate_series(1, 15) AS gs
ON CONFLICT (firebase_uid) DO UPDATE
SET role = EXCLUDED.role,
    status = EXCLUDED.status,
    pin_hash = EXCLUDED.pin_hash,
    pin_set = EXCLUDED.pin_set,
    pin_updated_at = EXCLUDED.pin_updated_at,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO users (
    firebase_uid,
    mobile_number,
    role,
    status,
    pin_hash,
    pin_set,
    pin_updated_at
)
SELECT
    'seed-merchant-user-' || lpad(gs::text, 3, '0'),
    '+88018' || lpad(gs::text, 8, '0'),
    'MERCHANT',
    'ACTIVE',
    :seed_pin_hash,
    TRUE,
    CURRENT_TIMESTAMP
FROM generate_series(1, 15) AS gs
ON CONFLICT (firebase_uid) DO UPDATE
SET role = EXCLUDED.role,
    status = EXCLUDED.status,
    pin_hash = EXCLUDED.pin_hash,
    pin_set = EXCLUDED.pin_set,
    pin_updated_at = EXCLUDED.pin_updated_at,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO user_profiles (user_id, full_name, email, avatar_url)
SELECT
    id,
    CASE
        WHEN firebase_uid = 'seed-admin-001' THEN 'Seed Admin'
        WHEN firebase_uid LIKE 'seed-customer-%' THEN 'Seed Customer ' || right(firebase_uid, 3)
        ELSE 'Seed Merchant ' || right(firebase_uid, 3)
    END,
    firebase_uid || '@smartkash.local',
    'https://example.com/smartkash/avatar/' || firebase_uid || '.png'
FROM users
WHERE firebase_uid = 'seed-admin-001'
   OR firebase_uid LIKE 'seed-customer-%'
   OR firebase_uid LIKE 'seed-merchant-user-%'
ON CONFLICT (user_id) DO UPDATE
SET full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    avatar_url = EXCLUDED.avatar_url,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO wallets (user_id, balance, currency, status)
SELECT
    id,
    CASE
        WHEN role = 'CUSTOMER' THEN 10000.00 + CAST(right(firebase_uid, 3) AS INTEGER)
        WHEN role = 'MERCHANT' THEN 5000.00 + CAST(right(firebase_uid, 3) AS INTEGER)
        ELSE 0.00
    END,
    'BDT',
    'ACTIVE'
FROM users
WHERE firebase_uid = 'seed-admin-001'
   OR firebase_uid LIKE 'seed-customer-%'
   OR firebase_uid LIKE 'seed-merchant-user-%'
ON CONFLICT (user_id) DO UPDATE
SET balance = EXCLUDED.balance,
    currency = EXCLUDED.currency,
    status = EXCLUDED.status,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO merchants (user_id, business_name, merchant_number, business_type, status)
SELECT
    u.id,
    'Seed Merchant Business ' || lpad(gs::text, 3, '0'),
    'MERCH-' || lpad(gs::text, 3, '0'),
    CASE (gs - 1) % 5
        WHEN 0 THEN 'Grocery'
        WHEN 1 THEN 'Pharmacy'
        WHEN 2 THEN 'Restaurant'
        WHEN 3 THEN 'Electronics'
        ELSE 'Education'
    END,
    'ACTIVE'
FROM generate_series(1, 15) AS gs
JOIN users u ON u.firebase_uid = 'seed-merchant-user-' || lpad(gs::text, 3, '0')
ON CONFLICT (user_id) DO UPDATE
SET business_name = EXCLUDED.business_name,
    merchant_number = EXCLUDED.merchant_number,
    business_type = EXCLUDED.business_type,
    status = EXCLUDED.status,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO transactions (
    transaction_reference,
    user_id,
    type,
    status,
    amount,
    counterparty_user_id,
    description,
    created_at
)
SELECT
    'SEED-TXN-' || lpad(gs::text, 3, '0'),
    c.id,
    CASE (gs - 1) % 6
        WHEN 0 THEN 'ADD_MONEY'
        WHEN 1 THEN 'SEND_MONEY'
        WHEN 2 THEN 'MERCHANT_PAYMENT'
        WHEN 3 THEN 'SAVINGS_DEPOSIT'
        WHEN 4 THEN 'MOBILE_RECHARGE'
        ELSE 'RECEIVE_MONEY'
    END,
    'SUCCESS',
    100.00 + gs,
    m.id,
    'Seed transaction ' || lpad(gs::text, 3, '0'),
    CURRENT_TIMESTAMP - (gs || ' days')::INTERVAL
FROM generate_series(1, 15) AS gs
JOIN users c ON c.firebase_uid = 'seed-customer-' || lpad(gs::text, 3, '0')
JOIN users m ON m.firebase_uid = 'seed-merchant-user-' || lpad(gs::text, 3, '0')
ON CONFLICT (transaction_reference) DO NOTHING;

INSERT INTO ledger_entries (
    wallet_id,
    user_id,
    transaction_reference,
    entry_type,
    amount,
    balance_after,
    description,
    created_at
)
SELECT
    w.id,
    c.id,
    'SEED-TXN-' || lpad(gs::text, 3, '0'),
    CASE WHEN gs % 2 = 0 THEN 'CREDIT' ELSE 'DEBIT' END,
    100.00 + gs,
    w.balance,
    'Seed ledger entry ' || lpad(gs::text, 3, '0'),
    CURRENT_TIMESTAMP - (gs || ' days')::INTERVAL
FROM generate_series(1, 15) AS gs
JOIN users c ON c.firebase_uid = 'seed-customer-' || lpad(gs::text, 3, '0')
JOIN wallets w ON w.user_id = c.id
WHERE NOT EXISTS (
    SELECT 1
    FROM ledger_entries le
    WHERE le.transaction_reference = 'SEED-TXN-' || lpad(gs::text, 3, '0')
      AND le.wallet_id = w.id
);

INSERT INTO idempotency_keys (
    user_id,
    idempotency_key,
    request_hash,
    operation_type,
    status,
    response_body,
    expires_at
)
SELECT
    c.id,
    'seed-idempotency-' || lpad(gs::text, 3, '0'),
    'seed-request-hash-' || lpad(gs::text, 3, '0'),
    CASE (gs - 1) % 5
        WHEN 0 THEN 'ADD_MONEY'
        WHEN 1 THEN 'SEND_MONEY'
        WHEN 2 THEN 'MERCHANT_PAYMENT'
        WHEN 3 THEN 'MOBILE_RECHARGE'
        ELSE 'SAVINGS_DEPOSIT'
    END,
    'COMPLETED',
    '{"seed":true}',
    CURRENT_TIMESTAMP + INTERVAL '30 days'
FROM generate_series(1, 15) AS gs
JOIN users c ON c.firebase_uid = 'seed-customer-' || lpad(gs::text, 3, '0')
ON CONFLICT (user_id, idempotency_key) DO UPDATE
SET request_hash = EXCLUDED.request_hash,
    operation_type = EXCLUDED.operation_type,
    status = EXCLUDED.status,
    response_body = EXCLUDED.response_body,
    expires_at = EXCLUDED.expires_at,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO add_money_requests (
    user_id,
    amount,
    source_type,
    status,
    approved_by,
    approved_at,
    note,
    created_at,
    updated_at
)
SELECT
    c.id,
    500.00 + gs,
    CASE (gs - 1) % 3
        WHEN 0 THEN 'DEMO_BANK'
        WHEN 1 THEN 'DEMO_CARD'
        ELSE 'MANUAL'
    END,
    CASE (gs - 1) % 3
        WHEN 0 THEN 'PENDING'
        WHEN 1 THEN 'APPROVED'
        ELSE 'REJECTED'
    END,
    CASE WHEN gs % 3 = 1 THEN NULL ELSE a.id END,
    CASE WHEN gs % 3 = 1 THEN NULL ELSE CURRENT_TIMESTAMP END,
    'seed-add-money-' || lpad(gs::text, 3, '0'),
    CURRENT_TIMESTAMP - (gs || ' days')::INTERVAL,
    CURRENT_TIMESTAMP
FROM generate_series(1, 15) AS gs
JOIN users c ON c.firebase_uid = 'seed-customer-' || lpad(gs::text, 3, '0')
JOIN users a ON a.firebase_uid = 'seed-admin-001'
WHERE NOT EXISTS (
    SELECT 1 FROM add_money_requests r WHERE r.note = 'seed-add-money-' || lpad(gs::text, 3, '0')
);

INSERT INTO loan_requests (
    user_id,
    amount,
    purpose,
    status,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at
)
SELECT
    c.id,
    2000.00 + (gs * 100),
    'Seed loan purpose ' || lpad(gs::text, 3, '0'),
    CASE (gs - 1) % 3
        WHEN 0 THEN 'PENDING'
        WHEN 1 THEN 'APPROVED'
        ELSE 'REJECTED'
    END,
    CASE WHEN gs % 3 = 1 THEN NULL ELSE a.id END,
    CASE WHEN gs % 3 = 1 THEN NULL ELSE CURRENT_TIMESTAMP END,
    CURRENT_TIMESTAMP - (gs || ' days')::INTERVAL,
    CURRENT_TIMESTAMP
FROM generate_series(1, 15) AS gs
JOIN users c ON c.firebase_uid = 'seed-customer-' || lpad(gs::text, 3, '0')
JOIN users a ON a.firebase_uid = 'seed-admin-001'
WHERE NOT EXISTS (
    SELECT 1
    FROM loan_requests lr
    WHERE lr.purpose = 'Seed loan purpose ' || lpad(gs::text, 3, '0')
);

INSERT INTO mobile_recharges (
    user_id,
    operator,
    mobile_number,
    amount,
    status,
    transaction_reference,
    created_at
)
SELECT
    c.id,
    CASE (gs - 1) % 5
        WHEN 0 THEN 'GP'
        WHEN 1 THEN 'ROBI'
        WHEN 2 THEN 'BANGLALINK'
        WHEN 3 THEN 'TELETALK'
        ELSE 'AIRTEL'
    END,
    '+88019' || lpad(gs::text, 8, '0'),
    20.00 + gs,
    CASE WHEN gs % 5 = 0 THEN 'FAILED' ELSE 'SUCCESS' END,
    'SEED-TXN-' || lpad(gs::text, 3, '0'),
    CURRENT_TIMESTAMP - (gs || ' days')::INTERVAL
FROM generate_series(1, 15) AS gs
JOIN users c ON c.firebase_uid = 'seed-customer-' || lpad(gs::text, 3, '0')
WHERE NOT EXISTS (
    SELECT 1
    FROM mobile_recharges mr
    WHERE mr.mobile_number = '+88019' || lpad(gs::text, 8, '0')
      AND mr.transaction_reference = 'SEED-TXN-' || lpad(gs::text, 3, '0')
);

INSERT INTO savings_goals (
    user_id,
    name,
    target_amount,
    current_amount,
    target_date,
    status,
    created_at,
    updated_at
)
SELECT
    c.id,
    'Seed Savings Goal ' || lpad(gs::text, 3, '0'),
    10000.00 + (gs * 500),
    1000.00 + (gs * 100),
    CURRENT_DATE + (gs * 10),
    CASE WHEN gs % 5 = 0 THEN 'COMPLETED' ELSE 'ACTIVE' END,
    CURRENT_TIMESTAMP - (gs || ' days')::INTERVAL,
    CURRENT_TIMESTAMP
FROM generate_series(1, 15) AS gs
JOIN users c ON c.firebase_uid = 'seed-customer-' || lpad(gs::text, 3, '0')
WHERE NOT EXISTS (
    SELECT 1
    FROM savings_goals sg
    WHERE sg.user_id = c.id
      AND sg.name = 'Seed Savings Goal ' || lpad(gs::text, 3, '0')
);

INSERT INTO firebase_devices (
    user_id,
    fcm_token,
    device_type,
    active,
    created_at,
    updated_at
)
SELECT
    c.id,
    'seed-fcm-token-' || lpad(gs::text, 3, '0'),
    CASE (gs - 1) % 6
        WHEN 0 THEN 'ANDROID'
        WHEN 1 THEN 'IOS'
        WHEN 2 THEN 'WEB'
        WHEN 3 THEN 'WINDOWS'
        WHEN 4 THEN 'LINUX'
        ELSE 'MACOS'
    END,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM generate_series(1, 15) AS gs
JOIN users c ON c.firebase_uid = 'seed-customer-' || lpad(gs::text, 3, '0')
ON CONFLICT (fcm_token) DO UPDATE
SET user_id = EXCLUDED.user_id,
    device_type = EXCLUDED.device_type,
    active = TRUE,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO admin_audit_logs (
    admin_user_id,
    action,
    target_type,
    target_id,
    details,
    created_at
)
SELECT
    a.id,
    CASE WHEN gs % 2 = 0 THEN 'ADD_MONEY_APPROVE' ELSE 'LOAN_REJECT' END,
    CASE WHEN gs % 2 = 0 THEN 'ADD_MONEY_REQUEST' ELSE 'LOAN_REQUEST' END,
    'seed-target-' || lpad(gs::text, 3, '0'),
    'Seed admin audit log ' || lpad(gs::text, 3, '0'),
    CURRENT_TIMESTAMP - (gs || ' days')::INTERVAL
FROM generate_series(1, 15) AS gs
JOIN users a ON a.firebase_uid = 'seed-admin-001'
WHERE NOT EXISTS (
    SELECT 1
    FROM admin_audit_logs aal
    WHERE aal.target_id = 'seed-target-' || lpad(gs::text, 3, '0')
      AND aal.details = 'Seed admin audit log ' || lpad(gs::text, 3, '0')
);

COMMIT;

SELECT 'users' AS table_name, COUNT(*) AS seed_rows
FROM users
WHERE firebase_uid = 'seed-admin-001'
   OR firebase_uid LIKE 'seed-customer-%'
   OR firebase_uid LIKE 'seed-merchant-user-%'
UNION ALL
SELECT 'user_profiles', COUNT(*)
FROM user_profiles up
JOIN users u ON u.id = up.user_id
WHERE u.firebase_uid = 'seed-admin-001'
   OR u.firebase_uid LIKE 'seed-customer-%'
   OR u.firebase_uid LIKE 'seed-merchant-user-%'
UNION ALL
SELECT 'wallets', COUNT(*)
FROM wallets w
JOIN users u ON u.id = w.user_id
WHERE u.firebase_uid = 'seed-admin-001'
   OR u.firebase_uid LIKE 'seed-customer-%'
   OR u.firebase_uid LIKE 'seed-merchant-user-%'
UNION ALL
SELECT 'merchants', COUNT(*) FROM merchants WHERE merchant_number LIKE 'MERCH-%'
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions WHERE transaction_reference LIKE 'SEED-TXN-%'
UNION ALL
SELECT 'ledger_entries', COUNT(*) FROM ledger_entries WHERE transaction_reference LIKE 'SEED-TXN-%'
UNION ALL
SELECT 'idempotency_keys', COUNT(*) FROM idempotency_keys WHERE idempotency_key LIKE 'seed-idempotency-%'
UNION ALL
SELECT 'add_money_requests', COUNT(*) FROM add_money_requests WHERE note LIKE 'seed-add-money-%'
UNION ALL
SELECT 'loan_requests', COUNT(*) FROM loan_requests WHERE purpose LIKE 'Seed loan purpose %'
UNION ALL
SELECT 'mobile_recharges', COUNT(*) FROM mobile_recharges WHERE mobile_number LIKE '+88019%'
UNION ALL
SELECT 'savings_goals', COUNT(*) FROM savings_goals WHERE name LIKE 'Seed Savings Goal %'
UNION ALL
SELECT 'firebase_devices', COUNT(*) FROM firebase_devices WHERE fcm_token LIKE 'seed-fcm-token-%'
UNION ALL
SELECT 'admin_audit_logs', COUNT(*) FROM admin_audit_logs WHERE details LIKE 'Seed admin audit log %'
ORDER BY table_name;
