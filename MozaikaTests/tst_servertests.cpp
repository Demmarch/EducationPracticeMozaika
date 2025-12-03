#include "tst_servertests.h"

// Конструктор и деструктор
ServerTests::ServerTests() {}
ServerTests::~ServerTests() {}

// --- ТЕСТ 1: Расчет скидок ---
void ServerTests::testCalculateDiscount()
{
    // Получаем инстанс DbManager
    DbManager& db = DbManager::instance();

    // < 10 000 -> 0%
    QCOMPARE(db.calculateDiscount(5000.0), 0);
    QCOMPARE(db.calculateDiscount(9999.99), 0);

    // 10 000 ... 49 999 -> 5%
    QCOMPARE(db.calculateDiscount(10000.0), 5);
    QCOMPARE(db.calculateDiscount(25000.0), 5);
    QCOMPARE(db.calculateDiscount(49999.0), 5);

    // 50 000 ... 299 999 -> 10%
    QCOMPARE(db.calculateDiscount(50000.0), 10);
    QCOMPARE(db.calculateDiscount(150000.0), 10);

    // >= 300 000 -> 15%
    QCOMPARE(db.calculateDiscount(300000.0), 15);
    QCOMPARE(db.calculateDiscount(1000000.0), 15);
}

// --- ТЕСТ 2: Калькулятор производства ---
void ServerTests::testProductionCalculator()
{
    // Примерные данные из логики:
    // (10 * 20) * 1.25 * 1.05 = 262.5 (расход на 1 ед)
    // 1000 / 262.5 = 3.8 -> floor -> 3

    int prodTypeId = 1;
    int matTypeId = 1;
    int matQty = 1000;
    double p1 = 10.0;
    double p2 = 20.0;

    int result = ProductionCalculator::calculateOutput(prodTypeId, matTypeId, matQty, p1, p2);

    // Проверяем ожидаемый результат
    QCOMPARE(result, 3);

    // Негативный тест: Отрицательное количество
    int errorResult = ProductionCalculator::calculateOutput(1, 1, -100, 10, 20);
    QCOMPARE(errorResult, -1);
}

// --- ТЕСТ 3: Сериализация JSON ---
void ServerTests::testMaterialJsonSerialization()
{
    Material original;
    original.id = 10;
    original.title = "Test Material";
    original.cost = 150.50;
    original.minCount = 50;
    original.currentQuantity = 100;
    original.unit = "kg";
    original.description = "Test desc";

    QJsonObject json = original.toJson();

    QCOMPARE(json["id"].toInt(), 10);
    QCOMPARE(json["material_name"].toString(), QString("Test Material"));
    QCOMPARE(json["cost"].toDouble(), 150.50);

    Material restored = Material::fromJson(json);

    QCOMPARE(restored.id, original.id);
    QCOMPARE(restored.title, original.title);
    QCOMPARE(restored.cost, original.cost);
}

// Макрос, который создает функцию main() и запускает тесты
QTEST_MAIN(ServerTests)
