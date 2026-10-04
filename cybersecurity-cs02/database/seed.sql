-- ============================================================================
-- SecureMart - Database Seed Data (SYNTHETIC LABORATORY DATA ONLY)
-- ============================================================================
-- WHAT:  Populates roles, users, categories, products, carts, orders, audit.
-- WHY:   Provides realistic data so the UI and APIs display real content
--        sourced from MySQL rather than hardcoded frontend values.
-- WHERE: Run against `securemart_db` AFTER schema.sql.
-- EXPECTED: Row counts printed by the final SELECT summary.
-- ERROR:  FK/unique violations if run twice (mitigated by guards).
-- RECOVERY: TRUNCATE in reverse FK order, or DROP + recreate DB.
--
-- LAB-ONLY CREDENTIALS (never real):
--   admin@example.local    / Admin@Lab123!
--   customer@example.local / Customer@Lab123!
--   alice@example.local    / Alice@Lab123!
--   bob@example.local      / Bob@Lab123!
-- Passwords stored ONLY as bcrypt hashes ($2b$10, cost 10).
-- ============================================================================

USE securemart_db;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE cart_items;
TRUNCATE TABLE cart;
TRUNCATE TABLE audit_logs;
TRUNCATE TABLE products;
TRUNCATE TABLE categories;
TRUNCATE TABLE users;
TRUNCATE TABLE roles;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------------
-- roles
-- ---------------------------------------------------------------------------
INSERT INTO roles (id, name, description) VALUES
  (1, 'customer', 'Standard shopper: browse, cart, own orders and profile'),
  (2, 'admin',    'Administrator: manage catalogue, users, orders, security');

-- ---------------------------------------------------------------------------
-- users (bcrypt password hashes)
-- ---------------------------------------------------------------------------
INSERT INTO users (id, name, email, password_hash, role_id, phone, address, is_active) VALUES
  (1, 'Site Administrator', 'admin@example.local',
   '$2b$10$xYjdUt0Uw7yzZ8Cw353agexe3zcmuQr7rhEMGiYhA33sRVAWlVZjC', 2,
   '+1-555-0100', '100 Lab Lane, Testville', 1),
  (2, 'Demo Customer', 'customer@example.local',
   '$2b$10$GSJJoyc/Osa3g/Q17ldjMuzaO9MD8RBVElR39/YFrRheH4raqtjAm', 1,
   '+1-555-0101', '200 Demo Street, Sampletown', 1),
  (3, 'Alice Example', 'alice@example.local',
   '$2b$10$Xx2MAh7MqMLD2Fuw5C.tsu45vxXNUOM5YjbEa6DvO3MUcxtKkNOHW', 1,
   '+1-555-0102', '301 Example Ave, Placeholder', 1),
  (4, 'Bob Example', 'bob@example.local',
   '$2b$10$ABXNmz6V41Ev86Y95/RsoeXt7lMvxBfs2zjZWyqldlKQHMBdtA4dm', 1,
   '+1-555-0103', '402 Sample Rd, Mock City', 1);

-- ---------------------------------------------------------------------------
-- categories (5)
-- ---------------------------------------------------------------------------
INSERT INTO categories (id, name, slug, description) VALUES
  (1, 'Beverages',    'beverages',    'Juices, teas, coffees and bottled drinks'),
  (2, 'Snacks',       'snacks',       'Chips, crackers and quick bites'),
  (3, 'Bakery',       'bakery',       'Breads, cakes and pastries'),
  (4, 'Produce',      'produce',      'Fresh fruit and vegetables'),
  (5, 'Household',    'household',    'Everyday home and cleaning essentials');

