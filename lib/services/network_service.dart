import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'preferences_service.dart';

class NetworkService {
  static RawDatagramSocket? _recordingSocket;

  /// Sends a command via UDP to the configured PC IP and Port.
  static Future<void> sendCommand(String command) async {
    final ip = PreferencesService.pcIpAddress;
    final portStr = PreferencesService.pcPort;

    if (ip.isEmpty || portStr.isEmpty) {
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null) return;

    try {
      final destination = InternetAddress(ip);
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final data = utf8.encode(command);
      socket.send(data, destination, port);
      socket.close();
      debugPrint("Sent command '$command' to $ip:$port");
    } catch (e) {
      debugPrint("Error sending command: $e");
    }
  }

  /// Binds a UDP socket to listen for key combination feedback from the PC,
  /// and transmits the 'RECORD_START' command to the PC.
  static Future<void> startRecording(Function(String) onKeysReceived) async {
    final ip = PreferencesService.pcIpAddress;
    final portStr = PreferencesService.pcPort;

    if (ip.isEmpty || portStr.isEmpty) {
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null) return;

    try {
      // Close any existing socket first
      stopRecording();

      // Bind socket to any available local port
      _recordingSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      
      _recordingSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _recordingSocket!.receive();
          if (datagram != null) {
            final message = utf8.decode(datagram.data);
            if (message.startsWith("RECORD_RESULT:")) {
              final keys = message.substring("RECORD_RESULT:".length);
              onKeysReceived(keys);
              stopRecording();
            }
          }
        }
      });

      // Send record start command to the PC
      final destination = InternetAddress(ip);
      final data = utf8.encode("RECORD_START");
      _recordingSocket!.send(data, destination, port);
      debugPrint("Sent 'RECORD_START' to $ip:$port");
    } catch (e) {
      debugPrint("Error starting macro recording: $e");
    }
  }

  /// Cancels recording and closes the recording listener socket.
  static void stopRecording() {
    if (_recordingSocket != null) {
      final ip = PreferencesService.pcIpAddress;
      final portStr = PreferencesService.pcPort;
      final port = int.tryParse(portStr);

      if (ip.isNotEmpty && port != null) {
        try {
          // Notify PC to stop hooks
          final destination = InternetAddress(ip);
          final data = utf8.encode("RECORD_STOP");
          _recordingSocket!.send(data, destination, port);
        } catch (_) {}
      }

      _recordingSocket!.close();
      _recordingSocket = null;
      debugPrint("Stopped macro recording listener");
    }
  }
}
