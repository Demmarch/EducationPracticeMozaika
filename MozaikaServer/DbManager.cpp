#include "DbManager.h"
#include <iostream>
#include <filesystem>
#include <fstream>
#include <chrono>

namespace fs = std::filesystem;

std::string getImagesDir() {
    fs::path path = fs::current_path() / "img";
    if (!fs::exists(path)) {
        fs::create_directories(path);
    }
    return path.string();
}

// Сохранение Base64 в файл
std::string saveImageToDisk(const std::string &base64Data, const std::string &originalName) {
    if (base64Data.empty()) return "";

    std::string dirPath = getImagesDir();
    
    std::string extension = "jpg";
    size_t dotPos = originalName.find_last_of('.');
    if (dotPos != std::string::npos) {
        extension = originalName.substr(dotPos + 1);
    }

    auto now = std::chrono::system_clock::now().time_since_epoch();
    auto millis = std::chrono::duration_cast<std::chrono::milliseconds>(now).count();
    
    std::string fileName = "material_" + std::to_string(millis) + "." + extension;
    fs::path fullPath = fs::path(dirPath) / fileName;

    std::string decodedData = crow::utility::base64decode(base64Data, base64Data.size());

    std::ofstream file(fullPath, std::ios::binary);
    if (file.is_open()) {
        file.write(decodedData.data(), decodedData.size());
        file.close();
        return fileName;
    }
    return "";
}

// Чтение файла в Base64
std::string loadImageFromDisk(const std::string &fileName) {
    if (fileName.empty()) return "";

    fs::path fullPath = fs::path(getImagesDir()) / fileName;
    
    std::ifstream file(fullPath, std::ios::binary | std::ios::ate);
    if (file.is_open()) {
        std::streamsize size = file.tellg();
        file.seekg(0, std::ios::beg);

        std::string buffer(size, '\0');
        if (file.read(&buffer[0], size)) {
            return crow::utility::base64encode(buffer, buffer.size());
        }
    }
    return "";
}

DbManager::DbManager() {}

DbManager::~DbManager() {
    if (m_connection && m_connection->is_open()) {
        m_connection->close();
    }
}

DbManager& DbManager::instance() {
    static DbManager instance;
    return instance;
}

bool DbManager::connectToDb() {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        // Connection string PostgreSQL.!!
        m_connection = std::make_unique<pqxx::connection>(
            "dbname=MozaikaDB user=postgres password=demmarc host=localhost port=5432");
        
        if (m_connection->is_open()) {
            std::cout << "Connected to database: " << m_connection->dbname() << std::endl;
            return true;
        } else {
            std::cerr << "Can't open database" << std::endl;
            return false;
        }
    } catch (const std::exception &e) {
        std::cerr << "DB Connection Error: " << e.what() << std::endl;
        return false;
    }
}

std::vector<Material> DbManager::getAllMaterials() {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    std::vector<Material> result;
    
    try {
        pqxx::work txn(*m_connection);
        pqxx::result res = txn.exec(
            "SELECT m.id, m.material_name, m.current_quantity, "
            "m.min_count, m.cost, m.unit, m.count_in_pack, m.image, "
            "m.material_type_id, m.description, mt.type_name "
            "FROM material m "
            "JOIN material_type mt ON m.material_type_id = mt.id "
            "ORDER BY m.id ASC"
        );

        for (auto row : res) {
            Material m;
            m.id = row["id"].as<int>();
            m.title = row["material_name"].c_str();
            m.currentQuantity = row["current_quantity"].as<int>();
            m.minCount = row["min_count"].as<int>();
            m.cost = row["cost"].as<double>();
            m.unit = row["unit"].c_str();
            m.countInPack = row["count_in_pack"].as<int>();
            m.image = row["image"].c_str();
            m.typeId = row["material_type_id"].as<int>();
            m.description = row["description"].c_str();
            m.typeName = row["type_name"].c_str();
            
            m.imageBase64 = loadImageFromDisk(m.image);
            
            result.push_back(m);
        }
    } catch (const std::exception &e) {
        std::cerr << "getAllMaterials Error: " << e.what() << std::endl;
    }
    return result;
}

