#ifndef ENTITIES_H
#define ENTITIES_H

#include "crow.h"
#include <string>
#include <vector>
#include <iostream>

inline std::string jsonString(const crow::json::rvalue& json, const char* key, const std::string& def = "") {
    if (json.has(key)) {
        return std::string(json[key].s());
    }
    return def;
}

inline int jsonInt(const crow::json::rvalue& json, const char* key, int def = 0) {
    if (json.has(key)) {
        return json[key].i();
    }
    return def;
}

inline double jsonDouble(const crow::json::rvalue& json, const char* key, double def = 0.0) {
    if (json.has(key)) {
        return json[key].d();
    }
    return def;
}

struct Material {
    int id;
    int typeId;
    std::string typeName;       // Из JOIN material_type
    std::string title;          // SQL: material_name
    std::string unit;
    int countInPack;            // SQL: count_in_pack
    int minCount;               // SQL: min_count
    double cost;
    std::string description;
    std::string image;
    std::string imageBase64;
    int currentQuantity;        // SQL: current_quantity

    crow::json::wvalue toJson() const {
        crow::json::wvalue json;
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

    static Material fromJson(const crow::json::rvalue &json) {
        Material m;
        m.id = jsonInt(json, "id");
        m.typeId = jsonInt(json, "material_type_id");
        m.typeName = jsonString(json, "type_name");
        m.title = jsonString(json, "material_name");
        m.unit = jsonString(json, "unit");
        m.countInPack = jsonInt(json, "count_in_pack");
        m.minCount = jsonInt(json, "min_count");
        m.cost = jsonDouble(json, "cost");
        m.description = jsonString(json, "description");
        m.image = jsonString(json, "image");
        m.imageBase64 = jsonString(json, "image_base64");
        m.currentQuantity = jsonInt(json, "current_quantity");
        return m;
    }
};

struct ProductType {
    int id;
    std::string title;

    crow::json::wvalue toJson() const {
        crow::json::wvalue json;
        json["id"] = id;
        json["title"] = title;
        return json;
    }
};

struct Product {
    int id;
    std::string article;        // Артикул
    std::string title;          // Название
    int typeId;                 // ID типа
    std::string type;           // Название типа
    double minCost;             // Мин. стоимость
    std::string description;    // Описание
    std::string image;          // Путь
    std::string imageBase64;    // Картинка

    static Product fromJson(const crow::json::rvalue &json) {
        Product p;
        p.id = jsonInt(json, "id");
        p.article = jsonString(json, "article");
        p.title = jsonString(json, "product_name");
        p.typeId = jsonInt(json, "product_type_id");
        p.minCost = jsonDouble(json, "min_cost_for_partner");
        p.description = jsonString(json, "description");
        p.image = jsonString(json, "image");
        p.imageBase64 = jsonString(json, "image_base64");
        return p;
    }

