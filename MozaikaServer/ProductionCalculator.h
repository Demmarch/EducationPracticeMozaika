#ifndef PRODUCTIONCALCULATOR_H
#define PRODUCTIONCALCULATOR_H

class ProductionCalculator
{
public:
    static int calculateOutput(int productTypeId,
                               int materialTypeId,
                               int materialQuantity,
                               double param1,
                               double param2);
};

#endif // PRODUCTIONCALCULATOR_H