crow::json::wvalue DbManager::getMaterialTypes() {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    std::vector<crow::json::wvalue> resultList;
    
    try {
        pqxx::nontransaction txn(*m_connection);
        pqxx::result res = txn.exec("SELECT id, type_name FROM material_type ORDER BY id ASC");
        
        for (auto row : res) {
            crow::json::wvalue item;
            item["id"] = row["id"].as<int>();
            item["title"] = row["type_name"].c_str();
            resultList.push_back(std::move(item));
        }
    } catch (const std::exception &e) {
        std::cerr << "getMaterialTypes Error: " << e.what() << std::endl;
    }
    
    crow::json::wvalue finalJson;
    finalJson = std::move(resultList);
    return finalJson;
}

std::vector<Product> DbManager::getAllProducts() {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    std::vector<Product> result;
    
    try {
        pqxx::work txn(*m_connection);
        pqxx::result res = txn.exec(
            "SELECT p.id, p.article, p.product_name, p.min_cost_for_partner, "
            "p.image, p.product_type_id, p.description, pt.type_name "
            "FROM product p "
            "JOIN product_type pt ON p.product_type_id = pt.id "
            "ORDER BY p.product_name ASC"
        );

        for (auto row : res) {
            Product p;
            p.id = row["id"].as<int>();
            p.article = row["article"].c_str();
            p.title = row["product_name"].c_str();
            p.minCost = row["min_cost_for_partner"].as<double>();
            p.image = row["image"].c_str();
            p.typeId = row["product_type_id"].as<int>();
            p.description = row["description"].c_str();
            p.type = row["type_name"].c_str();
            
            p.imageBase64 = loadImageFromDisk(p.image);
            
            result.push_back(p);
        }
    } catch (const std::exception &e) {
        std::cerr << "getAllProducts Error: " << e.what() << std::endl;
    }
    return result;
}

crow::json::wvalue DbManager::getProductTypes() {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    std::vector<crow::json::wvalue> resultList;
    try {
        pqxx::nontransaction txn(*m_connection);
        pqxx::result res = txn.exec("SELECT id, type_name FROM product_type ORDER BY id ASC");
        for (auto row : res) {
            crow::json::wvalue item;
            item["id"] = row["id"].as<int>();
            item["title"] = row["type_name"].c_str();
            resultList.push_back(std::move(item));
        }
    } catch (const std::exception &e) {
        std::cerr << "getProductTypes Error: " << e.what() << std::endl;
    }
    crow::json::wvalue finalJson;
    finalJson = std::move(resultList);
    return finalJson;
}

bool DbManager::addProduct(const Product &p) {
    std::string savedFileName = p.image;
    if (!p.imageBase64.empty()) {
        savedFileName = saveImageToDisk(p.imageBase64, p.image);
    }

    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        txn.exec_params(
            "INSERT INTO product (article, product_type_id, product_name, "
            "description, image, min_cost_for_partner) "
            "VALUES ($1, $2, $3, $4, $5, $6)",
            p.article, p.typeId, p.title, p.description, savedFileName, p.minCost
        );
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "addProduct Error: " << e.what() << std::endl;
        return false;
    }
}

bool DbManager::updateProduct(const Product &p) {
    std::string savedFileName = p.image;
    if (!p.imageBase64.empty()) {
        savedFileName = saveImageToDisk(p.imageBase64, p.image);
    }

    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        txn.exec_params(
            "UPDATE product SET article=$1, product_type_id=$2, "
            "product_name=$3, description=$4, image=$5, "
            "min_cost_for_partner=$6 "
            "WHERE id=$7",
            p.article, p.typeId, p.title, p.description, savedFileName, p.minCost, p.id
        );
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "updateProduct Error: " << e.what() << std::endl;
        return false;
    }
}

bool DbManager::deleteProduct(int id) {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        txn.exec_params("DELETE FROM product WHERE id = $1", id);
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "deleteProduct Error: " << e.what() << std::endl;
        return false;
    }
}

