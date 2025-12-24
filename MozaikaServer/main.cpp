#define CROW_MAIN
#include "crow.h"
#include <pqxx/pqxx>
#include <iostream>

int main()
{
    crow::SimpleApp app;

    CROW_ROUTE(app, "/")([](){
        return "Hello from Crow via qmake!";
    });

    CROW_ROUTE(app, "/db_check")([](){
        try {
            pqxx::connection c("dbname=MozaikaDB user=postgres password=demmarc host=localhost port=5432");
            if (c.is_open()) {
                return std::string("Database connection successful: ") + c.dbname();
            } else {
                return std::string("Database connection failed");
            }
        } catch (const std::exception &e) {
            return std::string("Error: ") + e.what();
        }
    });

    // Запуск сервера на порту 8080 (Crow по умолчанию HTTP)
    // Ваш старый сервер был на 33333 и использовал raw TCP.
    // Crow использует HTTP, поэтому клиент тоже придется адаптировать под HTTP запросы.
    std::cout << "Starting Crow server on port 8080..." << std::endl;
    app.port(8080).multithreaded().run();

    return 0;
}