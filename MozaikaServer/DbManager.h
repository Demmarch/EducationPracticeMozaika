#ifndef DBMANAGER_H
#define DBMANAGER_H

#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <pqxx/pqxx> // Библиотека для PostgreSQL
#include "crow.h" // Для crow::json::wvalue
#include "Entities.h"

// Структура UserInfo (адаптирована под std::string)
struct UserInfo {
    bool isAuthenticated = false;
    std::string role;     // "manager" или "partner"
    std::string name;     // Имя для отображения
    int id = -1;
};

class DbManager
{
public:
    // Singleton
    static DbManager& instance();

    // Подключение к БД
    bool connectToDb();

    // === Материалы (Модуль 2) ===
    std::vector<Material> getAllMaterials();
    // Возвращает JSON массив объектов {id, title}
    crow::json::wvalue getMaterialTypes();
    
    bool addMaterial(const Material &material);
    bool updateMaterial(const Material &material);
    
    // Поставщики (Модуль 4)
    crow::json::wvalue getSuppliersForMaterial(int materialId);
    
    // === Продукты ===
    std::vector<Product> getAllProducts();
    crow::json::wvalue getProductTypes();
    bool addProduct(const Product &p);
    bool updateProduct(const Product &p);
    bool deleteProduct(int id);

    // === Регистрация / Авторизация ===
    UserInfo authorizeUser(const std::string &login, const std::string &password);
    bool registerPartner(const Partner &partner);
    bool registerEmployee(const Staff &staff);

    // === Партнеры ===
    std::vector<Partner> getAllPartners();
    int calculateDiscount(double totalSales);
    // Обновление данных партнера (обычные поля)
    bool updateDataPartner(const crow::json::rvalue &data);
    // Обновляет: login, password, inn (Sensetive)
    bool updatePartnerSensitiveData(const crow::json::rvalue &data);

    // === Сотрудники ===
    std::vector<Staff> getAllStaff();
    // Обновление данных сотрудника (обычные поля)
    bool updateDataEmployee(const crow::json::rvalue &data);
    // Обновляет: login, password, passport_details (Sensitive)
    bool updateStaffSensitiveData(const crow::json::rvalue &data);

    // === Заказы ===
    std::vector<Request> getAllRequests();
    std::vector<RequestItem> getRequestItems(int requestId);
    bool addRequest(Request &req); // req передается по ссылке, чтобы обновить ID
    bool updateRequest(const Request &req);
    bool updateRequestStatus(int requestId, const std::string &status);

private:
    DbManager();
    ~DbManager();

    // Запрещаем копирование
    DbManager(const DbManager&) = delete;
    DbManager& operator=(const DbManager&) = delete;

    // Указатель на подключение pqxx
    std::unique_ptr<pqxx::connection> m_connection;
    // Мьютекс для защиты соединения в многопоточной среде Crow
    std::mutex m_dbMutex;
};

#endif // DBMANAGER_H