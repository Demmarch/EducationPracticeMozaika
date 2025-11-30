#ifndef CLIENTHANDLER_H
#define CLIENTHANDLER_H

#include <QObject>
#include <QTcpSocket>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

class ClientHandler : public QObject
{
    Q_OBJECT
public:
    explicit ClientHandler(qintptr socketDescriptor, QObject *parent = nullptr);

private slots:
    void onReadyRead();
    void onDisconnected();

private:
    QTcpSocket *m_socket;
    void sendJson(const QJsonObject &json);
};

#endif // CLIENTHANDLER_H
