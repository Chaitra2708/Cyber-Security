-- ============================================================================
-- SecureMart - MySQL Database Schema
-- Project: CS-02 Web Application Security Assessment Using OWASP Methodology
-- ============================================================================
-- WHAT:  Creates the relational schema for the SecureMart marketplace.
-- WHY:   The application needs a real backend-persisted data store; all
--        products, users, carts, orders and audit events live here.
-- WHERE: Run against MySQL instance hosting database `securemart_db`.
-- EXPECTED: All CREATE statements succeed; SHOW TABLES lists 9 tables.
-- ERROR:  Duplicate table errors if run twice (mitigated by IF NOT EXISTS).
-- RECOVERY: DROP DATABASE securemart_db; then re-run schema + seed.
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------------
-- roles: enumerates the two supported access levels (RBAC)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS roles (
    id          TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name        VARCHAR(20)      NOT NULL UNIQUE,
    description VARCHAR(120)     NOT NULL DEFAULT '',
    created_at  TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- users: application accounts (password stored ONLY as bcrypt hash)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    name          VARCHAR(80)     NOT NULL,
    email         VARCHAR(160)    NOT NULL,
    password_hash VARCHAR(100)    NOT NULL,
    role_id       TINYINT UNSIGNED NOT NULL DEFAULT 1,
    phone         VARCHAR(20)     NOT NULL DEFAULT '',
    address       VARCHAR(255)    NOT NULL DEFAULT '',
    is_active     TINYINT(1)      NOT NULL DEFAULT 1,
    created_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_email (email),
    KEY idx_users_role (role_id),
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles (id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- categories: product taxonomy
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name        VARCHAR(60)  NOT NULL UNIQUE,
    slug        VARCHAR(60)  NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL DEFAULT '',
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- products: catalogue items
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name         VARCHAR(120) NOT NULL,
    slug         VARCHAR(140) NOT NULL,
    description  TEXT         NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    stock        INT UNSIGNED NOT NULL DEFAULT 0,
    image        VARCHAR(160) NOT NULL DEFAULT '',
    category_id  INT UNSIGNED NOT NULL,
    is_active    TINYINT(1)   NOT NULL DEFAULT 1,
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_products_slug (slug),
    KEY idx_products_category (category_id),
    KEY idx_products_name (name),
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories (id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- cart: one active shopping cart per user
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cart (
    id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id    INT UNSIGNED NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_cart_user (user_id),
    CONSTRAINT fk_cart_user FOREIGN KEY (user_id) REFERENCES users (id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- cart_items: line items inside a cart
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cart_items (
    id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cart_id    INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    quantity   INT UNSIGNED NOT NULL DEFAULT 1,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_cart_items_cart (cart_id),
    KEY idx_cart_items_product (product_id),
    CONSTRAINT fk_cart_items_cart FOREIGN KEY (cart_id) REFERENCES cart (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_cart_items_product FOREIGN KEY (product_id) REFERENCES products (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_cart_items_qty CHECK (quantity > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- orders: checkout records (simulation only - no real payment)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id      INT UNSIGNED NOT NULL,
    total        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status       ENUM('pending','processing','shipped','delivered','cancelled')
                 NOT NULL DEFAULT 'pending',
    shipping_address VARCHAR(255) NOT NULL DEFAULT '',
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_orders_user (user_id),
    KEY idx_orders_status (status),
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users (id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- order_items: line items inside an order (price snapshotted at purchase)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_id    INT UNSIGNED NOT NULL,
    product_id  INT UNSIGNED NOT NULL,
    quantity    INT UNSIGNED NOT NULL DEFAULT 1,
    unit_price  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_order_items_order (order_id),
    KEY idx_order_items_product (product_id),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_order_items_qty CHECK (quantity > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- audit_logs: security / business event trail (never stores secrets)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id     INT UNSIGNED    NULL,
    event_type  VARCHAR(60)     NOT NULL,
    description VARCHAR(255)    NOT NULL DEFAULT '',
    ip_address  VARCHAR(45)     NOT NULL DEFAULT '',
    user_agent  VARCHAR(255)    NOT NULL DEFAULT '',
    created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_audit_event_type (event_type),
    KEY idx_audit_user (user_id),
    KEY idx_audit_created_at (created_at),
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users (id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
