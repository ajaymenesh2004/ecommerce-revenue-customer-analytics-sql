-- ==================================================================
-- E-COMMERCE ETL SCHEMA SETUP
-- Load order: customers, products -> orders -> reviews
-- (Customers & Products must load first — Orders references both;
--  Reviews references Orders, Customers, and Products)
-- ==================================================================

-- ==================================================================
-- SECTION 1: DATABASE SETUP
-- ==================================================================

CREATE DATABASE ecommerce;
USE ecommerce;

-- ==================================================================
-- SECTION 2: DROP EXISTING TABLES (reverse dependency order —
-- child tables dropped before the parent tables they reference)
-- ==================================================================

DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- ==================================================================
-- SECTION 3: CREATE TABLES (parent tables first, so foreign keys
-- in child tables have something to reference)
-- ==================================================================

-- 3.1 Customers (parent table — referenced by Orders and Reviews)
CREATE TABLE customers (
    customer_id     VARCHAR(20)     NOT NULL,
    customer_name   VARCHAR(120)    NOT NULL,
    gender          VARCHAR(20),
    age_group       VARCHAR(30),
    country         VARCHAR(60),
    signup_date     DATE,
    PRIMARY KEY (customer_id)
);

-- 3.2 Products (parent table — referenced by Orders and Reviews)
CREATE TABLE products (
    product_id      VARCHAR(20)     NOT NULL,
    product_name    VARCHAR(150)    NOT NULL,
    category        VARCHAR(60),
    unit_price      NUMERIC(10, 2),
    PRIMARY KEY (product_id)
);

-- 3.3 Orders (child of Customers + Products; parent of Reviews)
CREATE TABLE orders (
    order_id        VARCHAR(20)     NOT NULL,
    customer_id     VARCHAR(20)     NOT NULL,
    product_id      VARCHAR(20)     NOT NULL,
    quantity        INT             NOT NULL,
    unit_price      NUMERIC(10, 2),
    total_amount    NUMERIC(12, 2),
    order_date      DATE,
    order_status    VARCHAR(20),
    payment_method  VARCHAR(30),
    PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_orders_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
);

-- 3.4 Reviews (child of Orders, Customers, and Products)
CREATE TABLE reviews (
    review_id       VARCHAR(20)     NOT NULL,
    order_id        VARCHAR(20)     NOT NULL,
    customer_id     VARCHAR(20)     NOT NULL,
    product_id      VARCHAR(20)     NOT NULL,
    rating          INT,
    review_text     VARCHAR(255),
    review_date     DATE,
    PRIMARY KEY (review_id),
    CONSTRAINT fk_reviews_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_reviews_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_reviews_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
);

-- ==================================================================
-- SECTION 4: RAW TABLE PREVIEWS (sanity check after data load)
-- ==================================================================

SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM reviews;