-- ---------------------------------------------------------------------------
-- products (15) - synthetic catalogue, images use local placeholder paths
-- ---------------------------------------------------------------------------
INSERT INTO products (id, name, slug, description, price, stock, image, category_id) VALUES
  (1,  'Apple Juice (1L)',        'apple-juice-1l',        'Cold-pressed apple juice with no added sugar.',        3.49, 120, '/img/apple-juice.svg',  1),
  (2,  'Orange Juice (1L)',       'orange-juice-1l',       'Fresh squeezed orange juice, rich in vitamin C.',      3.99, 95,  '/img/orange-juice.svg', 1),
  (3,  'Green Tea (25 Bags)',     'green-tea-25',          'Calming green tea bags, medium leaf blend.',           4.75, 60,  '/img/green-tea.svg',     1),
  (4,  'Ground Coffee (500g)',    'ground-coffee-500g',    'Medium roast arabica ground coffee.',                  9.99, 45,  '/img/coffee.svg',        1),
  (5,  'Sparkling Water (6pk)',   'sparkling-water-6pk',   'Naturally carbonated mineral water.',                  5.49, 150, '/img/sparkling.svg',     1),
  (6,  'Potato Chips (200g)',     'potato-chips-200g',     'Sea-salted crunchy potato chips.',                     2.29, 200, '/img/chips.svg',         2),
  (7,  'Salted Crackers (150g)',  'salted-crackers-150g',  'Baked crackers with a light salt glaze.',              1.99, 180, '/img/crackers.svg',      2),
  (8,  'Trail Mix (300g)',        'trail-mix-300g',        'Mixed nuts, seeds and dried fruit.',                   6.49, 75,  '/img/trail-mix.svg',     2),
  (9,  'Chocolate Bar (100g)',    'chocolate-bar-100g',    'Dark chocolate bar, 70% cocoa.',                       2.79, 140, '/img/chocolate.svg',     2),
  (10, 'Sourdough Bread',         'sourdough-bread',       'Artisan sourdough loaf, baked daily.',                 4.25, 30,  '/img/sourdough.svg',     3),
  (11, 'Croissant (4pk)',         'croissant-4pk',         'Butter croissants, flaky and light.',                 5.99, 40,  '/img/croissant.svg',     3),
  (12, 'Bananas (1kg)',           'bananas-1kg',           'Fresh yellow bananas, fair-trade sourced.',           1.79, 90,  '/img/bananas.svg',       4),
  (13, 'Tomatoes (500g)',         'tomatoes-500g',         'Vine-ripened salad tomatoes.',                         2.49, 70,  '/img/tomatoes.svg',      4),
  (14, 'Dish Soap (750ml)',       'dish-soap-750ml',       'Lemon scented concentrated dish soap.',                3.19, 110, '/img/dish-soap.svg',     5),
  (15, 'Paper Towels (6 Rolls)',  'paper-towels-6rolls',   'Absorbent kitchen paper towels.',                      6.99, 85,  '/img/paper-towels.svg',  5);

-- ---------------------------------------------------------------------------
-- carts + cart items (demo customer already has items in cart)
-- ---------------------------------------------------------------------------
INSERT INTO cart (id, user_id) VALUES
  (1, 2),
  (2, 3);

INSERT INTO cart_items (id, cart_id, product_id, quantity) VALUES
  (1, 1, 1,  2),
  (2, 1, 6,  1),
  (3, 1, 12, 3),
  (4, 2, 4,  1);

-- ---------------------------------------------------------------------------
-- orders + order items (checkout simulation history)
-- ---------------------------------------------------------------------------
INSERT INTO orders (id, user_id, total, status, shipping_address) VALUES
  (1, 2, 14.76, 'delivered', '200 Demo Street, Sampletown'),
  (2, 2, 11.48, 'shipped',   '200 Demo Street, Sampletown'),
  (3, 3,  9.99, 'pending',   '301 Example Ave, Placeholder'),
  (4, 4,  6.78, 'processing','402 Sample Rd, Mock City');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
  (1, 1,  2, 3.49),
  (1, 6,  2, 2.29),
  (1, 12, 3, 1.79),
  (2, 4,  1, 9.99),
  (3, 4,  1, 9.99),
  (4, 12, 2, 1.79),
  (4, 7,  1, 1.99),
  (4, 9,  1, 1.21);

-- ---------------------------------------------------------------------------
-- audit_logs (sample security/business events, no secrets stored)
-- ---------------------------------------------------------------------------
INSERT INTO audit_logs (user_id, event_type, description, ip_address, user_agent) VALUES
  (1, 'LOGIN_SUCCESS',    'Administrator signed in',                '127.0.0.1', 'SecureMart-Lab/1.0'),
  (2, 'LOGIN_SUCCESS',    'Customer signed in',                     '127.0.0.1', 'SecureMart-Lab/1.0'),
  (2, 'ORDER_CREATED',    'Order #1 placed (checkout simulation)',  '127.0.0.1', 'SecureMart-Lab/1.0'),
  (2, 'LOGIN_FAILED',     'Failed sign-in attempt (wrong password)','127.0.0.1', 'SecureMart-Lab/1.0'),
  (1, 'PRODUCT_CREATED',  'Administrator added a product',          '127.0.0.1', 'SecureMart-Lab/1.0'),
  (3, 'REGISTER',         'New account self-registered',            '127.0.0.1', 'SecureMart-Lab/1.0');

-- ---------------------------------------------------------------------------
-- summary
-- ---------------------------------------------------------------------------
SELECT 'roles'     AS tbl, COUNT(*) AS rows_added FROM roles
UNION ALL SELECT 'users',     COUNT(*) FROM users
UNION ALL SELECT 'categories',COUNT(*) FROM categories
UNION ALL SELECT 'products',  COUNT(*) FROM products
UNION ALL SELECT 'cart',      COUNT(*) FROM cart
UNION ALL SELECT 'cart_items',COUNT(*) FROM cart_items
UNION ALL SELECT 'orders',    COUNT(*) FROM orders
UNION ALL SELECT 'order_items',COUNT(*) FROM order_items
UNION ALL SELECT 'audit_logs',COUNT(*) FROM audit_logs;