bool DbManager::addMaterial(const Material &m) {
    std::string savedFileName = m.image;
    if (!m.imageBase64.empty()) {
        savedFileName = saveImageToDisk(m.imageBase64, m.image);
    }
    
    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        txn.exec_params(
            "INSERT INTO material (material_name, material_type_id, current_quantity, "
            "unit, count_in_pack, min_count, cost, description, image) "
            "VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
            m.title, m.typeId, m.currentQuantity, m.unit, m.countInPack,
            m.minCount, m.cost, m.description, savedFileName
        );
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "addMaterial Error: " << e.what() << std::endl;
        return false;
    }
}

bool DbManager::updateMaterial(const Material &m) {
    std::string savedFileName = m.image;
    if (!m.imageBase64.empty()) {
        savedFileName = saveImageToDisk(m.imageBase64, m.image);
    }

    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        txn.exec_params(
            "UPDATE material SET material_name=$1, material_type_id=$2, "
            "current_quantity=$3, unit=$4, count_in_pack=$5, "
            "min_count=$6, cost=$7, description=$8, image=$9 "
            "WHERE id=$10",
            m.title, m.typeId, m.currentQuantity, m.unit, m.countInPack,
            m.minCount, m.cost, m.description, savedFileName, m.id
        );
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "updateMaterial Error: " << e.what() << std::endl;
        return false;
    }
}

crow::json::wvalue DbManager::getSuppliersForMaterial(int materialId) {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    std::vector<crow::json::wvalue> list;
    try {
        pqxx::work txn(*m_connection);
        pqxx::result res = txn.exec_params(
            "SELECT s.supplier_name, s.supplier_type, to_char(MIN(h.operation_date), 'DD.MM.YYYY') as start_date "
            "FROM supplier s "
            "JOIN material_supply_history h ON s.id = h.supplier_id "
            "WHERE h.material_id = $1 "
            "GROUP BY s.id, s.supplier_name, s.supplier_type",
            materialId
        );
        for(auto row : res) {
            crow::json::wvalue item;
            item["name"] = row["supplier_name"].c_str();
            item["type"] = row["supplier_type"].c_str();
            item["start_date"] = row["start_date"].c_str();
            list.push_back(std::move(item));
        }
    } catch (const std::exception &e) {
        std::cerr << "getSuppliers Error: " << e.what() << std::endl;
    }
    crow::json::wvalue result;
    result = std::move(list);
    return result;
}

UserInfo DbManager::authorizeUser(const std::string &login, const std::string &password) {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    UserInfo info;
    info.isAuthenticated = false;

    try {
        pqxx::work txn(*m_connection);
        
        // Staff
        pqxx::result resStaff = txn.exec_params(
            "SELECT id, surname, name, position_id FROM staff "
            "WHERE login = $1 AND password = crypt($2, password)",
            login, password
        );
        
        if (!resStaff.empty()) {
            info.isAuthenticated = true;
            info.id = resStaff[0]["id"].as<int>();
            info.name = std::string(resStaff[0]["surname"].c_str()) + " " + resStaff[0]["name"].c_str();
            info.role = "manager";
            return info;
        }

        // Partner
        pqxx::result resPart = txn.exec_params(
            "SELECT id, partner_name FROM partner "
            "WHERE login = $1 AND password = crypt($2, password)",
            login, password
        );
        
        if (!resPart.empty()) {
            info.isAuthenticated = true;
            info.id = resPart[0]["id"].as<int>();
            info.name = resPart[0]["partner_name"].c_str();
            info.role = "partner";
            return info;
        }

    } catch (const std::exception &e) {
        std::cerr << "Auth Error: " << e.what() << std::endl;
    }
    return info;
}

