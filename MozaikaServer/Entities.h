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
        m.currentQuantity = json["current_quantity"].toInt();
        return m;
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
    QString salesLocations; // SQL: sales_locations
    QString login;
    QString password;

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
        json["sales_locations"] = salesLocations;
        json["login"] = login;
        json["password"] = password;
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

struct Product {
    int id;
    QString article;
    int typeId;             // SQL: product_type_id
    QString typeName;       // Из JOIN product_type
    QString name;           // SQL: product_name
    QString description;
    QString image;
    double minCostForPartner; // SQL: min_cost_for_partner
    QString packageSize;    // SQL: package_size
    double netWeight;       // SQL: net_weight
    double grossWeight;     // SQL: gross_weight
    QString certificateScan;// SQL: certificate_scan
    QString standardNumber; // SQL: standard_number
    int productionTime;     // SQL: production_time
    double costPrice;       // SQL: cost_price
    int workshopNumber;     // SQL: workshop_number
    int productionPeopleCount; // SQL: production_people_count

    QJsonObject toJson() const {
        QJsonObject json;
        json["id"] = id;
        json["article"] = article;
        json["product_type_id"] = typeId;
        json["type_name"] = typeName;
        json["product_name"] = name;
        json["description"] = description;
        json["image"] = image;
        json["min_cost_for_partner"] = minCostForPartner;
        json["package_size"] = packageSize;
        json["net_weight"] = netWeight;
        json["gross_weight"] = grossWeight;
        json["certificate_scan"] = certificateScan;
        json["standard_number"] = standardNumber;
        json["production_time"] = productionTime;
        json["cost_price"] = costPrice;
        json["workshop_number"] = workshopNumber;
        json["production_people_count"] = productionPeopleCount;
        return json;
    }

    static Product fromJson(const QJsonObject &json) {
        Product p;
        p.id = json["id"].toInt();
        p.article = json["article"].toString();
        p.typeId = json["product_type_id"].toInt();
        if (json.contains("type_name")) p.typeName = json["type_name"].toString();

        p.name = json["product_name"].toString();
        p.description = json["description"].toString();
        p.image = json["image"].toString();
        p.minCostForPartner = json["min_cost_for_partner"].toDouble();
        p.packageSize = json["package_size"].toString();
        p.netWeight = json["net_weight"].toDouble();
        p.grossWeight = json["gross_weight"].toDouble();
        p.certificateScan = json["certificate_scan"].toString();
        p.standardNumber = json["standard_number"].toString();
        p.productionTime = json["production_time"].toInt();
        p.costPrice = json["cost_price"].toDouble();
        p.workshopNumber = json["workshop_number"].toInt();
        p.productionPeopleCount = json["production_people_count"].toInt();
        return p;
    }
};

#endif // ENTITIES_H
