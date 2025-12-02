#include "ClientHandler.h"
#include "DbManager.h"
#include "ProductionCalculator.h" // Для Модуля 4
#include "Entities.h"

ClientHandler::ClientHandler(qintptr socketDescriptor, QObject *parent)
    : QObject(parent)
{
    m_socket = new QTcpSocket(this);
    m_socket->setSocketDescriptor(socketDescriptor);

    connect(m_socket, &QTcpSocket::readyRead, this, &ClientHandler::onReadyRead);
    connect(m_socket, &QTcpSocket::disconnected, this, &ClientHandler::onDisconnected);

    qDebug() << "Клиент подключен. Дескриптор:" << socketDescriptor;
}

void ClientHandler::onReadyRead()
{
    m_buffer.append(m_socket->readAll());
    while (m_buffer.contains('\n')) {
        int index = m_buffer.indexOf('\n');

        // Извлекаем одну полную строку (запрос)
        QByteArray data = m_buffer.left(index).trimmed();

        // Удаляем обработанную часть из буфера (+1, чтобы удалить сам \n)
        m_buffer.remove(0, index + 1);

        if (data.isEmpty()) {
            continue;
        }

        // Парсим JSON
        QJsonParseError parseError;
        QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);

        if (parseError.error != QJsonParseError::NoError) {
            qDebug() << "JSON Error:" << parseError.errorString();
            QJsonObject err;
            err["status"] = "error";
            err["message"] = "Ошибка парсинга JSON на сервере";
            sendJson(err);
            continue;
        }

        QJsonObject request = doc.object();
        QJsonObject response;

        QString action = request["action"].toString();
        QJsonObject requestData = request["data"].toObject();

        qDebug() << "Action received:" << action;
        // Запрос списка материалов (Модуль 2)
        if (action == "GET_MATERIALS") {
            // Получаем список структур
            QList<Material> materialsList = DbManager::instance().getAllMaterials();

            // Конвертируем список структур в JSON Array
            QJsonArray materialsArray;
            for (const Material &m : materialsList) {
                materialsArray.append(m.toJson());
            }

            response["status"] = "success";
            response["data"] = materialsArray;
        }
        // Пример вызова расчетного метода (Модуль 4)
        else if (action == "CALCULATE_PRODUCTION") {
            QJsonObject params = request["data"].toObject();
            int result = ProductionCalculator::calculateOutput(
                params["prod_type"].toInt(),
                params["mat_type"].toInt(),
                params["mat_qty"].toInt(),
                params["p1"].toDouble(),
                params["p2"].toDouble()
                );
            response["status"] = (result != -1) ? "success" : "error";
            response["result"] = result;
        }
        else if (action == "GET_MATERIAL_TYPES") {
            response["status"] = "success";
            response["data"] = DbManager::instance().getMaterialTypes();
        }
        else if (action == "ADD_MATERIAL") {
            Material m = Material::fromJson(requestData);
            bool success = DbManager::instance().addMaterial(m);
            response["status"] = success ? "success" : "error";
        }
        else if (action == "UPDATE_MATERIAL") {
            Material m = Material::fromJson(requestData);
            bool success = DbManager::instance().updateMaterial(m);
            response["status"] = success ? "success" : "error";
        }
        else if (action == "GET_SUPPLIERS") {
            int matId = requestData["material_id"].toInt();
            response["status"] = "success";
            response["data"] = DbManager::instance().getSuppliersForMaterial(matId);
        }
        else if (action == "GET_PRODUCTS") {
            QList<Product> productList = DbManager::instance().getAllProducts();

            QJsonArray prodArray;
            for (const Product &p : productList) {
                prodArray.append(p.toJson());
            }

            response["status"] = "success";
            response["data"] = prodArray;
        }
        else if (action == "GET_PRODUCT_TYPES") {
            response["status"] = "success";
            response["data"] = DbManager::instance().getProductTypes();
        }
        else if (action == "ADD_PRODUCT") {
            Product p = Product::fromJson(requestData);
            bool success = DbManager::instance().addProduct(p);
            response["status"] = success ? "success" : "error";
            if (!success) response["message"] = "Ошибка добавления (возможно, дубликат артикула)";
        }
        else if (action == "UPDATE_PRODUCT") {
            Product p = Product::fromJson(requestData);
            bool success = DbManager::instance().updateProduct(p);
            response["status"] = success ? "success" : "error";
        }
        else if (action == "DELETE_PRODUCT") {
            int id = requestData["id"].toInt();
            bool success = DbManager::instance().deleteProduct(id);
            response["status"] = success ? "success" : "error";
            if (!success) response["message"] = "Нельзя удалить продукт, используемый в заказах";
        }
        else if (action == "LOGIN") {
            QJsonObject params = request["data"].toObject();
            QString login = params["login"].toString();
            QString pass = params["password"].toString();

            UserInfo info = DbManager::instance().authorizeUser(login, pass);

            if (info.isAuthenticated) {
                response["status"] = "success";
                response["role"] = info.role;
                response["user_id"] = info.id;
                response["username"] = info.name;
            } else {
                response["status"] = "error";
                response["message"] = "Неверный логин или пароль";
            }
        }
        else if (action == "GET_PARTNERS") {
            QList<Partner> partners = DbManager::instance().getAllPartners();
            QJsonArray arr;
            for (const Partner &p : partners) {
                arr.append(p.toJson());
            }
            response["status"] = "success";
            response["data"] = arr;
        }
        else if (action == "GET_EMPLOYEES") {
            QList<Staff> staffList = DbManager::instance().getAllStaff();
            QJsonArray arr;
            for (const Staff &s : staffList) {
                arr.append(s.toJson());
            }
            response["status"] = "success";
            response["data"] = arr;
        }
        else if (action == "REGISTER_PARTNER") {
            Partner p = Partner::fromJson(requestData);
            bool success = DbManager::instance().registerPartner(p);
            response["status"] = success ? "success" : "error";
            if (!success) response["message"] = "Ошибка регистрации";
        }
        else if (action == "REGISTER_EMPLOYEE") {
            Staff s = Staff::fromJson(requestData);
            bool success = DbManager::instance().registerEmployee(s);
            response["status"] = success ? "success" : "error";
        }
        else if (action == "UPDATE_EMPLOYEE_DATA") {
            bool success = DbManager::instance().updateDataEmployee(requestData);
            response["status"] = success ? "success" : "error";
        }
        else if (action == "UPDATE_PARTNER_DATA") {
            bool success = DbManager::instance().updateDataPartner(requestData);
            response["status"] = success ? "success" : "error";
        }
        else if (action == "UPDATE_STAFF_SECURITY") {
            bool success = DbManager::instance().updateStaffSensitiveData(requestData);
            response["status"] = success ? "success" : "error";
        }

        // Ожидает JSON: { "id": 1, "password": "new_pass", "inn": "1234567890" }
        else if (action == "UPDATE_PARTNER_SECURITY") {
            bool success = DbManager::instance().updatePartnerSensitiveData(requestData);
            response["status"] = success ? "success" : "error";
        }
        else {
            response["status"] = "error";
            response["message"] = "Неизвестная команда";
        }

        sendJson(response);
    }
}

void ClientHandler::sendJson(const QJsonObject &json)
{
    QJsonDocument doc(json);
    QByteArray data = doc.toJson(QJsonDocument::Compact);
    // Добавляем символ новой строки как разделитель конца сообщения. Без этого клиентское приложение не поймет, что это конец
    data.append('\n');
    m_socket->write(data);
    m_socket->flush();
}

void ClientHandler::onDisconnected()
{
    qDebug() << "Клиент отключился";
    m_socket->deleteLater();
    // Удаляем сам handler, когда сокет умирает
    this->deleteLater();
}