bool DbManager::registerPartner(const Partner &p) {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        txn.exec_params(
            "INSERT INTO partner (partner_name, director_name, email, phone, "
            "legal_address, inn, partner_type_id, login, password, rating, logo, sales_locations) "
            "VALUES ($1, $2, $3, $4, $5, "
            "pgp_sym_encrypt($6, 'Mozaika2025'), $7, $8, "
            "crypt($9, gen_salt('bf')), 0, $10, $11)",
            p.name, p.director, p.email, p.phone, p.legalAddress,
            p.inn, p.typeId, p.login, p.password, p.logo, p.salesLocations
        );
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "registerPartner Error: " << e.what() << std::endl;
        return false;
    }
}

bool DbManager::registerEmployee(const Staff &s) {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        txn.exec_params(
            "INSERT INTO staff (surname, name, patronymic, position_id, birth_date, "
            "passport_details, bank_account, phone, login, password, family_status, health_info) "
            "VALUES ($1, $2, $3, $4, $5, "
            "pgp_sym_encrypt($6, 'Mozaika2025'), $7, $8, $9, "
            "crypt($10, gen_salt('bf')), $11, $12)",
            s.surname, s.name, s.patronymic, s.positionId, s.birthDate,
            s.passportDetails, s.bankAccount, s.phone, s.login,
            s.password, s.familyStatus, s.healthInfo
        );
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "registerEmployee Error: " << e.what() << std::endl;
        return false;
    }
}

int DbManager::calculateDiscount(double totalSales) {
    if (totalSales < 10000) return 0;
    if (totalSales < 50000) return 5;
    if (totalSales < 300000) return 10;
    return 15;
}

std::vector<Partner> DbManager::getAllPartners() {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    std::vector<Partner> result;
    try {
        pqxx::work txn(*m_connection);
        pqxx::result res = txn.exec(
            "SELECT p.id, p.legal_address, pt.type_name, p.partner_name, p.director_name, p.phone, p.email, p.rating, "
            "COALESCE(SUM(rp.quantity * rp.actual_price), 0) as total_sales, "
            "pgp_sym_decrypt(p.inn, 'Mozaika2025') as inn, p.login "
            "FROM partner p "
            "JOIN partner_type pt ON p.partner_type_id = pt.id "
            "LEFT JOIN request r ON p.id = r.partner_id "
            "LEFT JOIN request_product rp ON r.id = rp.request_id "
            "GROUP BY p.id, pt.type_name, p.partner_name, p.director_name, p.phone, p.email, p.rating "
            "ORDER BY p.partner_name ASC"
        );

        for (auto row : res) {
            Partner p;
            p.id = row["id"].as<int>();
            p.typeName = row["type_name"].c_str();
            p.name = row["partner_name"].c_str();
            p.director = row["director_name"].c_str();
            p.phone = row["phone"].c_str();
            p.email = row["email"].c_str();
            p.rating = row["rating"].as<int>();
            p.legalAddress = row["legal_address"].c_str();
            p.inn = row["inn"].c_str();
            p.login = row["login"].c_str();

            double totalSales = row["total_sales"].as<double>();
            p.discount = calculateDiscount(totalSales);

            result.push_back(p);
        }
    } catch (const std::exception &e) {
        std::cerr << "getAllPartners Error: " << e.what() << std::endl;
    }
    return result;
}

std::vector<Staff> DbManager::getAllStaff() {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    std::vector<Staff> result;
    try {
        pqxx::work txn(*m_connection);
        pqxx::result res = txn.exec(
            "SELECT s.id, s.surname, s.name, s.patronymic, s.position_id, "
            "sp.position_name, s.birth_date, s.phone, s.bank_account, "
            "s.family_status, s.health_info, s.login, "
            "pgp_sym_decrypt(s.passport_details, 'Mozaika2025') as passport_details "
            "FROM staff s "
            "LEFT JOIN staff_position sp ON s.position_id = sp.id "
            "ORDER BY s.surname ASC"
        );
        
        for (auto row : res) {
            Staff s;
            s.id = row["id"].as<int>();
            s.surname = row["surname"].c_str();
            s.name = row["name"].c_str();
            s.patronymic = row["patronymic"].c_str();
            s.positionId = row["position_id"].as<int>();
            s.positionName = row["position_name"].c_str();
            s.birthDate = row["birth_date"].c_str();
            s.phone = row["phone"].c_str();
            s.bankAccount = row["bank_account"].c_str();
            s.familyStatus = row["family_status"].c_str();
            s.healthInfo = row["health_info"].c_str();
            s.passportDetails = row["passport_details"].c_str();
            s.login = row["login"].c_str();
            s.password = "";
            result.push_back(s);
        }
    } catch (const std::exception &e) {
        std::cerr << "getAllStaff Error: " << e.what() << std::endl;
    }
    return result;
}

