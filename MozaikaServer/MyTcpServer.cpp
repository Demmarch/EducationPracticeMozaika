#include "MyTcpServer.h"
#include <QDebug>

MyTcpServer::MyTcpServer(QObject *parent) : QTcpServer(parent) {}

void MyTcpServer::startServer()
{
    if (listen(QHostAddress::Any, 33333)) {
        qDebug() << "Сервер запущен на порту 33333";
    } else {
        qDebug() << "Не удалось запустить сервер!";
    }
}

void MyTcpServer::incomingConnection(qintptr socketDescriptor)
{
    new ClientHandler(socketDescriptor, this);
}
