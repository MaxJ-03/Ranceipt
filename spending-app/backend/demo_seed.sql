-- Demo seed data for Ranceipt sandbox demo
-- This script is idempotent and only affects rows tied to the demo user

-- Helper: Delete existing demo data if any
DELETE FROM receipt_items
WHERE receipt_id IN (SELECT id FROM receipts WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user'));

DELETE FROM receipts
WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user');

DELETE FROM transactions
WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user');

DELETE FROM personal_goals
WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user');

DELETE FROM app_sessions
WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user');

DELETE FROM bunq_connections
WHERE bunq_user_api_key_id = 'sandbox-demo-user';

DELETE FROM users
WHERE id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user');

-- Create demo user
INSERT INTO users (created_at) VALUES (NOW()) RETURNING id AS demo_user_id;

-- Populate demo user with bunq connection (assume user_id = 1 for demo; adjust as needed)
INSERT INTO bunq_connections (user_id, bunq_user_api_key_id, encrypted_access_token, created_at)
VALUES (1, 'sandbox-demo-user', 'encrypted_demo_token', NOW());

-- Insert custom categories for receipts
INSERT INTO custom_categories (name) VALUES
  ('Coffee')
  ON CONFLICT DO NOTHING;
INSERT INTO custom_categories (name) VALUES
  ('Yogurt')
  ON CONFLICT DO NOTHING;
INSERT INTO custom_categories (name) VALUES
  ('Milk'),
  ('Bread'),
  ('Vegetables'),
  ('Cheese'),
  ('Apples'),
  ('Pasta'),
  ('Oil'),
  ('Chocolate')
  ON CONFLICT DO NOTHING;

-- Insert general categories for transactions
INSERT INTO general_categories (name) VALUES
  ('Groceries'),
  ('Dining'),
  ('Transport'),
  ('Entertainment'),
  ('Shopping'),
  ('Subscription'),
  ('Healthcare'),
  ('Utilities'),
  ('Travel')
  ON CONFLICT DO NOTHING;

-- Create demo transactions (past 30 days, realistic)
INSERT INTO transactions (user_id, bunq_payment_id, amount, currency, merchant, description, transaction_date, general_category_id)
VALUES
  (1, 'demo_txn_001', -4.50, 'EUR', 'Starbucks', 'Coffee', NOW() - INTERVAL '28 days', (SELECT id FROM general_categories WHERE name = 'Dining')),
  (1, 'demo_txn_002', -45.80, 'EUR', 'Albert Heijn', 'Groceries', NOW() - INTERVAL '27 days', (SELECT id FROM general_categories WHERE name = 'Groceries')),
  (1, 'demo_txn_003', -4.50, 'EUR', 'Coffee Company', 'Coffee', NOW() - INTERVAL '26 days', (SELECT id FROM general_categories WHERE name = 'Dining')),
  (1, 'demo_txn_004', -9.99, 'EUR', 'Spotify', 'Subscription', NOW() - INTERVAL '25 days', (SELECT id FROM general_categories WHERE name = 'Subscription')),
  (1, 'demo_txn_005', -28.45, 'EUR', 'Albert Heijn', 'Groceries', NOW() - INTERVAL '24 days', (SELECT id FROM general_categories WHERE name = 'Groceries')),
  (1, 'demo_txn_006', -15.99, 'EUR', 'Basic-Fit', 'Fitness', NOW() - INTERVAL '23 days', (SELECT id FROM general_categories WHERE name = 'Entertainment')),
  (1, 'demo_txn_007', -4.50, 'EUR', 'Starbucks', 'Coffee', NOW() - INTERVAL '22 days', (SELECT id FROM general_categories WHERE name = 'Dining')),
  (1, 'demo_txn_008', -32.50, 'EUR', 'Jumbo', 'Groceries', NOW() - INTERVAL '21 days', (SELECT id FROM general_categories WHERE name = 'Groceries')),
  (1, 'demo_txn_009', -12.50, 'EUR', 'Uber Eats', 'Food delivery', NOW() - INTERVAL '20 days', (SELECT id FROM general_categories WHERE name = 'Dining')),
  (1, 'demo_txn_010', -22.00, 'EUR', 'Uber', 'Ride', NOW() - INTERVAL '19 days', (SELECT id FROM general_categories WHERE name = 'Transport')),
  (1, 'demo_txn_011', -4.50, 'EUR', 'Coffee Company', 'Coffee', NOW() - INTERVAL '18 days', (SELECT id FROM general_categories WHERE name = 'Dining')),
  (1, 'demo_txn_012', -85.00, 'EUR', 'Zara', 'Clothing', NOW() - INTERVAL '17 days', (SELECT id FROM general_categories WHERE name = 'Shopping')),
  (1, 'demo_txn_013', -6.99, 'EUR', 'Netflix', 'Subscription', NOW() - INTERVAL '16 days', (SELECT id FROM general_categories WHERE name = 'Subscription')),
  (1, 'demo_txn_014', -41.20, 'EUR', 'Albert Heijn', 'Groceries', NOW() - INTERVAL '15 days', (SELECT id FROM general_categories WHERE name = 'Groceries')),
  (1, 'demo_txn_015', -4.50, 'EUR', 'Starbucks', 'Coffee', NOW() - INTERVAL '14 days', (SELECT id FROM general_categories WHERE name = 'Dining')),
  (1, 'demo_txn_016', -18.50, 'EUR', 'HEMA', 'Home goods', NOW() - INTERVAL '13 days', (SELECT id FROM general_categories WHERE name = 'Shopping')),
  (1, 'demo_txn_017', -9.99, 'EUR', 'Apple', 'Subscription', NOW() - INTERVAL '12 days', (SELECT id FROM general_categories WHERE name = 'Subscription')),
  (1, 'demo_txn_018', -4.50, 'EUR', 'Coffee Company', 'Coffee', NOW() - INTERVAL '11 days', (SELECT id FROM general_categories WHERE name = 'Dining')),
  (1, 'demo_txn_019', -38.99, 'EUR', 'Kruidvat', 'Pharmacy', NOW() - INTERVAL '10 days', (SELECT id FROM general_categories WHERE name = 'Healthcare')),
  (1, 'demo_txn_020', -27.80, 'EUR', 'Albert Heijn', 'Groceries', NOW() - INTERVAL '9 days', (SELECT id FROM general_categories WHERE name = 'Groceries')),
  (1, 'demo_txn_021', -4.50, 'EUR', 'Starbucks', 'Coffee', NOW() - INTERVAL '8 days', (SELECT id FROM general_categories WHERE name = 'Dining')),
  (1, 'demo_txn_022', -120.00, 'EUR', 'IKEA', 'Furniture', NOW() - INTERVAL '7 days', (SELECT id FROM general_categories WHERE name = 'Shopping')),
  (1, 'demo_txn_023', -45.50, 'EUR', 'Bol.com', 'Books/Electronics', NOW() - INTERVAL '6 days', (SELECT id FROM general_categories WHERE name = 'Shopping')),
  (1, 'demo_txn_024', -4.50, 'EUR', 'Coffee Company', 'Coffee', NOW() - INTERVAL '5 days', (SELECT id FROM general_categories WHERE name = 'Dining')),
  (1, 'demo_txn_025', -52.30, 'EUR', 'Albert Heijn', 'Groceries', NOW() - INTERVAL '4 days', (SELECT id FROM general_categories WHERE name = 'Groceries')),
  (1, 'demo_txn_026', -4.50, 'EUR', 'Starbucks', 'Coffee', NOW() - INTERVAL '3 days', (SELECT id FROM general_categories WHERE name = 'Dining')),
  (1, 'demo_txn_027', -22.99, 'EUR', 'NS', 'Train ticket', NOW() - INTERVAL '2 days', (SELECT id FROM general_categories WHERE name = 'Transport')),
  (1, 'demo_txn_028', -4.50, 'EUR', 'Coffee Company', 'Coffee', NOW() - INTERVAL '1 day', (SELECT id FROM general_categories WHERE name = 'Dining')),
  (1, 'demo_txn_029', -35.40, 'EUR', 'Albert Heijn', 'Groceries', NOW(), (SELECT id FROM general_categories WHERE name = 'Groceries')),
  (1, 'demo_txn_030', -4.50, 'EUR', 'Starbucks', 'Coffee', NOW(), (SELECT id FROM general_categories WHERE name = 'Dining'))
ON CONFLICT DO NOTHING;

-- Create receipts linked to select transactions
INSERT INTO receipts (user_id, transaction_id, merchant, total_amount, currency, receipt_date)
SELECT 1, t.id, t.merchant, t.amount, t.currency, t.transaction_date
FROM transactions t
WHERE t.user_id = 1 AND t.bunq_payment_id IN ('demo_txn_002', 'demo_txn_005', 'demo_txn_008', 'demo_txn_014', 'demo_txn_020', 'demo_txn_025', 'demo_txn_029');

-- Populate receipt items for transaction demo_txn_002 (Albert Heijn)
INSERT INTO receipt_items (receipt_id, category_id, name, quantity, unit_price)
SELECT r.id, (SELECT id FROM custom_categories WHERE name = 'Yogurt'), 'Greek Yogurt', 2, 2.40
FROM receipts r
WHERE r.user_id = 1 AND r.merchant = 'Albert Heijn' AND r.total_amount = -45.80
LIMIT 1;

INSERT INTO receipt_items (receipt_id, category_id, name, quantity, unit_price)
SELECT r.id, (SELECT id FROM custom_categories WHERE name = 'Milk'), 'Whole Milk 1L', 1, 1.50
FROM receipts r
WHERE r.user_id = 1 AND r.merchant = 'Albert Heijn' AND r.total_amount = -45.80
LIMIT 1;

INSERT INTO receipt_items (receipt_id, category_id, name, quantity, unit_price)
SELECT r.id, (SELECT id FROM custom_categories WHERE name = 'Bread'), 'Whole Wheat Bread', 1, 1.99
FROM receipts r
WHERE r.user_id = 1 AND r.merchant = 'Albert Heijn' AND r.total_amount = -45.80
LIMIT 1;

INSERT INTO receipt_items (receipt_id, category_id, name, quantity, unit_price)
SELECT r.id, (SELECT id FROM custom_categories WHERE name = 'Cheese'), 'Cheddar Cheese', 1, 3.50
FROM receipts r
WHERE r.user_id = 1 AND r.merchant = 'Albert Heijn' AND r.total_amount = -45.80
LIMIT 1;

INSERT INTO receipt_items (receipt_id, category_id, name, quantity, unit_price)
SELECT r.id, (SELECT id FROM custom_categories WHERE name = 'Vegetables'), 'Bell Peppers', 3, 1.20
FROM receipts r
WHERE r.user_id = 1 AND r.merchant = 'Albert Heijn' AND r.total_amount = -45.80
LIMIT 1;

INSERT INTO receipt_items (receipt_id, category_id, name, quantity, unit_price)
SELECT r.id, (SELECT id FROM custom_categories WHERE name = 'Apples'), 'Red Apples 1kg', 1, 2.50
FROM receipts r
WHERE r.user_id = 1 AND r.merchant = 'Albert Heijn' AND r.total_amount = -45.80
LIMIT 1;

INSERT INTO receipt_items (receipt_id, category_id, name, quantity, unit_price)
SELECT r.id, (SELECT id FROM custom_categories WHERE name = 'Pasta'), 'Penne Pasta 500g', 2, 0.99
FROM receipts r
WHERE r.user_id = 1 AND r.merchant = 'Albert Heijn' AND r.total_amount = -45.80
LIMIT 1;

INSERT INTO receipt_items (receipt_id, category_id, name, quantity, unit_price)
SELECT r.id, (SELECT id FROM custom_categories WHERE name = 'Oil'), 'Olive Oil 500ml', 1, 5.99
FROM receipts r
WHERE r.user_id = 1 AND r.merchant = 'Albert Heijn' AND r.total_amount = -45.80
LIMIT 1;

-- Populate receipt items for transaction demo_txn_005 (Albert Heijn)
INSERT INTO receipt_items (receipt_id, category_id, name, quantity, unit_price)
SELECT r.id, (SELECT id FROM custom_categories WHERE name = 'Yogurt'), 'Plain Yogurt', 3, 1.50
FROM receipts r
WHERE r.user_id = 1 AND r.merchant = 'Albert Heijn' AND r.total_amount = -28.45 AND r.receipt_date < NOW() - INTERVAL '23 days'
LIMIT 1;

INSERT INTO receipt_items (receipt_id, category_id, name, quantity, unit_price)
SELECT r.id, (SELECT id FROM custom_categories WHERE name = 'Milk'), 'Skimmed Milk 1L', 2, 1.30
FROM receipts r
WHERE r.user_id = 1 AND r.merchant = 'Albert Heijn' AND r.total_amount = -28.45 AND r.receipt_date < NOW() - INTERVAL '23 days'
LIMIT 1;

INSERT INTO receipt_items (receipt_id, category_id, name, quantity, unit_price)
SELECT r.id, (SELECT id FROM custom_categories WHERE name = 'Chocolate'), 'Dark Chocolate', 2, 2.25
FROM receipts r
WHERE r.user_id = 1 AND r.merchant = 'Albert Heijn' AND r.total_amount = -28.45 AND r.receipt_date < NOW() - INTERVAL '23 days'
LIMIT 1;

-- Add personal goal
INSERT INTO personal_goals (user_id, amount_to_save, currency, target_date)
VALUES (1, 250.00, 'EUR', NOW() + INTERVAL '30 days');