std::string getJsonStr(const crow::json::rvalue& json, const char* key) {
    if (json.has(key)) return std::string(json[key].s());
    return "";
}

bool DbManager::updateDataEmployee(const crow::json::rvalue &data) {
    if (!data.has("id")) return false;
    int id = data["id"].i();

    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        
        //Dynamic build query
        std::string sql = "UPDATE staff SET ";
        std::vector<std::string> parts;
        
        if (data.has("surname"))       parts.push_back("surname = " + txn.quote(getJsonStr(data, "surname")));
        if (data.has("name"))          parts.push_back("name = " + txn.quote(getJsonStr(data, "name")));
        if (data.has("patronymic"))    parts.push_back("patronymic = " + txn.quote(getJsonStr(data, "patronymic")));
        if (data.has("position_id"))   parts.push_back("position_id = " + std::to_string(data["position_id"].i()));
        if (data.has("birth_date"))    parts.push_back("birth_date = " + txn.quote(getJsonStr(data, "birth_date")));
        if (data.has("bank_account"))  parts.push_back("bank_account = " + txn.quote(getJsonStr(data, "bank_account")));
        if (data.has("phone"))         parts.push_back("phone = " + txn.quote(getJsonStr(data, "phone")));
        if (data.has("family_status")) parts.push_back("family_status = " + txn.quote(getJsonStr(data, "family_status")));
        if (data.has("health_info"))   parts.push_back("health_info = " + txn.quote(getJsonStr(data, "health_info")));

        if (parts.empty()) return false;

        for (size_t i = 0; i < parts.size(); ++i) {
            sql += parts[i];
            if (i < parts.size() - 1) sql += ", ";
        }
        sql += " WHERE id = " + std::to_string(id);

        txn.exec(sql);
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "updateDataEmployee Error: " << e.what() << std::endl;
        return false;
    }
}

bool DbManager::updateDataPartner(const crow::json::rvalue &data) {
    if (!data.has("id")) return false;
    int id = data["id"].i();

    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        std::string sql = "UPDATE partner SET ";
        std::vector<std::string> parts;

        if (data.has("partner_name"))    parts.push_back("partner_name = " + txn.quote(getJsonStr(data, "partner_name")));
        if (data.has("director_name"))   parts.push_back("director_name = " + txn.quote(getJsonStr(data, "director_name")));
        if (data.has("email"))           parts.push_back("email = " + txn.quote(getJsonStr(data, "email")));
        if (data.has("phone"))           parts.push_back("phone = " + txn.quote(getJsonStr(data, "phone")));
        if (data.has("legal_address"))   parts.push_back("legal_address = " + txn.quote(getJsonStr(data, "legal_address")));
        if (data.has("partner_type_id")) parts.push_back("partner_type_id = " + std::to_string(data["partner_type_id"].i()));
        if (data.has("login"))           parts.push_back("login = " + txn.quote(getJsonStr(data, "login")));
        if (data.has("rating"))          parts.push_back("rating = " + std::to_string(data["rating"].i()));
        if (data.has("logo"))            parts.push_back("logo = " + txn.quote(getJsonStr(data, "logo")));
        if (data.has("sales_locations")) parts.push_back("sales_locations = " + txn.quote(getJsonStr(data, "sales_locations")));

        if (parts.empty()) return false;

        for (size_t i = 0; i < parts.size(); ++i) {
            sql += parts[i];
            if (i < parts.size() - 1) sql += ", ";
        }
        sql += " WHERE id = " + std::to_string(id);

        txn.exec(sql);
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "updateDataPartner Error: " << e.what() << std::endl;
        return false;
    }
}

