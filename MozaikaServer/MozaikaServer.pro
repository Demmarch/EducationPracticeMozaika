TEMPLATE = app
CONFIG += console c++17
CONFIG -= app_bundle

CONFIG -= qt

# !!!!!Write YOUR include path for Crow!!!!!
INCLUDEPATH +="D:/Programs/Crow 1.3.0/include"

# !!!!!Write for linux/mac!!!!! 
win32 {
    # !!!!!Write YOUR include path for Crow!!!!!
    INCLUDEPATH += D:/Programs/MSYS2/mingw64/include

    # Пути к бинарным библиотекам (.a / .lib)
    LIBS += -LD:/Programs/MSYS2/mingw64/lib
    LIBS += -lpqxx -lpq -lws2_32 -lwsock32 -lbcrypt
}

SOURCES += \
    main.cpp \
    ProductionCalculator.cpp \ # Логика без зависимостей, можно раскомментировать позже
    # DbManager.cpp \            # Требует полного переписывания
    # ClientHandler.cpp          # Требует полного переписывания

HEADERS += \
    Entities.h \
    # DbManager.h \
    ProductionCalculator.h \
    # ClientHandler.h
