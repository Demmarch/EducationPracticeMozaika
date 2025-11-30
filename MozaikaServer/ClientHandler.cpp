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
    // Читаем все данные (для простоты считаем, что JSON приходит целиком)
    QByteArray data = m_socket->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    QJsonObject request = doc.object();
    QJsonObject response;

    QString action = request["action"].toString();
    QJsonObject requestData = request["data"].toObject();

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
        int matId = request["material_id"].toInt();
        response["status"] = "success";
        response["data"] = DbManager::instance().getSuppliersForMaterial(matId);
    }
    if (action == "LOGIN") {
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
        Staff s = Staff::fromJson(requestData);
        bool success = DbManager::instance().updateDataEmployee(s);
        response["status"] = success ? "success" : "error";
    }
    else if (action == "UPDATE_PARTNER_DATA") {
        Partner p = Partner::fromJson(requestData);
        bool success = DbManager::instance().updateDataPartner(p);
        response["status"] = success ? "success" : "error";
    }
    else {
        response["status"] = "error";
        response["message"] = "Неизвестная команда";
    }

    sendJson(response);
}

void ClientHandler::sendJson(const QJsonObject &json)
{
    QJsonDocument doc(json);
    m_socket->write(doc.toJson());
    m_socket->flush();
}

void ClientHandler::onDisconnected()
{
    qDebug() << "Клиент отключился";
    m_socket->deleteLater();
    // Удаляем сам handler, когда сокет умирает
    this->deleteLater();
}
