#ifndef TST_SERVERTESTS_H
#define TST_SERVERTESTS_H

#include <QObject>
#include <QtTest>

// Подключаем заголовки из проекта сервера, чтобы типы были известны
#include "DbManager.h"
#include "ProductionCalculator.h"
#include "Entities.h"

class ServerTests : public QObject
{
    Q_OBJECT

public:
    ServerTests();
    ~ServerTests();

private slots:
    // Объявление слотов-тестов.
    // Qt Test автоматически запустит все функции, объявленные в private slots.

    // Тест 1: Логика расчета скидок
    void testCalculateDiscount();

    // Тест 2: Калькулятор производства (Модуль 4)
    void testProductionCalculator();

    // Тест 3: Проверка JSON сериализации Материала
    void testMaterialJsonSerialization();
};

#endif // TST_SERVERTESTS_H
