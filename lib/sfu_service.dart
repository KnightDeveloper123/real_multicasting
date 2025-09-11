import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:real_multicasting/socket_service.dart';

class SFUService {
  final device = Device();
  final socketService = SocketService();

  Future<Device> getDevice() async {
    final routerRtpCapabilities = await socketService.joinRoom();
    await device.load(routerRtpCapabilities: routerRtpCapabilities);
    debugPrint('Step2️⃣ Device loaded');
    return device;
  }

  Future<Transport> createSendTransport() async {
    final data = await socketService.createTransport();

    final sendTransport = device.createSendTransport(
      id: data['id'],
      iceParameters: IceParameters.fromMap(data['iceParameters']),
      iceCandidates:
          (data['iceCandidates'] as List)
              .map((c) => IceCandidate.fromMap(c))
              .toList(),
      dtlsParameters: DtlsParameters.fromMap(data['dtlsParameters']),
    );
    debugPrint('Step4️⃣ Send transport created');

    // Helper to normalise ack payload to a String id
    String extractStringId(dynamic ackPayload) {
      if (ackPayload == null) return '';
      if (ackPayload is String) return ackPayload;
      if (ackPayload is Map) {
        // common shapes: { id: 'abc' } or { producerId: 'abc' }
        if (ackPayload['id'] != null) return ackPayload['id'].toString();
        if (ackPayload['producerId'] != null) {
          return ackPayload['producerId'].toString();
        }
        if (ackPayload['producer_id'] != null) {
          return ackPayload['producer_id'].toString();
        }
        // fallback: encode the whole map
        return jsonEncode(ackPayload);
      }
      // final fallback
      return ackPayload.toString();
    }

    // connect handler
    sendTransport.on('connect', (data) {
      try {
        final dtlsParams = data['dtlsParameters'] as DtlsParameters;
        final callback = data['callback'];

        socketService.socket.emitWithAck(
          'connectTransport',
          {
            'transportId': sendTransport.id,
            'dtlsParameters': dtlsParams.toMap(),
            'roomId': 'room1',
            'role': 'caster',
            'userId': '2',
            'type': 'send',
          },
          ack: (ackPayload) {
            // some servers just return {} or a status — ensure we call the callback cleanly
            try {
              callback();
            } catch (e) {
              // If callback expects args or different shape, try to call without args.
              debugPrint('connect callback call error: $e');
            }
          },
        );
      } catch (e) {
        debugPrint('connect handler error: ${e.toString()}');
        final errback = data['errback'];
        if (errback != null) errback(e);
      }
    });

    // produce handler
    sendTransport.on('produce', (data) async {
      debugPrint('🎥 Produce event triggered');
      final rtpParams = data['rtpParameters'] as RtpParameters;
      final callback = data['callback'];
      final errback = data['errback'];

      try {
        socketService.socket.emitWithAck(
          'produce',
          {
            'roomId': 'room1',
            'userId': '2',
            'role': 'caster',
            'transportId': sendTransport.id,
            'kind': data['kind'],
            'rtpParameters': rtpParams.toMap(),
            // only add appData if it's already JSON-safe (string or Map)
            if (data['appData'] != null &&
                (data['appData'] is String || data['appData'] is Map))
              'appData': data['appData'],
          },
          ack: (ackPayload) {
            try {
              final producerIdStr = extractStringId(ackPayload);
              debugPrint(
                'Produce ack returned: $ackPayload -> using id: $producerIdStr',
              );
              // call library callback with a String id (what it expects)
              callback(producerIdStr);
            } catch (e) {
              debugPrint('Error while processing produce ack: $e');
              errback(e);
            }
          },
        );
      } catch (e) {
        debugPrint('❌ Produce error (emit failed): ${e.toString()}');
        if (errback != null) errback(e);
      }
    });

    debugPrint('Step6️⃣ Send transport produced');
    return sendTransport;
  }
}