bool DbManager::updateStaffSensitiveData(const crow::json::rvalue &data) {
    if (!data.has("id")) return false;
    int id = data["id"].i();

    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        std::string sql = "UPDATE staff SET ";
        std::vector<std::string> parts;

        std::string login = getJsonStr(data, "login");
        std::string password = getJsonStr(data, "password");
        std::string passport = getJsonStr(data, "passport_details");

        if (!login.empty()) parts.push_back("login = " + txn.quote(login));
        // crypt
        if (!password.empty()) parts.push_back("password = crypt(" + txn.quote(password) + ", gen_salt('bf'))");
        // pgp_sym_encrypt
        if (!passport.empty()) parts.push_back("passport_details = pgp_sym_encrypt(" + txn.quote(passport) + ", 'Mozaika2025')");

        if (parts.empty()) return true;

        for (size_t i = 0; i < parts.size(); ++i) {
            sql += parts[i];
            if (i < parts.size() - 1) sql += ", ";
        }
        sql += " WHERE id = " + std::to_string(id);

        txn.exec(sql);
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "updateStaffSensitive Error: " << e.what() << std::endl;
        return false;
    }
}

bool DbManager::updatePartnerSensitiveData(const crow::json::rvalue &data) {
    if (!data.has("id")) return false;
    int id = data["id"].i();

    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        std::string sql = "UPDATE partner SET ";
        std::vector<std::string> parts;

        std::string login = getJsonStr(data, "login");
        std::string password = getJsonStr(data, "password");
        std::string inn = getJsonStr(data, "inn");

        if (!login.empty()) parts.push_back("login = " + txn.quote(login));
        if (!password.empty()) parts.push_back("password = crypt(" + txn.quote(password) + ", gen_salt('bf'))");
        if (!inn.empty()) parts.push_back("inn = pgp_sym_encrypt(" + txn.quote(inn) + ", 'Mozaika2025')");

        if (parts.empty()) return true;

        for (size_t i = 0; i < parts.size(); ++i) {
            sql += parts[i];
            if (i < parts.size() - 1) sql += ", ";
        }
        sql += " WHERE id = " + std::to_string(id);

        txn.exec(sql);
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "updatePartnerSensitive Error: " << e.what() << std::endl;
        return false;
    }
}

std::vector<Request> DbManager::getAllRequests() {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    std::vector<Request> result;
    try {
        pqxx::work txn(*m_connection);
        pqxx::result res = txn.exec(
            "SELECT r.id, to_char(r.date_created, 'YYYY-MM-DD HH24:MI:SS') as date_created, r.status, "
            "to_char(r.payment_date, 'YYYY-MM-DD HH24:MI:SS') as payment_date, "
            "r.partner_id, p.partner_name, "
            "r.manager_id, s.surname, s.name "
            "FROM request r "
            "JOIN partner p ON r.partner_id = p.id "
            "LEFT JOIN staff s ON r.manager_id = s.id "
            "ORDER BY r.date_created DESC"
        );
        for (auto row : res) {
            Request r;
            r.id = row["id"].as<int>();
            r.dateCreated = row["date_created"].c_str();
            r.status = row["status"].c_str();
            
            if (!row["payment_date"].is_null())
                r.paymentDate = row["payment_date"].c_str();
            else 
                r.paymentDate = "";

            r.partnerId = row["partner_id"].as<int>();
            r.partnerName = row["partner_name"].c_str();

            if (!row["manager_id"].is_null()) {
                r.managerId = row["manager_id"].as<int>();
                r.managerName = std::string(row["surname"].c_str()) + " " + row["name"].c_str();
            } else {
                r.managerId = 0;
                r.managerName = "Не назначен";
            }
            result.push_back(r);
        }
    } catch (const std::exception &e) {
        std::cerr << "getAllRequests Error: " << e.what() << std::endl;
    }
    return result;
}

