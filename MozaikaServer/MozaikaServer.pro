QT -= gui
QT += core network sql

CONFIG += c++14 console
CONFIG -= app_bundle

DEFINES += QT_DEPRECATED_WARNINGS

SOURCES += \
    ClientHandler.cpp \
    DbManager.cpp \
    MyTcpServer.cpp \
    ProductionCalculator.cpp \
    main.cpp \

# Заголовки

HEADERS += \
    ClientHandler.h \
    DbManager.h \
    Entities.h \
    MyTcpServer.h \
    ProductionCalculator.h
