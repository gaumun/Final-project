CREATE DATABASE FINALPROJECT;

# создаем таблицы и загружаем в них данные
CREATE TABLE order_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    price DECIMAL(10, 2),
    quantity INT,
    revenue DECIMAL(10, 2),
    category VARCHAR(100),
    product_name VARCHAR(255)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_lines.csv'
INTO TABLE order_lines
CHARACTER SET cp1251
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, product_id, @price, quantity, @revenue, category, product_name)
SET 
    price = REPLACE(@price, ',', '.'),
    revenue = REPLACE(@revenue, ',', '.');

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    warehouse_id INT,
    user_id INT,
    week INT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv'
INTO TABLE orders
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_date, order_id, warehouse_id, user_id, week);

select * from orders;

CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY,
    name VARCHAR(255),
    city VARCHAR(100)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/warehouses.csv'
INTO TABLE warehouses
CHARACTER SET cp1251
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(warehouse_id, name, city);

CREATE TABLE products (
	product_id INT PRIMARY KEY,
    product VARCHAR(255),
    category VARCHAR(100)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
CHARACTER SET cp1251
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

/* Задание №2 Напишите SQL запрос по базе данных из задания 1, который выведет список тех пользователей, 
которые купили за период 1-15 августа 2 любых корма для животных, кроме "Корм Kitekat для кошек, с кроликом в соусе, 85 г". 
Приложите его в текстовом документе.
*/
SELECT o.user_id, COUNT(DISTINCT p.product_id) AS product_count 
FROM orders o
JOIN order_lines ol ON o.order_id = ol.order_id
JOIN products p ON p.product_id = ol.product_id
WHERE TRIM(p.category) LIKE '%Продукция для животных%' 
	AND p.product_id != 3107
    AND DAY(o.order_date) BETWEEN 1 AND 15
GROUP BY o.user_id
HAVING COUNT(DISTINCT p.product_id) >= 2;

/* Задание №3. Напишите SQL запрос, который выведет список топ 5 самых часто встречающихся товаров 
в заказах пользователей в СПб за период 15-30 августа. 
Приложите его в том же текстовом документе, где вы написали запрос из предыдущего пункта.
*/
SELECT 
  p.product,
  COUNT(*) AS order_count
FROM orders o
JOIN order_lines ol ON o.order_id = ol.order_id
JOIN products p ON ol.product_id = p.product_id
JOIN warehouses w ON o.warehouse_id = w.warehouse_id
WHERE w.name = 'Санкт-Петербург'
  AND DAY(o.order_date) BETWEEN 15 AND 30
GROUP BY p.product
ORDER BY order_count DESC
LIMIT 5;