std::vector<RequestItem> DbManager::getRequestItems(int requestId) {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    std::vector<RequestItem> result;
    try {
        pqxx::work txn(*m_connection);
        pqxx::result res = txn.exec_params(
            "SELECT rp.id, rp.quantity, rp.actual_price, to_char(rp.planned_production_date, 'YYYY-MM-DD') as planned_date, "
            "rp.product_id, prod.product_name, prod.article, pt.type_name "
            "FROM request_product rp "
            "JOIN product prod ON rp.product_id = prod.id "
            "JOIN product_type pt ON prod.product_type_id = pt.id "
            "WHERE rp.request_id = $1",
            requestId
        );
        for (auto row : res) {
            RequestItem item;
            item.id = row["id"].as<int>();
            item.requestId = requestId;
            item.quantity = row["quantity"].as<int>();
            item.actualPrice = row["actual_price"].as<double>();
            item.plannedDate = row["planned_date"].c_str();

            item.productId = row["product_id"].as<int>();
            item.productName = row["product_name"].c_str();
            item.productArticle = row["article"].c_str();
            item.productType = row["type_name"].c_str();
            result.push_back(item);
        }
    } catch (const std::exception &e) {
        std::cerr << "getRequestItems Error: " << e.what() << std::endl;
    }
    return result;
}

bool DbManager::addRequest(Request &req) {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        
        pqxx::result res = txn.exec_params(
            "INSERT INTO request (partner_id, manager_id, status, date_created) "
            "VALUES ($1, $2, $3, NOW()) RETURNING id, to_char(date_created, 'YYYY-MM-DD HH24:MI:SS')",
            req.partnerId,
            (req.managerId > 0 ? std::make_optional(req.managerId) : std::nullopt),
            (req.status.empty() ? "Новая" : req.status)
        );
        
        if (res.empty()) return false;
        
        req.id = res[0][0].as<int>();
        req.dateCreated = res[0][1].c_str();

        if (!req.items.empty()) {
            for (const auto &item : req.items) {
                std::optional<std::string> planDate;
                if (!item.plannedDate.empty()) planDate = item.plannedDate;

                txn.exec_params(
                    "INSERT INTO request_product (request_id, product_id, quantity, actual_price, planned_production_date) "
                    "VALUES ($1, $2, $3, $4, $5)",
                    req.id, item.productId, item.quantity, item.actualPrice, planDate
                );
            }
        }
        
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "addRequest Error: " << e.what() << std::endl;
        return false;
    }
}

bool DbManager::updateRequest(const Request &req) {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        
        std::optional<std::string> payDate;
        if (!req.paymentDate.empty()) payDate = req.paymentDate;

        txn.exec_params(
            "UPDATE request SET manager_id=$1, status=$2, payment_date=$3 WHERE id=$4",
            (req.managerId > 0 ? std::make_optional(req.managerId) : std::nullopt),
            req.status,
            payDate,
            req.id
        );

        txn.exec_params("DELETE FROM request_product WHERE request_id = $1", req.id);

        if (!req.items.empty()) {
            for (const auto &item : req.items) {
                std::optional<std::string> planDate;
                if (!item.plannedDate.empty()) planDate = item.plannedDate;

                txn.exec_params(
                    "INSERT INTO request_product (request_id, product_id, quantity, actual_price, planned_production_date) "
                    "VALUES ($1, $2, $3, $4, $5)",
                    req.id, item.productId, item.quantity, item.actualPrice, planDate
                );
            }
        }

        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "updateRequest Error: " << e.what() << std::endl;
        return false;
    }
}

bool DbManager::updateRequestStatus(int requestId, const std::string &status) {
    std::lock_guard<std::mutex> lock(m_dbMutex);
    try {
        pqxx::work txn(*m_connection);
        txn.exec_params("UPDATE request SET status = $1 WHERE id = $2", status, requestId);
        txn.commit();
        return true;
    } catch (const std::exception &e) {
        std::cerr << "updateRequestStatus Error: " << e.what() << std::endl;
        return false;
    }
}