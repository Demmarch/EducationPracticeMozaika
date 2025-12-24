#define CROW_MAIN
#include "crow.h"

#include "DbManager.h"
#include "ProductionCalculator.h"
#include "Entities.h"

#include <iostream>

crow::json::wvalue make_response(const std::string& status, const std::string& message = "") {
    crow::json::wvalue x;
    x["status"] = status;
    if (!message.empty()) {
        x["message"] = message;
    }
    return x;
}

int main()
{
    if (!DbManager::instance().connectToDb()) {
        std::cerr << "CRITICAL: Could not connect to database. Server stopped." << std::endl;
        return -1;
    }

    crow::SimpleApp app;

    // GET /materials -> GET_MATERIALS
    CROW_ROUTE(app, "/materials")
    ([](){
        auto list = DbManager::instance().getAllMaterials();
        
        std::vector<crow::json::wvalue> arr;
        arr.reserve(list.size());
        for (const auto& m : list) {
            arr.push_back(m.toJson());
        }

        crow::json::wvalue res;
        res["status"] = "success";
        res["data"] = std::move(arr);
        return res;
    });

    // Post /materials -> ADD_MATERIAL
    CROW_ROUTE(app, "/materials").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400, "Invalid JSON");

        Material m = Material::fromJson(x);
        bool success = DbManager::instance().addMaterial(m);
        return crow::response(make_response(success ? "success" : "error"));
    });

    // Put /materials -> UPDATE_MATERIAL
    CROW_ROUTE(app, "/materials").methods(crow::HTTPMethod::Put)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400, "Invalid JSON");

        Material m = Material::fromJson(x);
        bool success = DbManager::instance().updateMaterial(m);
        return crow::response(make_response(success ? "success" : "error"));
    });

    // GET /materials/types -> GET_MATERIAL_TYPES
    CROW_ROUTE(app, "/materials/types")
    ([](){
        crow::json::wvalue res;
        res["status"] = "success";
        res["data"] = DbManager::instance().getMaterialTypes();
        return res;
    });

    // GET /materials/<id>/suppliers -> GET_SUPPLIERS
    CROW_ROUTE(app, "/materials/<int>/suppliers")
    ([](int id){
        crow::json::wvalue res;
        res["status"] = "success";
        res["data"] = DbManager::instance().getSuppliersForMaterial(id);
        return res;
    });

    // GET /products -> GET_PRODUCTS
    CROW_ROUTE(app, "/products")
    ([](){
        auto list = DbManager::instance().getAllProducts();
        std::vector<crow::json::wvalue> arr;
        for (const auto& p : list) arr.push_back(p.toJson());

        crow::json::wvalue res;
        res["status"] = "success";
        res["data"] = std::move(arr);
        return res;
    });

    // Post /products -> ADD_PRODUCT
    CROW_ROUTE(app, "/products").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400, "Invalid JSON");

        Product p = Product::fromJson(x);
        bool success = DbManager::instance().addProduct(p);
        
        auto res = make_response(success ? "success" : "error");
        if (!success) res["message"] = "Ошибка добавления (возможно, дубликат артикула)";
        return crow::response(res);
    });

    // Put /products -> UPDATE_PRODUCT
    CROW_ROUTE(app, "/products").methods(crow::HTTPMethod::Put)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400, "Invalid JSON");

        Product p = Product::fromJson(x);
        bool success = DbManager::instance().updateProduct(p);
        return crow::response(make_response(success ? "success" : "error"));
    });

    // DELETE /products/<id> -> DELETE_PRODUCT
    CROW_ROUTE(app, "/products/<int>").methods(crow::HTTPMethod::Delete)
    ([](int id){
        bool success = DbManager::instance().deleteProduct(id);
        auto res = make_response(success ? "success" : "error");
        if (!success) res["message"] = "Нельзя удалить продукт, используемый в заказах";
        return crow::response(res);
    });

    // GET /products/types -> GET_PRODUCT_TYPES
    CROW_ROUTE(app, "/products/types")
    ([](){
        crow::json::wvalue res;
        res["status"] = "success";
        res["data"] = DbManager::instance().getProductTypes();
        return res;
    });

    // Post /production/calculate -> CALCULATE_PRODUCTION
    CROW_ROUTE(app, "/production/calculate").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400, "Invalid JSON");

        if (!x.has("prod_type") || !x.has("mat_type") || !x.has("mat_qty")) {
             return crow::response(400, "Missing parameters");
        }

        int result = ProductionCalculator::calculateOutput(
            x["prod_type"].i(),
            x["mat_type"].i(),
            x["mat_qty"].i(),
            x["p1"].d(),
            x["p2"].d()
        );

        crow::json::wvalue res;
        res["status"] = (result != -1) ? "success" : "error";
        res["result"] = result;
        return crow::response(res);
    });

    // Post /login -> LOGIN
    CROW_ROUTE(app, "/login").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400);

        std::string login = x["login"].s();
        std::string password = x["password"].s();

        UserInfo info = DbManager::instance().authorizeUser(login, password);

        crow::json::wvalue res;
        if (info.isAuthenticated) {
            res["status"] = "success";
            res["role"] = info.role;
            res["user_id"] = info.id;
            res["username"] = info.name;
        } else {
            res["status"] = "error";
            res["message"] = "Неверный логин или пароль";
        }
        return crow::response(res);
    });

    // GET /partners -> GET_PARTNERS
    CROW_ROUTE(app, "/partners")
    ([](){
        auto list = DbManager::instance().getAllPartners();
        std::vector<crow::json::wvalue> arr;
        for (const auto& p : list) arr.push_back(p.toJson());

        crow::json::wvalue res;
        res["status"] = "success";
        res["data"] = std::move(arr);
        return res;
    });

    // Post /partners -> REGISTER_PARTNER
    CROW_ROUTE(app, "/partners").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400);

        Partner p = Partner::fromJson(x);
        bool success = DbManager::instance().registerPartner(p);
        
        auto res = make_response(success ? "success" : "error");
        if (!success) res["message"] = "Ошибка регистрации";
        return crow::response(res);
    });

    // Post /partners/update_data -> UPDATE_PARTNER_DATA
    CROW_ROUTE(app, "/partners/update_data").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400);
        bool success = DbManager::instance().updateDataPartner(x);
        return crow::response(make_response(success ? "success" : "error"));
    });

    // Post /partners/security -> UPDATE_PARTNER_SECURITY
    CROW_ROUTE(app, "/partners/security").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400);
        bool success = DbManager::instance().updatePartnerSensitiveData(x);
        return crow::response(make_response(success ? "success" : "error"));
    });

    // GET /employees -> GET_EMPLOYEES
    CROW_ROUTE(app, "/employees")
    ([](){
        auto list = DbManager::instance().getAllStaff();
        std::vector<crow::json::wvalue> arr;
        for (const auto& s : list) arr.push_back(s.toJson());

        crow::json::wvalue res;
        res["status"] = "success";
        res["data"] = std::move(arr);
        return res;
    });

    // Post /employees -> REGISTER_EMPLOYEE
    CROW_ROUTE(app, "/employees").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400);

        Staff s = Staff::fromJson(x);
        bool success = DbManager::instance().registerEmployee(s);
        return crow::response(make_response(success ? "success" : "error"));
    });

    // Post /employees/update_data -> UPDATE_EMPLOYEE_DATA
    CROW_ROUTE(app, "/employees/update_data").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400);
        bool success = DbManager::instance().updateDataEmployee(x);
        return crow::response(make_response(success ? "success" : "error"));
    });

    // Post /employees/security -> UPDATE_STAFF_SECURITY
    CROW_ROUTE(app, "/employees/security").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400);
        bool success = DbManager::instance().updateStaffSensitiveData(x);
        return crow::response(make_response(success ? "success" : "error"));
    });

    // GET /requests -> GET_REQUESTS
    CROW_ROUTE(app, "/requests")
    ([](){
        auto list = DbManager::instance().getAllRequests();
        std::vector<crow::json::wvalue> arr;
        for (const auto& r : list) arr.push_back(r.toJson());

        crow::json::wvalue res;
        res["status"] = "success";
        res["data"] = std::move(arr);
        return res;
    });

    // GET /requests/<id>/items -> GET_REQUEST_ITEMS
    CROW_ROUTE(app, "/requests/<int>/items")
    ([](int id){
        auto list = DbManager::instance().getRequestItems(id);
        std::vector<crow::json::wvalue> arr;
        for (const auto& item : list) arr.push_back(item.toJson());

        crow::json::wvalue res;
        res["status"] = "success";
        res["data"] = std::move(arr);
        return res;
    });

    CROW_ROUTE(app, "/requests").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400);

        Request r = Request::fromJson(x);
        bool success = DbManager::instance().addRequest(r);
        
        auto res = make_response(success ? "success" : "error");
        if (!success) res["message"] = "Ошибка создания заказа. Проверьте данные.";
        return crow::response(res);
    });

    CROW_ROUTE(app, "/requests").methods(crow::HTTPMethod::Put)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x) return crow::response(400);

        Request r = Request::fromJson(x);
        bool success = DbManager::instance().updateRequest(r);
        return crow::response(make_response(success ? "success" : "error"));
    });

    CROW_ROUTE(app, "/requests/status").methods(crow::HTTPMethod::Post)
    ([](const crow::request& req){
        auto x = crow::json::load(req.body);
        if (!x || !x.has("id") || !x.has("status")) return crow::response(400);

        int id = x["id"].i();
        std::string status = x["status"].s();
        bool success = DbManager::instance().updateRequestStatus(id, status);
        return crow::response(make_response(success ? "success" : "error"));
    });

    std::cout << "Starting Crow server on port 18080..." << std::endl;
    app.port(18080).multithreaded().run();

    return 0;
}