    crow::json::wvalue toJson() const {
        crow::json::wvalue json;
        json["id"] = id;
        json["article"] = article;
        json["product_name"] = title;
        json["product_type_id"] = typeId;
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
    std::string typeName;   // Из JOIN partner_type
    std::string name;       // SQL: partner_name
    std::string director;   // SQL: director_name
    std::string email;
    std::string phone;
    std::string legalAddress; // SQL: legal_address
    std::string inn;        // SQL: inn
    int rating;
    std::string logo;
    std::string logoBase64;
    std::string salesLocations; // SQL: sales_locations
    std::string login;
    std::string password;
    int discount;

    crow::json::wvalue toJson() const {
        crow::json::wvalue json;
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

    static Partner fromJson(const crow::json::rvalue &json) {
        Partner p;
        p.id = jsonInt(json, "id");
        p.typeId = jsonInt(json, "partner_type_id");
        p.typeName = jsonString(json, "type_name");
        p.name = jsonString(json, "partner_name");
        p.director = jsonString(json, "director_name");
        p.email = jsonString(json, "email");
        p.phone = jsonString(json, "phone");
        p.legalAddress = jsonString(json, "legal_address");
        p.inn = jsonString(json, "inn");
        p.rating = jsonInt(json, "rating");
        p.logo = jsonString(json, "logo");
        p.logoBase64 = jsonString(json, "logo_base64");
        p.salesLocations = jsonString(json, "sales_locations");
        p.login = jsonString(json, "login");
        p.password = jsonString(json, "password");
        return p;
    }
};

struct Staff {
    int id;
    std::string surname;
    std::string name;
    std::string patronymic;
    int positionId;         // SQL: position_id
    std::string positionName; // Из JOIN staff_position
    std::string birthDate;  // Храним как строку YYYY-MM-DD
    std::string passportDetails;
    std::string bankAccount;
    std::string familyStatus;
    std::string healthInfo;
    std::string phone;
    std::string login;
    std::string password;

    crow::json::wvalue toJson() const {
        crow::json::wvalue json;
        json["id"] = id;
        json["surname"] = surname;
        json["name"] = name;
        json["patronymic"] = patronymic;
        json["position_id"] = positionId;
        json["position_name"] = positionName;
        json["birth_date"] = birthDate;
        json["passport_details"] = passportDetails;
        json["bank_account"] = bankAccount;
        json["family_status"] = familyStatus;
        json["health_info"] = healthInfo;
        json["phone"] = phone;
        json["login"] = login;
        json["password"] = password;
        return json;
    }

    static Staff fromJson(const crow::json::rvalue &json) {
        Staff s;
        s.id = jsonInt(json, "id");
        s.surname = jsonString(json, "surname");
        s.name = jsonString(json, "name");
        s.patronymic = jsonString(json, "patronymic");
        s.positionId = jsonInt(json, "position_id");
        s.positionName = jsonString(json, "position_name");
        s.birthDate = jsonString(json, "birth_date");
        s.passportDetails = jsonString(json, "passport_details");
        s.bankAccount = jsonString(json, "bank_account");
        s.familyStatus = jsonString(json, "family_status");
        s.healthInfo = jsonString(json, "health_info");
        s.phone = jsonString(json, "phone");
        s.login = jsonString(json, "login");
        s.password = jsonString(json, "password");
        return s;
    }
};

struct RequestItem {
    int id;
    int requestId;
    int productId;
    std::string productName;    // Для отображения
    std::string productArticle; // Для отображения
    std::string productType;    // Для отображения
    int quantity;
    double actualPrice;
    std::string plannedDate;    // YYYY-MM-DD

    crow::json::wvalue toJson() const {
        crow::json::wvalue json;
        json["id"] = id;
        json["request_id"] = requestId;
        json["product_id"] = productId;
        json["product_name"] = productName;
        json["article"] = productArticle;
        json["type"] = productType;
        json["quantity"] = quantity;
        json["actual_price"] = actualPrice;
        json["planned_date"] = plannedDate;
        return json;
    }

    static RequestItem fromJson(const crow::json::rvalue &json) {
        RequestItem item;
        item.id = jsonInt(json, "id");
        item.requestId = jsonInt(json, "request_id");
        item.productId = jsonInt(json, "product_id");
        item.quantity = jsonInt(json, "quantity");
        item.actualPrice = jsonDouble(json, "actual_price");
        item.plannedDate = jsonString(json, "planned_date");
        return item;
    }
};

struct Request {
    int id;
    int partnerId;
    std::string partnerName;
    int managerId;
    std::string managerName;
    std::string dateCreated; // YYYY-MM-DD HH:MM:SS
    std::string status;
    std::string paymentDate; // YYYY-MM-DD HH:MM:SS

    std::vector<RequestItem> items;

    crow::json::wvalue toJson() const {
        crow::json::wvalue json;
        json["id"] = id;
        json["partner_id"] = partnerId;
        json["partner_name"] = partnerName;
        json["manager_id"] = managerId;
        json["manager_name"] = managerName;
        json["date_created"] = dateCreated;
        json["status"] = status;
        if (!paymentDate.empty()) {
            json["payment_date"] = paymentDate;
        }

        // Сериализация списка
        std::vector<crow::json::wvalue> itemsArr;
        for (const auto &item : items) {
            itemsArr.push_back(item.toJson());
        }
        json["items"] = std::move(itemsArr); // Используем move для вектора wvalue
        return json;
    }

    static Request fromJson(const crow::json::rvalue &json) {
        Request r;
        r.id = jsonInt(json, "id");
        r.partnerId = jsonInt(json, "partner_id");
        r.managerId = jsonInt(json, "manager_id");
        r.status = jsonString(json, "status");
        r.paymentDate = jsonString(json, "payment_date");

        if (json.has("items")) {
            const auto& itemsJson = json["items"];
            // Проходим по JSON массиву
            for (const auto& itemVal : itemsJson) {
                r.items.push_back(RequestItem::fromJson(itemVal));
            }
        }
        return r;
    }
};

struct UserInfo {
    bool isAuthenticated = false;
    std::string role;
    std::string name;
    int id = -1;
};

#endif // ENTITIES_H