-- Ranceipt / Spending App database initialization
-- Usage with running container:
--   docker cp ranceipt_db_init.sql spending_postgres:/ranceipt_db_init.sql
--   docker exec -it spending_postgres psql -U postgres -d spending_app -f /ranceipt_db_init.sql
--
-- Usage on a fresh Postgres container only:
--   mount this file into /docker-entrypoint-initdb.d/init.sql

DROP TABLE IF EXISTS receipt_items CASCADE;
DROP TABLE IF EXISTS receipts CASCADE;
DROP TABLE IF EXISTS personal_goals CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS custom_categories CASCADE;
DROP TABLE IF EXISTS general_categories CASCADE;
DROP TABLE IF EXISTS bunq_connections CASCADE;
DROP TABLE IF EXISTS oauth_states CASCADE;
DROP TABLE IF EXISTS app_sessions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE app_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE oauth_states (
    id BIGSERIAL PRIMARY KEY,
    state TEXT NOT NULL UNIQUE,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE bunq_connections (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bunq_user_api_key_id TEXT NOT NULL UNIQUE,
    encrypted_access_token TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_synced_at TIMESTAMPTZ
);

CREATE TABLE general_categories (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE custom_categories (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bunq_payment_id TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'EUR',
    merchant TEXT,
    description TEXT,
    transaction_date TIMESTAMPTZ NOT NULL,
    general_category_id BIGINT REFERENCES general_categories(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, bunq_payment_id)
);

CREATE TABLE receipts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transaction_id BIGINT UNIQUE REFERENCES transactions(id) ON DELETE SET NULL,
    merchant TEXT,
    total_amount NUMERIC(12, 2),
    currency TEXT NOT NULL DEFAULT 'EUR',
    receipt_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE receipt_items (
    id BIGSERIAL PRIMARY KEY,
    receipt_id BIGINT NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
    category_id BIGINT NOT NULL REFERENCES custom_categories(id) ON DELETE RESTRICT,
    name TEXT,
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 1,
    unit_price NUMERIC(12, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE personal_goals (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount_to_save NUMERIC(12, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'EUR',
    target_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_app_sessions_user_id ON app_sessions(user_id);
CREATE INDEX idx_app_sessions_token_hash ON app_sessions(session_token_hash);
CREATE INDEX idx_bunq_connections_user_id ON bunq_connections(user_id);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_bunq_payment_id ON transactions(bunq_payment_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_general_category_id ON transactions(general_category_id);
CREATE INDEX idx_receipts_user_id ON receipts(user_id);
CREATE INDEX idx_receipts_transaction_id ON receipts(transaction_id);
CREATE INDEX idx_receipt_items_receipt_id ON receipt_items(receipt_id);
CREATE INDEX idx_receipt_items_category_id ON receipt_items(category_id);
CREATE INDEX idx_personal_goals_user_id ON personal_goals(user_id);
CREATE INDEX idx_personal_goals_target_date ON personal_goals(target_date);

INSERT INTO custom_categories (name) VALUES
('Bread'),
('Pastries'),
('Cakes'),
('Eggs'),
('Milk'),
('Plant-based milk'),
('Butter'),
('Cheese'),
('Soft cheese and spreads'),
('Yogurt'),
('Cream'),
('Chicken breast'),
('Chicken thighs'),
('Beef'),
('Pork'),
('Lamb'),
('Turkey'),
('Deli meat'),
('Sausages'),
('Bacon'),
('Fish'),
('Seafood'),
('Rice'),
('Pasta'),
('Noodles'),
('Flour'),
('Sugar'),
('Oats'),
('Cereal'),
('Granola'),
('Beans'),
('Lentils'),
('Chickpeas'),
('Nuts'),
('Seeds'),
('Dried fruit'),
('Apples'),
('Bananas'),
('Oranges'),
('Lemons and limes'),
('Grapes'),
('Berries'),
('Melons'),
('Stone fruit'),
('Tropical fruit'),
('Avocados'),
('Potatoes'),
('Sweet potatoes'),
('Onions'),
('Garlic'),
('Carrots'),
('Tomatoes'),
('Cucumbers'),
('Lettuce'),
('Spinach'),
('Broccoli'),
('Cauliflower'),
('Peppers'),
('Mushrooms'),
('Zucchini'),
('Eggplant'),
('Cabbage'),
('Leeks'),
('Asparagus'),
('Fresh herbs'),
('Frozen vegetables'),
('Frozen fruit'),
('Canned vegetables'),
('Canned fruit'),
('Canned fish'),
('Canned meat'),
('Soup'),
('Pizza'),
('Prepared meals'),
('Sandwiches'),
('Salads'),
('Sauces'),
('Condiments'),
('Cooking oil'),
('Vinegar'),
('Salt'),
('Spices'),
('Stock'),
('Baking ingredients'),
('Chocolate'),
('Candy'),
('Packaged snacks'),
('Ice cream'),
('Desserts'),
('Gum and mints'),
('Coffee for home'),
('Prepared coffee drinks'),
('Tea'),
('Bottled water'),
('Sparkling water'),
('Juice'),
('Smoothies'),
('Soft drinks'),
('Energy drinks'),
('Sports drinks'),
('Beer'),
('Wine'),
('Sparkling wine'),
('Cider'),
('Spirits'),
('Ready-to-drink alcoholic drinks'),
('Non-alcoholic beer and wine'),
('Cigarettes'),
('Rolling tobacco'),
('Vapes'),
('Nicotine pouches'),
('Smoking accessories'),
('Shampoo'),
('Conditioner'),
('Body wash'),
('Soap'),
('Toothpaste'),
('Toothbrushes'),
('Deodorant'),
('Skincare'),
('Hair styling products'),
('Razors'),
('Shaving products'),
('Feminine care'),
('Condoms'),
('Toilet paper'),
('Paper towels'),
('Tissues'),
('Laundry detergent'),
('Fabric softener'),
('Dish soap'),
('Dishwasher products'),
('Surface cleaner'),
('Bathroom cleaner'),
('Trash bags'),
('Foil and food wrap'),
('Food storage bags'),
('Batteries'),
('Light bulbs'),
('Baby products'),
('Pet food'),
('Pet products'),
('Over-the-counter medicine'),
('Vitamins'),
('First aid products'),
('Other')
ON CONFLICT (name) DO NOTHING;

INSERT INTO general_categories (name) VALUES
('Assets'),
('Business expenses'),
('Car expenses'),
('Cash'),
('Clothing'),
('Culture'),
('Electronics'),
('Employee benefits'),
('Entertainment'),
('Family'),
('Finance'),
('Food and drink'),
('General'),
('Gifts'),
('Groceries'),
('Healthcare'),
('Household expenses'),
('HR'),
('Income'),
('Insurance'),
('Investments'),
('Marketing'),
('Office supplies'),
('Payroll'),
('Personal care'),
('Pets'),
('Professional services'),
('Rent and utilities'),
('Savings'),
('Shopping'),
('Sports'),
('Subscriptions'),
('Travel'),
('Uncategorized')
ON CONFLICT (name) DO NOTHING;
