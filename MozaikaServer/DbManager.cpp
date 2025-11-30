#include "DbManager.h"
#include "Entities.h"

DbManager::DbManager() {}

DbManager::~DbManager() {
    if (m_db.isOpen()) {
        m_db.close();
    }
}

DbManager& DbManager::instance() {
    static DbManager instance;
    return instance;
}

bool DbManager::connectToDb() {
    m_db = QSqlDatabase::addDatabase("QPSQL");
    m_db.setHostName("localhost");
    m_db.setDatabaseName("MozaikaDB");
    m_db.setUserName("postgres");
    m_db.setPassword("demmarc");
    m_db.setPort(5432);

    if (!m_db.open()) {
        qDebug() << "Ошибка подключения к БД:" << m_db.lastError().text();
        return false;
    }
    qDebug() << "Подключение к БД успешно!";
    return true;
}

// === Получение материалов (Возвращает List<Material>) ===
QList<Material> DbManager::getAllMaterials() {
    QList<Material> result;
    if (!m_db.isOpen()) return result;

    QSqlQuery query;
    query.prepare("SELECT m.id, m.material_name, m.current_quantity, "
                  "m.min_count, m.cost, m.unit, m.count_in_pack, m.image, "
                  "m.material_type_id, m.description, " // Добавили поля
                  "mt.type_name "
                  "FROM material m "
                  "JOIN material_type mt ON m.material_type_id = mt.id "
                  "ORDER BY m.id ASC");

    if (query.exec()) {
        while (query.next()) {
            Material m;
            m.id = query.value("id").toInt();
            m.title = query.value("material_name").toString();
            m.currentQuantity = query.value("current_quantity").toInt();
            m.minCount = query.value("min_count").toInt();
            m.cost = query.value("cost").toDouble();
            m.unit = query.value("unit").toString();
            m.countInPack = query.value("count_in_pack").toInt();
            m.image = query.value("image").toString();
            m.typeName = query.value("type_name").toString();
            m.typeId = query.value("material_type_id").toInt();
            m.description = query.value("description").toString();

            result.append(m);
        }
    } else {
        qDebug() << "SQL Error (getAllMaterials):" << query.lastError().text();
    }
    return result;
}

// === Добавление материала (Принимает Material) ===
bool DbManager::addMaterial(const Material &m) {
    QSqlQuery query;
    query.prepare("INSERT INTO material (material_name, material_type_id, current_quantity, "
                  "unit, count_in_pack, min_count, cost, description, image) "
                  "VALUES (:name, :type_id, :qty, :unit, :pack, :min, :cost, :desc, :img)");

    query.bindValue(":name", m.title);
    query.bindValue(":type_id", m.typeId);
    query.bindValue(":qty", m.currentQuantity);
    query.bindValue(":unit", m.unit);
    query.bindValue(":pack", m.countInPack);
    query.bindValue(":min", m.minCount);
    query.bindValue(":cost", m.cost);
    query.bindValue(":desc", m.description);
    query.bindValue(":img", m.image);

    if (!query.exec()) {
        qDebug() << "Insert error:" << query.lastError().text();
        return false;
    }
    return true;
}

// === Обновление материала (Принимает Material) ===
bool DbManager::updateMaterial(const Material &m) {
    QSqlQuery query;
    query.prepare("UPDATE material SET material_name = :name, material_type_id = :type_id, "
                  "current_quantity = :qty, unit = :unit, count_in_pack = :pack, "
                  "min_count = :min, cost = :cost, description = :desc, image = :img "
                  "WHERE id = :id");

    query.bindValue(":id", m.id);
    query.bindValue(":name", m.title);
    query.bindValue(":type_id", m.typeId);
    query.bindValue(":qty", m.currentQuantity);
    query.bindValue(":unit", m.unit);
    query.bindValue(":pack", m.countInPack);
    query.bindValue(":min", m.minCount);
    query.bindValue(":cost", m.cost);
    query.bindValue(":desc", m.description);
    query.bindValue(":img", m.image);

    if (!query.exec()) {
        qDebug() << "Update error:" << query.lastError().text();
        return false;
    }
    return true;
}

QJsonArray DbManager::getMaterialTypes() {
    QJsonArray result;
    QSqlQuery query("SELECT id, type_name FROM material_type ORDER BY id ASC");
    while (query.next()) {
        QJsonObject item;
        item["id"] = query.value("id").toInt();
        item["title"] = query.value("type_name").toString();
        result.append(item);
    }
    return result;
}

QJsonArray DbManager::getSuppliersForMaterial(int materialId) {
    QJsonArray result;
    QSqlQuery query;
    query.prepare("SELECT s.supplier_name, s.supplier_type, MIN(h.operation_date) as start_date "
                  "FROM supplier s "
                  "JOIN material_supply_history h ON s.id = h.supplier_id "
                  "WHERE h.material_id = :id "
                  "GROUP BY s.id, s.supplier_name, s.supplier_type");
    query.bindValue(":id", materialId);
    if (query.exec()) {
        while (query.next()) {
            QJsonObject item;
            item["name"] = query.value("supplier_name").toString();
            item["type"] = query.value("supplier_type").toString();
            item["start_date"] = query.value("start_date").toDateTime().toString("dd.MM.yyyy");
            item["rating"] = 5;
            result.append(item);
        }
    }
    return result;
}

