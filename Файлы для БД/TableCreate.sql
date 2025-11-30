-- Очистка базы данных перед созданием (для перезапусков)
DROP TABLE IF EXISTS access_log CASCADE;
DROP TABLE IF EXISTS request_product CASCADE;
DROP TABLE IF EXISTS request CASCADE;
DROP TABLE IF EXISTS product_material CASCADE;
DROP TABLE IF EXISTS product_cost_history CASCADE;
DROP TABLE IF EXISTS material_supply_history CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS material CASCADE;
DROP TABLE IF EXISTS partner CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS supplier CASCADE;
DROP TABLE IF EXISTS staff_position CASCADE;
DROP TABLE IF EXISTS material_type CASCADE;
DROP TABLE IF EXISTS product_type CASCADE;
DROP TABLE IF EXISTS partner_type CASCADE;

-- 1. Справочник типов партнеров (ООО, ЗАО и т.д.)
CREATE TABLE partner_type (
    id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE
);

-- 2. Справочник типов продукции (Плитка, Декор и т.д.)
CREATE TABLE product_type (
    id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE
);

-- 3. Справочник типов материалов (Глина, Краситель и т.д.)
CREATE TABLE material_type (
    id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE
);

-- 4. Справочник должностей сотрудников
CREATE TABLE staff_position (
    id SERIAL PRIMARY KEY,
    position_name VARCHAR(50) NOT NULL UNIQUE
);

-- 5. Поставщики
CREATE TABLE supplier (
    id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    inn BYTEA NOT NULL,
    supplier_type VARCHAR(50) -- Тип поставщика (например, "Оптовый")
);

-- 6. Сотрудники
CREATE TABLE staff (
    id SERIAL PRIMARY KEY,
    surname VARCHAR(50) NOT NULL,
    name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    position_id INTEGER REFERENCES staff_position(id) ON DELETE RESTRICT,
	birth_date DATE NOT NULL,
    -- Поле для паспорта ("должен" хранит зашифрованный JSON)
    passport_details BYTEA NOT NULL,
    bank_account VARCHAR(25) NOT NULL, -- Номер счета
    family_status VARCHAR(50),
    health_info TEXT,
    phone VARCHAR(20) NOT NULL,
    login VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL
);

-- 7. Партнеры
CREATE TABLE partner (
    id SERIAL PRIMARY KEY,
    partner_type_id INTEGER REFERENCES partner_type(id) ON DELETE RESTRICT,
    partner_name VARCHAR(100) NOT NULL,
    director_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    legal_address TEXT NOT NULL,
    inn BYTEA NOT NULL,
    rating INTEGER DEFAULT 0,
	logo TEXT, -- Путь к логотипу 
    sales_locations TEXT, -- Места продаж
    login VARCHAR(50) UNIQUE, -- Для входа в ЛК
    password VARCHAR(100)     -- Для входа в ЛК
);

-- 8. Материалы
CREATE TABLE material (
    id SERIAL PRIMARY KEY,
    material_type_id INTEGER REFERENCES material_type(id) ON DELETE RESTRICT,
    material_name VARCHAR(100) NOT NULL,
    unit VARCHAR(10) NOT NULL, -- Ед. измерения (кг, л, шт)
    count_in_pack INTEGER,     -- Количество в упаковке
    min_count INTEGER,         -- Минимальный остаток
    cost DECIMAL(10, 2) NOT NULL,
    description TEXT,
    image TEXT,                -- Путь к файлу изображения
    current_quantity INTEGER DEFAULT 0 -- Текущий остаток
);

-- 9. Продукция
CREATE TABLE product (
    id SERIAL PRIMARY KEY,
    article VARCHAR(50) NOT NULL UNIQUE, -- Артикул
    product_type_id INTEGER REFERENCES product_type(id) ON DELETE RESTRICT,
    product_name VARCHAR(100) NOT NULL,
    description TEXT,
    image TEXT,
    min_cost_for_partner DECIMAL(10, 2) NOT NULL,
    package_size VARCHAR(50), -- Размеры упаковки (ДхШхВ)
    net_weight DECIMAL(10, 3), -- Вес без упаковки
    gross_weight DECIMAL(10, 3), -- Вес с упаковкой
    certificate_scan TEXT, -- Путь к скану сертификата
    standard_number VARCHAR(50), -- Номер стандарта
    production_time INTEGER, -- Время изготовления (например, в часах)
    cost_price DECIMAL(10, 2), -- Себестоимость
    workshop_number INTEGER, -- Номер цеха
    production_people_count INTEGER -- Кол-во людей для производства
);

-- 10. История изменения стоимости продукции
CREATE TABLE product_cost_history (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    new_cost DECIMAL(10, 2) NOT NULL
);

-- 11. Спецификация продукции (Связь Продукт-Материал)
CREATE TABLE product_material (
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    material_id INTEGER REFERENCES material(id) ON DELETE RESTRICT,
    required_quantity DECIMAL(10, 3) NOT NULL, -- Сколько материала нужно на 1 ед. продукции
    PRIMARY KEY (product_id, material_id)
);

-- 12. История движения материалов (Поставки и списания)
CREATE TABLE material_supply_history (
    id SERIAL PRIMARY KEY,
    material_id INTEGER REFERENCES material(id) ON DELETE CASCADE,
    supplier_id INTEGER REFERENCES supplier(id) ON DELETE SET NULL, -- NULL если это списание в производство
    operation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    quantity_changed INTEGER NOT NULL -- Положительное - приход, отрицательное - расход
);

-- 13. Заявки (Заказы)
CREATE TABLE request (
    id SERIAL PRIMARY KEY,
    partner_id INTEGER REFERENCES partner(id) ON DELETE CASCADE,
    manager_id INTEGER REFERENCES staff(id) ON DELETE SET NULL,
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL DEFAULT 'Новая', -- Статусы: Новая, Ожидает оплаты, В производстве, Готова, Выполнена
    payment_date TIMESTAMP -- Дата оплаты (для проверки правила 3 дней) 
);

-- 14. Состав заявки
CREATE TABLE request_product (
    id SERIAL PRIMARY KEY,
    request_id INTEGER REFERENCES request(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES product(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
	-- Менеджер указывает стоимость и дату производства для каждой единицы:
    actual_price DECIMAL(10, 2) NOT NULL, -- Цена продажи (может отличаться от min_cost из-за скидок)
    planned_production_date DATE -- Дата, к которой продукция будет произведена
);

-- 15. Журнал посещений (СКУД)
CREATE TABLE access_log (
    id SERIAL PRIMARY KEY,
    staff_id INTEGER REFERENCES staff(id) ON DELETE CASCADE,
    entry_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entry_type VARCHAR(10) CHECK (entry_type IN ('Вход', 'Выход'))
);