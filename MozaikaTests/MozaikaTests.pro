QT -= gui
QT += core network sql testlib

CONFIG += console
CONFIG -= app_bundle
CONFIG += c++17

TARGET = MozaikaTests
TEMPLATE = app

# --- НАСТРОЙКА ПУТЕЙ К СЕРВЕРУ ---
SERVER_DIR = ../MozaikaServer

INCLUDEPATH += $$SERVER_DIR
DEPENDPATH  += $$SERVER_DIR

# --- ИСХОДНЫЙ КОД ТЕСТОВ ---
SOURCES += tst_servertests.cpp
HEADERS += tst_servertests.h
# --- ИСХОДНЫЙ КОД СЕРВЕРА (Для тестирования) ---
# Подключаем реализации классов, которые будем тестировать.
# main.cpp сервера НЕ подключаем!
SOURCES += \
    $$SERVER_DIR/DbManager.cpp \
    $$SERVER_DIR/ProductionCalculator.cpp \
    $$SERVER_DIR/ClientHandler.cpp

HEADERS += \
    $$SERVER_DIR/DbManager.h \
    $$SERVER_DIR/Entities.h \
    $$SERVER_DIR/ProductionCalculator.h \
    $$SERVER_DIR/ClientHandler.h