UserInfo DbManager::authorizeUser(const QString &login, const QString &password) {
    UserInfo info;
    info.isAuthenticated = false;
    QSqlQuery query;

    // 1. Staff
    query.prepare("SELECT id, surname, name, position_id FROM staff "
                  "WHERE login = :login AND password = crypt(:pass, password)");
    query.bindValue(":login", login);
    query.bindValue(":pass", password);

    if (query.exec() && query.next()) {
        info.isAuthenticated = true;
        info.id = query.value("id").toInt();
        info.name = query.value("surname").toString() + " " + query.value("name").toString();
        info.role = "manager";
        return info;
    }

    // 2. Partner
    query.prepare("SELECT id, partner_name FROM partner "
                  "WHERE login = :login AND password = crypt(:pass, password)");
    query.bindValue(":login", login);
    query.bindValue(":pass", password);

    if (query.exec() && query.next()) {
        info.isAuthenticated = true;
        info.id = query.value("id").toInt();
        info.name = query.value("partner_name").toString();
        info.role = "partner";
        return info;
    }
    return info;
}

// === Регистрация Партнера (Принимает Partner) ===
bool DbManager::registerPartner(const Partner &p) {
    QSqlQuery query;
    query.prepare("INSERT INTO partner (partner_name, director_name, email, phone, "
                  "legal_address, inn, partner_type_id, login, password, rating, logo, sales_locations) "
                  "VALUES (:p_name, :d_name, :email, :phone, :addr, "
                  "pgp_sym_encrypt(:inn, 'Mozaika2025'), :type_id, :login, "
                  "crypt(:password, gen_salt('bf')), 0, :logo, :loc)");

    query.bindValue(":p_name", p.name);
    query.bindValue(":d_name", p.director);
    query.bindValue(":email", p.email);
    query.bindValue(":phone", p.phone);
    query.bindValue(":addr", p.legalAddress);
    query.bindValue(":inn", p.inn);
    query.bindValue(":type_id", p.typeId);
    query.bindValue(":login", p.login);
    query.bindValue(":password", p.password);
    query.bindValue(":logo", p.logo);
    query.bindValue(":loc", p.salesLocations);

    if (!query.exec()) {
        qDebug() << "Register Partner Error:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DbManager::registerEmployee(const Staff &staff) {
    QSqlQuery query;
    query.prepare("INSERT INTO staff (surname, name, patronymic, position_id, birth_date, "
                  "passport_details, bank_account, phone, login, password, family_status, health_info) "
                  "VALUES (:surname, :name, :patr, :pos_id, :bdate, "
                  "pgp_sym_encrypt(:pass_det, 'Mozaika2025'), :acc, :phone, :login, "
                  "crypt(:password, gen_salt('bf')), :fam, :health)");

    query.bindValue(":surname", staff.surname);
    query.bindValue(":name", staff.name);
    query.bindValue(":patr", staff.patronymic);
    query.bindValue(":pos_id", staff.positionId);
    query.bindValue(":bdate", staff.birthDate);
    query.bindValue(":pass_det", staff.passportDetails);
    query.bindValue(":acc", staff.bankAccount);
    query.bindValue(":phone", staff.phone);
    query.bindValue(":login", staff.login);
    query.bindValue(":password", staff.password);
    query.bindValue(":fam", staff.familyStatus);
    query.bindValue(":health", staff.healthInfo);

    if (!query.exec()) {
        qDebug() << "Register Employee Error:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DbManager::updateDataEmployee(const Staff &staff) {
    QSqlQuery query;
    query.prepare("UPDATE staff SET surname=:surname, name=:name, patronymic=:patr, "
                  "position_id=:pos_id, birth_date=:bdate, bank_account=:acc, "
                  "phone=:phone, login=:login, family_status=:fam, health_info=:health "
                  "WHERE id=:id");

    query.bindValue(":id", staff.id);
    query.bindValue(":surname", staff.surname);
    query.bindValue(":name", staff.name);
    query.bindValue(":patr", staff.patronymic);
    query.bindValue(":pos_id", staff.positionId);
    query.bindValue(":bdate", staff.birthDate);
    query.bindValue(":acc", staff.bankAccount);
    query.bindValue(":phone", staff.phone);
    query.bindValue(":login", staff.login);
    query.bindValue(":fam", staff.familyStatus);
    query.bindValue(":health", staff.healthInfo);

    if (!query.exec()) {
        qDebug() << "Update Employee Error:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DbManager::updateDataPartner(const Partner &partner) {
    QSqlQuery query;
    query.prepare("UPDATE partner SET partner_name=:p_name, director_name=:d_name, "
                  "email=:email, phone=:phone, legal_address=:addr, partner_type_id=:type_id, "
                  "login=:login, rating=:rating, logo=:logo, sales_locations=:loc "
                  "WHERE id=:id");

    query.bindValue(":id", partner.id);
    query.bindValue(":p_name", partner.name);
    query.bindValue(":d_name", partner.director);
    query.bindValue(":email", partner.email);
    query.bindValue(":phone", partner.phone);
    query.bindValue(":addr", partner.legalAddress);
    query.bindValue(":type_id", partner.typeId);
    query.bindValue(":login", partner.login);
    query.bindValue(":rating", partner.rating);
    query.bindValue(":logo", partner.logo);
    query.bindValue(":loc", partner.salesLocations);

    if (!query.exec()) {
        qDebug() << "Update Partner Error:" << query.lastError().text();
        return false;
    }
    return true;
}
