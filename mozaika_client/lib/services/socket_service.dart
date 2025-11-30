import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

class SocketService {
  static String get serverIp {
    if (kIsWeb) {
      return 'localhost';
    }
    
    if (Platform.isAndroid) {
      return '10.0.2.2'; 
    }
    
    return 'localhost';
  }
  static const int serverPort = 33333;

  /// Универсальный метод отправки запроса
  Future<Map<String, dynamic>> sendRequest(String action, [Map<String, dynamic>? data]) async {
    Socket? socket;
    try {
      // 1. Подключаемся
      socket = await Socket.connect(serverIp, serverPort, timeout: const Duration(seconds: 5));
      
      // 2. Формируем JSON
      final request = {
        'action': action,
        'data': data ?? {}
      };
      
      // 3. Отправляем
      socket.write(jsonEncode(request));
      await socket.flush();

      // 4. Читаем ответ
      // Слушаем поток данных. Как только придут данные - собираем и парсим.
      final completer = Completer<Map<String, dynamic>>();
      final buffer = StringBuffer();

      socket.listen(
        (List<int> event) {
          final chunk = utf8.decode(event);
          buffer.write(chunk);
        },
        onDone: () {
          // Когда сервер закрыл соединение или закончил передачу
          try {
            if (buffer.isNotEmpty) {
              final response = jsonDecode(buffer.toString());
              completer.complete(response);
            } else {
              completer.completeError("Пустой ответ от сервера");
            }
          } catch (e) {
            completer.completeError("Ошибка парсинга JSON: $e");
          }
        },
        onError: (error) {
          completer.completeError(error);
        },
      );

      // Ждем завершения
      return await completer.future;

    } catch (e) {
      if (kDebugMode) {
        print("Socket Error: $e");
      }
      return {'status': 'error', 'message': 'Ошибка соединения: $e'};
    } finally {
      // Всегда закрываем сокет после операции
      socket?.destroy();
    }
  }
}