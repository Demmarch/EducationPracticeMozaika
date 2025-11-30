CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Типы партнеров
COPY partner_type(id, type_name)
FROM 'C:\Users\Public\Documents\partner_type.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');


-- Типы продукции
COPY product_type(id, type_name)
FROM 'C:\Users\Public\Documents\product_type.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

-- Типы материалов
COPY material_type(id, type_name)
FROM 'C:\Users\Public\Documents\material_type.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

-- Должности сотрудников (таблица staff_position)
COPY staff_position(id, position_name)
FROM 'C:\Users\Public\Documents\staff_position.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');


-- Поставщики
-- Временная таблица
CREATE TEMP TABLE supplier_import_temp (
    id INTEGER,
    supplier_name VARCHAR(100) NOT NULL,
    inn_text VARCHAR(20),
    supplier_type VARCHAR(50) -- Тип поставщика (например, "Оптовый")
);
COPY supplier_import_temp(id, supplier_name, inn_text, supplier_type)
FROM 'C:\Users\Public\Documents\supplier.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

INSERT INTO supplier (
    id, supplier_name, inn, supplier_type
)
SELECT
    id, supplier_name,
    -- Шифруем ИНН
    pgp_sym_encrypt(inn_text, 'Mozaika2025'),
    supplier_type
FROM supplier_import_temp;

-- Удаляем временную таблицу
DROP TABLE supplier_import_temp;


-- Сотрудники (staff)
-- Временная таблица
CREATE TEMP TABLE staff_import_temp (
    id INTEGER,
    surname VARCHAR(50),
    name VARCHAR(50),
    patronymic VARCHAR(50),
    position_id INTEGER,
    birth_date DATE,
    passport_json_text TEXT, -- JSON придет как текст
    bank_account VARCHAR(25),
    family_status VARCHAR(50),
    health_info TEXT,
    phone VARCHAR(20),
    login VARCHAR(50),
    password_text VARCHAR(100) -- Пароль придет как текст
);

-- Загружаем CSV во временную таблицу
COPY staff_import_temp(id, surname, name, patronymic, position_id, birth_date, passport_json_text, bank_account, family_status, health_info, phone, login, password_text)
FROM 'C:\Users\Public\Documents\staff.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');

-- Переносим в основную таблицу с шифрованием паспорта и хешированием пароля
INSERT INTO staff (
    id, surname, name, patronymic, position_id, birth_date,
    passport_details, -- Целевое поле BYTEA
    bank_account, family_status, health_info, phone, login, 
    password -- Целевое поле хеша
)
SELECT 
    id, surname, name, patronymic, position_id, birth_date,
    -- Шифруем JSON паспорта
    pgp_sym_encrypt(passport_json_text, 'Mozaika2025'),
    bank_account, family_status, health_info, phone, login,
    -- Хешируем пароль
    crypt(password_text, gen_salt('bf'))
FROM staff_import_temp;

-- Удаляем временную таблицу
DROP TABLE staff_import_temp;

-- Партнеры
-- Создаем временную таблицу
CREATE TEMP TABLE partner_import_temp (
    id INTEGER,
    partner_type_id INTEGER,
    partner_name VARCHAR(100),
    director_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    legal_address TEXT,
    inn_text VARCHAR(20), -- ИНН придет как текст
    rating INTEGER,
    logo TEXT,
    sales_locations TEXT,
    login VARCHAR(50),
    password_text VARCHAR(100) -- Пароль придет как текст
);

-- Загружаем CSV во временную таблицу
COPY partner_import_temp(id, partner_type_id, partner_name, director_name, email, phone, legal_address, inn_text, rating, logo, sales_locations, login, password_text)
FROM 'C:\Users\Public\Documents\partner.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

-- Переносим в основную таблицу с шифрованием ИНН и хешированием пароля
INSERT INTO partner (
    id, partner_type_id, partner_name, director_name, email, phone, 
    legal_address, 
    inn, -- Целевое поле BYTEA
    rating, logo, sales_locations, login, 
    password -- Целевое поле хеша
)
SELECT 
    id, partner_type_id, partner_name, director_name, email, phone, 
    legal_address, 
    -- Шифруем ИНН
    pgp_sym_encrypt(inn_text, 'Mozaika2025'),
    rating, logo, sales_locations, login, 
    -- Хешируем пароль
    crypt(password_text, gen_salt('bf'))
FROM partner_import_temp;

-- Удаляем временную таблицу
DROP TABLE partner_import_temp;

-- Материалы
COPY material(id, material_type_id, material_name, unit, count_in_pack, min_count, cost, description, image, current_quantity)
FROM 'C:\Users\Public\Documents\material.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

-- Продукция
COPY product(id, article, product_type_id, product_name, description, image, min_cost_for_partner, package_size, net_weight, gross_weight, certificate_scan, standard_number, production_time, cost_price, workshop_number, production_people_count)
FROM 'C:\Users\Public\Documents\product.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

-- Спецификация (Продукт - Материал)
COPY product_material(product_id, material_id, required_quantity)
FROM 'C:\Users\Public\Documents\product_material.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

-- Заявки (Зависит от Партнеров и Сотрудников)
COPY request(id, partner_id, manager_id, date_created, status, payment_date)
FROM 'C:\Users\Public\Documents\request.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

-- Состав заявок (Зависит от Заявок и Продукции)
COPY request_product(id, request_id, product_id, quantity, actual_price, planned_production_date)
FROM 'C:\Users\Public\Documents\request_product.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

-- Обновление счётчиков ID
SELECT setval('partner_type_id_seq', (SELECT MAX(id) FROM partner_type));
SELECT setval('product_type_id_seq', (SELECT MAX(id) FROM product_type));
SELECT setval('material_type_id_seq', (SELECT MAX(id) FROM material_type));
SELECT setval('staff_position_id_seq', (SELECT MAX(id) FROM staff_position));
SELECT setval('supplier_id_seq', (SELECT MAX(id) FROM supplier));
SELECT setval('staff_id_seq', (SELECT MAX(id) FROM staff));
SELECT setval('partner_id_seq', (SELECT MAX(id) FROM partner));
SELECT setval('material_id_seq', (SELECT MAX(id) FROM material));
SELECT setval('product_id_seq', (SELECT MAX(id) FROM product));
SELECT setval('request_id_seq', (SELECT MAX(id) FROM request));
SELECT setval('request_product_id_seq', (SELECT MAX(id) FROM request_product));