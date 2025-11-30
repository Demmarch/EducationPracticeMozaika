#ifndef MYTCPSERVER_H
#define MYTCPSERVER_H

#include <QTcpServer>
#include "ClientHandler.h"

class MyTcpServer : public QTcpServer
{
    Q_OBJECT
public:
    explicit MyTcpServer(QObject *parent = nullptr);
    void startServer();

protected:
    void incomingConnection(qintptr socketDescriptor) override;
};

#endif // MYTCPSERVER_H
