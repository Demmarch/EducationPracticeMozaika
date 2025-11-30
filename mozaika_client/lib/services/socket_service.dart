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
      // Подключаемся
      socket = await Socket.connect(serverIp, serverPort, timeout: const Duration(seconds: 5));
      
      // Формируем JSON
      final request = {
        'action': action,
        'data': data ?? {}
      };
      
      // Отправляем
      socket.write(jsonEncode(request) + '\n');
      await socket.flush();

      // Читаем ответ
      final completer = Completer<Map<String, dynamic>>();
      final buffer = StringBuffer();

      socket.listen(
        (List<int> event) {
          final chunk = utf8.decode(event);
          buffer.write(chunk);

          if (buffer.toString().endsWith('\n')) {
            try {
              final jsonString = buffer.toString().trim();
              if (jsonString.isNotEmpty) {
                final response = jsonDecode(jsonString);
                
                if (!completer.isCompleted) {
                  completer.complete(response);
                }
                
                socket?.destroy(); 
              }
            } catch (e) {
              if (!completer.isCompleted) {
                completer.completeError("Ошибка парсинга JSON: $e");
              }
            }
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError("Соединение закрыто без ответа");
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
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