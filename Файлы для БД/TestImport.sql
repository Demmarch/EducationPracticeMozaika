select * from partner_type;
select * from product_type;
select * from material_type;
select * from staff_position;
select * from supplier;
SELECT 
    id,
    surname,
    name,
    pgp_sym_decrypt(passport_details, 'Mozaika2025') AS decrypted_passport,
	login,
	password
FROM staff;
SELECT 
    id,
    login,
    password = crypt('admin123', password) AS admin_password_match,
    password = crypt('manager123', password) AS manager_password_match,
    password = crypt('master123', password) AS master_password_match
FROM staff;

SELECT 
    p.id,
    p.partner_name,
    p.login,
    CASE 
        WHEN pgp_sym_decrypt(p.inn, 'Mozaika2025') IS NOT NULL THEN 'DECRYPTABLE'
        ELSE 'DECRYPT_ERROR'
    END AS inn_encryption_status,
    -- Проверка пароля
    CASE 
        WHEN p.password LIKE '$2a$%' THEN 'HASHED'
        ELSE 'NOT_HASHED'
    END AS password_hash_status,
	CASE 
        WHEN id = 1 AND password = crypt('pass1', password) THEN 'PASSWORD_MATCH'
        WHEN id = 2 AND password = crypt('pass2', password) THEN 'PASSWORD_MATCH'
        ELSE 'PASSWORD_MISMATCH'
    END AS password_check,
    -- Проверка соответствия данных
    CASE 
        WHEN (p.id = 1 AND pgp_sym_decrypt(p.inn, 'Mozaika2025') = '7701000001' AND p.password = crypt('pass1', p.password)) THEN 'ALL_CORRECT'
        WHEN (p.id = 2 AND pgp_sym_decrypt(p.inn, 'Mozaika2025') = '7801000002' AND p.password = crypt('pass2', p.password)) THEN 'ALL_CORRECT'
        ELSE 'DATA_MISMATCH'
    END AS overall_status
FROM partner p
ORDER BY p.id;

select * from material;
select * from product;
select * from request_product;
select * from request;
select * from product_material;
select 'ALL CORRECT' AS FINAL_RESULT;