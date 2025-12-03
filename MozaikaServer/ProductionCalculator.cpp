#include "ProductionCalculator.h"
#include <cmath>

int ProductionCalculator::calculateOutput(int productTypeId, int materialTypeId, int materialQuantity, double param1, double param2)
{
    // Проверка на некорректные данные (отрицательные числа или несуществующие ID)
    // Согласно заданию, метод должен вернуть -1 при ошибке.
    if (productTypeId <= 0 || materialTypeId <= 0 || materialQuantity < 0 || param1 <= 0 || param2 <= 0) {
        return -1;
    }

    // 1. Коэффициенты типа продукции (заглушка, в реальности берутся из БД или констант)
    // В ТЗ сказано "Коэффициент типа продукции и процент потери... вещественные числа"
    double productCoefficient = 1.0;

    // 2. Процент потери материала (заглушка)
    double materialLossPercent = 0.0; // Например, 0.1 для 10%

    // Логика выбора коэффициентов (Пример)
    if (productTypeId == 1) productCoefficient = 1.25;
    if (materialTypeId == 1) materialLossPercent = 0.05; // 5% брака

    // 3. Расчет необходимого сырья на одну единицу продукции
    // "произведение параметров продукции, умноженное на коэффициент"
    double materialPerUnit = (param1 * param2) * productCoefficient;

    // 4. Учет потерь сырья
    // "необходимое количество сырья должно быть увеличено с учетом возможных потерь"
    double materialPerUnitWithLoss = materialPerUnit * (1.0 + materialLossPercent);

    if (materialPerUnitWithLoss == 0) return -1;

    // 5. Расчет итогового количества продукции
    // Делим все сырье на расход для 1 шт и округляем вниз до целого
    int result = static_cast<int>(std::floor(materialQuantity / materialPerUnitWithLoss));

    return result;
}
