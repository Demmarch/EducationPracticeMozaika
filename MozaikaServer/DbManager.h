#ifndef DBMANAGER_H
#define DBMANAGER_H

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

#include "Entities.h"

struct UserInfo {
    bool isAuthenticated = false;
    QString role;     // "manager" или "partner"
    QString name;     // Имя для отображения
    int id = -1;
};

class DbManager
{
public:
    static DbManager& instance();
    bool connectToDb();

    // Получение списка материалов (Модуля 2)
    QList<Material> getAllMaterials();

    // Для выпадающего списка типов (Модуль 3)
    QJsonArray getMaterialTypes();

    // Для добавления и редактирования (Модуль 3)
    bool addMaterial(const Material &material);
    bool updateMaterial(const Material &material);

    // Для списка поставщиков (Модуль 4)
    QJsonArray getSuppliersForMaterial(int materialId);

    // Регистрация/авторизация
    UserInfo authorizeUser(const QString &login, const QString &password);
    bool registerPartner(const Partner &partner);
    bool registerEmployee(const Staff &staff);

    // Обновление данных сотрудника/партнера
    bool updateDataEmployee(const Staff &staff);
    bool updateDataPartner(const Partner &partner);
    // Обновляет: login, password, passport_details
    bool updateStaffSensitiveData(const QJsonObject &data);
    // Обновляет: login, password, inn
    bool updatePartnerSensitiveData(const QJsonObject &data);

private:
    DbManager();
    ~DbManager();
    QSqlDatabase m_db;
};

#endif // DBMANAGER_H
