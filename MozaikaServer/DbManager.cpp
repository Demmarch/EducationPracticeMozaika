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

bool DbManager::updateDataEmployee(const QJsonObject &data) {
    if (!data.contains("id")) return false;
    int id = data["id"].toInt();

    QStringList setClauses;

    // Проверяем наличие полей в JSON перед добавлением в SQL
    if (data.contains("surname"))       setClauses << "surname = :surname";
    if (data.contains("name"))          setClauses << "name = :name";
    if (data.contains("patronymic"))    setClauses << "patronymic = :patr";
    if (data.contains("position_id"))   setClauses << "position_id = :pos_id";
    if (data.contains("birth_date"))    setClauses << "birth_date = :bdate";
    if (data.contains("bank_account"))  setClauses << "bank_account = :acc";
    if (data.contains("phone"))         setClauses << "phone = :phone";
    if (data.contains("family_status")) setClauses << "family_status = :fam";
    if (data.contains("health_info"))   setClauses << "health_info = :health";

    if (setClauses.isEmpty()) return false;

    QString queryString = "UPDATE staff SET " + setClauses.join(", ") + " WHERE id = :id";
    QSqlQuery query;
    query.prepare(queryString);
    query.bindValue(":id", id);

    // Биндим только то, что есть
    if (data.contains("surname"))       query.bindValue(":surname", data["surname"].toString());
    if (data.contains("name"))          query.bindValue(":name", data["name"].toString());
    if (data.contains("patronymic"))    query.bindValue(":patr", data["patronymic"].toString());
    if (data.contains("position_id"))   query.bindValue(":pos_id", data["position_id"].toInt());
    if (data.contains("birth_date"))    query.bindValue(":bdate", data["birth_date"].toString());
    if (data.contains("bank_account"))  query.bindValue(":acc", data["bank_account"].toString());
    if (data.contains("phone"))         query.bindValue(":phone", data["phone"].toString());
    if (data.contains("family_status")) query.bindValue(":fam", data["family_status"].toString());
    if (data.contains("health_info"))   query.bindValue(":health", data["health_info"].toString());

    if (!query.exec()) {
        qDebug() << "Update Employee Error:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DbManager::updateDataPartner(const QJsonObject &data) {
    if (!data.contains("id")) return false;
    int id = data["id"].toInt();

    QStringList setClauses;

    // Проверяем наличие полей в JSON перед добавлением в SQL
    if (data.contains("partner_name"))      setClauses << "partner_name = :p_name";
    if (data.contains("director_name"))     setClauses << "director_name = :d_name";
    if (data.contains("email"))             setClauses << "email = :email";
    if (data.contains("phone"))             setClauses << "phone = :phone";
    if (data.contains("legal_address"))     setClauses << "legal_address = :addr";
    if (data.contains("partner_type_id"))   setClauses << "partner_type_id = :type_id";
    if (data.contains("login"))             setClauses << "login = :login";
    if (data.contains("rating"))            setClauses << "rating = :rating";
    if (data.contains("logo"))              setClauses << "logo = :logo";
    if (data.contains("sales_locations"))   setClauses << "sales_locations = :loc";

    if (setClauses.isEmpty()) return false;

    QString queryString = "UPDATE partner SET " + setClauses.join(", ") + " WHERE id = :id";
    QSqlQuery query;
    query.prepare(queryString);
    query.bindValue(":id", id);

    // Биндим только существующие значения
    if (data.contains("partner_name"))      query.bindValue(":p_name", data["partner_name"].toString());
    if (data.contains("director_name"))     query.bindValue(":d_name", data["director_name"].toString());
    if (data.contains("email"))             query.bindValue(":email", data["email"].toString());
    if (data.contains("phone"))             query.bindValue(":phone", data["phone"].toString());
    if (data.contains("legal_address"))     query.bindValue(":addr", data["legal_address"].toString());
    if (data.contains("partner_type_id"))   query.bindValue(":type_id", data["partner_type_id"].toInt());
    if (data.contains("login"))             query.bindValue(":login", data["login"].toString());
    if (data.contains("rating"))            query.bindValue(":rating", data["rating"].toInt());
    if (data.contains("logo"))              query.bindValue(":logo", data["logo"].toString());
    if (data.contains("sales_locations"))   query.bindValue(":loc", data["sales_locations"].toString());

    if (!query.exec()) {
        qDebug() << "Update Partner Error:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DbManager::updateStaffSensitiveData(const QJsonObject &data)
{
    if (!data.contains("id")) return false;
    int id = data["id"].toInt();
    QStringList setClauses;

    // Логин
    if (data.contains("login") && !data["login"].toString().isEmpty()) {
        setClauses << "login = :login";
    }
    // Пароль
    if (data.contains("password") && !data["password"].toString().isEmpty()) {
        setClauses << "password = crypt(:password, gen_salt('bf'))";
    }
    // Паспорт
    if (data.contains("passport_details") && !data["passport_details"].toString().isEmpty()) {
        setClauses << "passport_details = pgp_sym_encrypt(:passport_details, 'Mozaika2025')";
    }

    if (setClauses.isEmpty()) return true; // Ничего обновлять не надо

    QString queryString = "UPDATE staff SET " + setClauses.join(", ") + " WHERE id = :id";
    QSqlQuery query;
    query.prepare(queryString);
    query.bindValue(":id", id);

    if (data.contains("login"))
        query.bindValue(":login", data["login"].toString());
    if (data.contains("password"))
        query.bindValue(":password", data["password"].toString());
    if (data.contains("passport_details"))
        query.bindValue(":passport_details", data["passport_details"].toString());

    if (!query.exec()) {
        qDebug() << "Update Staff Sensitive Error:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DbManager::updatePartnerSensitiveData(const QJsonObject &data)
{
    if (!data.contains("id")) return false;
    int id = data["id"].toInt();
    QStringList setClauses;

    // Логин
    if (data.contains("login") && !data["login"].toString().isEmpty()) {
        setClauses << "login = :login";
    }
    // Пароль
    if (data.contains("password") && !data["password"].toString().isEmpty()) {
        setClauses << "password = crypt(:password, gen_salt('bf'))";
    }
    // ИНН
    if (data.contains("inn") && !data["inn"].toString().isEmpty()) {
        setClauses << "inn = pgp_sym_encrypt(:inn, 'Mozaika2025')";
    }

    if (setClauses.isEmpty()) return true;

    QString queryString = "UPDATE partner SET " + setClauses.join(", ") + " WHERE id = :id";
    QSqlQuery query;
    query.prepare(queryString);
    query.bindValue(":id", id);

    if (data.contains("login"))
        query.bindValue(":login", data["login"].toString());
    if (data.contains("password"))
        query.bindValue(":password", data["password"].toString());
    if (data.contains("inn"))
        query.bindValue(":inn", data["inn"].toString());

    if (!query.exec()) {
        qDebug() << "Update Partner Sensitive Error:" << query.lastError().text();
        return false;
    }
    return true;
}
