-- Для цены у продукта
-- Создаем функцию, которая будет вызвана в триггере
CREATE OR REPLACE FUNCTION trg_product_log_cost_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем, изменилась ли цена
    IF (OLD.min_cost_for_partner IS DISTINCT FROM NEW.min_cost_for_partner) THEN
        INSERT INTO product_cost_history (
            product_id, 
            new_cost, 
            change_date
        )
        VALUES (
            NEW.id, 
            NEW.min_cost_for_partner, 
            NOW()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создаем сам триггер, привязанный к таблице
CREATE TRIGGER update_product_cost_trigger
AFTER UPDATE ON product
FOR EACH ROW
EXECUTE FUNCTION trg_product_log_cost_change();

-- Для материалов
-- Функция обновления остатка при добавлении записи в историю
CREATE OR REPLACE FUNCTION trg_update_material_stock()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE material
    SET current_quantity = current_quantity + NEW.quantity_changed
    WHERE id = NEW.material_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер
CREATE TRIGGER insert_material_history_trigger
AFTER INSERT ON material_supply_history
FOR EACH ROW
EXECUTE FUNCTION trg_update_material_stock();