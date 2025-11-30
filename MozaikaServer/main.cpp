#include <QCoreApplication>
#include "DbManager.h"
#include "MyTcpServer.h"

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    if (!DbManager::instance().connectToDb()) {
        return -1; // Выход, если нет базы
    }

    MyTcpServer server;
    server.startServer();

    return a.exec();
}
