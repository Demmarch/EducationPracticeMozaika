#ifndef ENTITIES_H
#define ENTITIES_H

#include <QString>
#include <QJsonObject>
#include <QDate>
#include <QByteArray>
#include <QVariant>

struct Material {
    int id;
    int typeId;
    QString typeName;       // Из JOIN material_type
    QString title;          // SQL: material_name
    QString unit;
    int countInPack;        // SQL: count_in_pack
    int minCount;           // SQL: min_count
    double cost;
    QString description;
    QString image;
    QString imageBase64;
    int currentQuantity;    // SQL: current_quantity

    QJsonObject toJson() const {
        QJsonObject json;
        json["id"] = id;
        json["material_type_id"] = typeId;
        json["type_name"] = typeName;
        json["material_name"] = title;
        json["unit"] = unit;
        json["count_in_pack"] = countInPack;
        json["min_count"] = minCount;
        json["cost"] = cost;
        json["description"] = description;
        json["image"] = image;
        json["image_base64"] = imageBase64;
        json["current_quantity"] = currentQuantity;
        return json;
    }

    static Material fromJson(const QJsonObject &json) {
        Material m;
        m.id = json["id"].toInt();
        m.typeId = json["material_type_id"].toInt();
        if (json.contains("type_name")) m.typeName = json["type_name"].toString();

        m.title = json["material_name"].toString();
        m.unit = json["unit"].toString();
        m.countInPack = json["count_in_pack"].toInt();
        m.minCount = json["min_count"].toInt();
        m.cost = json["cost"].toDouble();
        m.description = json["description"].toString();
        m.image = json["image"].toString();
        m.imageBase64 = json["image_base64"].toString();
        m.currentQuantity = json["current_quantity"].toInt();
        return m;
    }
};


struct ProductType {
    int id;
    QString title;

    QJsonObject toJson() const {
        QJsonObject json;
        json["id"] = id;
        json["title"] = title;
        return json;
    }
};

// Обновите struct Product
struct Product {
    int id;
    QString article;        // Артикул
    QString title;          // Название
    int typeId;             // ID типа
    QString type;           // Название типа (для отображения)
    double minCost;         // Мин. стоимость
    QString description;    // Описание
    QString image;          // Путь
    QString imageBase64;    // Картинка

    // Добавьте метод парсинга JSON
    static Product fromJson(const QJsonObject &json) {
        Product p;
        p.id = json["id"].toInt();
        p.article = json["article"].toString();
        p.title = json["product_name"].toString();
        p.typeId = json["product_type_id"].toInt();
        p.minCost = json["min_cost_for_partner"].toDouble();
        p.description = json["description"].toString();
        p.image = json["image"].toString();
        p.imageBase64 = json["image_base64"].toString();
        return p;
    }

    QJsonObject toJson() const {
        QJsonObject json;
        json["id"] = id;
        json["article"] = article;
        json["product_name"] = title;
        json["product_type_id"] = typeId; // Важно вернуть ID для редактирования
        json["type_name"] = type;
        json["min_cost_for_partner"] = minCost;
        json["description"] = description;
        json["image"] = image;
        json["image_base64"] = imageBase64;
        return json;
    }
};

struct Partner {
    int id;
    int typeId;             // SQL: partner_type_id
    QString typeName;       // Из JOIN partner_type
    QString name;           // SQL: partner_name
    QString director;       // SQL: director_name
    QString email;
    QString phone;
    QString legalAddress;   // SQL: legal_address
    QString inn;            // SQL: inn (BYTEA, но храним как строку для UI)
    int rating;
    QString logo;
    QString logoBase64;
    QString salesLocations; // SQL: sales_locations
    QString login;
    QString password;
    int discount;

    QJsonObject toJson() const {
        QJsonObject json;
        json["id"] = id;
        json["partner_type_id"] = typeId;
        json["type_name"] = typeName;
        json["partner_name"] = name;
        json["director_name"] = director;
        json["email"] = email;
        json["phone"] = phone;
        json["legal_address"] = legalAddress;
        json["inn"] = inn;
        json["rating"] = rating;
        json["logo"] = logo;
        json["logoBase64"] = logoBase64;
        json["sales_locations"] = salesLocations;
        json["login"] = login;
        json["password"] = password;
        json["discount"] = discount;
        return json;
    }

    static Partner fromJson(const QJsonObject &json) {
        Partner p;
        p.id = json["id"].toInt();
        p.typeId = json["partner_type_id"].toInt();
        if (json.contains("type_name")) p.typeName = json["type_name"].toString();

        p.name = json["partner_name"].toString();
        p.director = json["director_name"].toString();
        p.email = json["email"].toString();
        p.phone = json["phone"].toString();
        p.legalAddress = json["legal_address"].toString();
        p.inn = json["inn"].toString();
        p.rating = json["rating"].toInt();
        p.logo = json["logo"].toString();
        p.logoBase64 = json["logo_base64"].toString();
        p.salesLocations = json["sales_locations"].toString();
        p.login = json["login"].toString();
        p.password = json["password"].toString();
        return p;
    }
};

struct Staff {
    int id;
    QString surname;
    QString name;
    QString patronymic;
    int positionId;         // SQL: position_id
    QString positionName;   // Из JOIN staff_position
    QDate birthDate;        // SQL: birth_date
    QString passportDetails; // SQL: passport_details
    QString bankAccount;    // SQL: bank_account
    QString familyStatus;   // SQL: family_status
    QString healthInfo;     // SQL: health_info
    QString phone;
    QString login;
    QString password;

    QJsonObject toJson() const {
        QJsonObject json;
        json["id"] = id;
        json["surname"] = surname;
        json["name"] = name;
        json["patronymic"] = patronymic;
        json["position_id"] = positionId;
        json["position_name"] = positionName;
        json["birth_date"] = birthDate.toString(Qt::ISODate);
        json["passport_details"] = passportDetails;
        json["bank_account"] = bankAccount;
        json["family_status"] = familyStatus;
        json["health_info"] = healthInfo;
        json["phone"] = phone;
        json["login"] = login;
        json["password"] = password;
        return json;
    }

    static Staff fromJson(const QJsonObject &json) {
        Staff s;
        s.id = json["id"].toInt();
        s.surname = json["surname"].toString();
        s.name = json["name"].toString();
        s.patronymic = json["patronymic"].toString();
        s.positionId = json["position_id"].toInt();
        if (json.contains("position_name")) s.positionName = json["position_name"].toString();

        // String -> QDate
        s.birthDate = QDate::fromString(json["birth_date"].toString(), Qt::ISODate);
        // Base64 String -> QByteArray
        s.passportDetails = json["passport_details"].toString();

        s.bankAccount = json["bank_account"].toString();
        s.familyStatus = json["family_status"].toString();
        s.healthInfo = json["health_info"].toString();
        s.phone = json["phone"].toString();
        s.login = json["login"].toString();
        s.password = json["password"].toString();
        return s;
    }
};

#endif // ENTITIES_H
