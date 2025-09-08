import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:real_multicasting/details.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  final details = Details('room1', 'caster', '2', 'animesh');
  final IO.Socket socket;

  SocketService()
    : socket = IO.io(
        'https://tfrd3n8l-8100.inc1.devtunnels.ms',
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
        },
      ) {
    socket.onConnect((_) => debugPrint("✅ Connected to server"));
    socket.onConnectError((err) => debugPrint("❌ Connect error: $err"));
    socket.onError((err) => debugPrint("❌ General error: $err"));
    socket.onDisconnect((_) => debugPrint("⚠️ Disconnected from server"));
    socket.connect();
    debugPrint('Connecting to socket server');
  }

  Future<RtpCapabilities> joinRoom() async {
    final completer = Completer<RtpCapabilities>();

    socket.onConnect((_) {
      debugPrint('Socket Connected to the server ✅');
      socket.emitWithAck(
        'joinRoom',
        details,
        ack: (data) {
          try {
            final rtpCaps = RtpCapabilities.fromMap(data['rtpCapabilities']);
            completer.complete(rtpCaps);
          } catch (e) {
            completer.completeError(e);
          }
        },
      );
    });
    debugPrint('Step1️⃣: Room Joined');

    return completer.future;
  }

  // Future<Map<String, dynamic>> createTransport() async {
  //   final completer = Completer<Map<String, dynamic>>();

  //   socket.emitWithAck(
  //     'createWebRtcTransport',
  //     {'forceTcp': false, 'producing': true, 'consuming': false},
  //     ack: (data) {
  //       completer.complete(Map<String, dynamic>.from(data));
  //     },
  //   );

  //   return completer.future;
  // }

  Future<Map<String, dynamic>> createTransport() async {
    final completer = Completer<Map<String, dynamic>>();

    socket.emitWithAck(
      'createTransport',
      {'roomId': 'room1', 'role': 'caster', 'userId': '2', 'type': 'send'},
      ack: (data) {
        completer.complete(Map<String, dynamic>.from(data));
      },
    );
    debugPrint('Step3️⃣ Transport created');
    return completer.future;
  }
}
