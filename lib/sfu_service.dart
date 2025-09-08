import 'package:flutter/material.dart';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:real_multicasting/socket_service.dart';

class SFUService {
  final device = Device();
  final socketService = SocketService();

  // Step 1: Load Device with Router Capabilities
  Future<Device> getDevice() async {
    final routerRtpCapabilities = await socketService.joinRoom();
    await device.load(routerRtpCapabilities: routerRtpCapabilities);
    debugPrint('Step2️⃣ Device loaded');
    return device;
  }

  // Step 2: Create Send Transport for sending media (mic/cam)
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
    // Step 3: Handle DTLS Connect event
    // sendTransport.on('connect', (dtlsParameters) {
    //   socketService.socket.emit('connectTransport', {
    //     'transportId': data['id'],
    //     'dtlsParameters': (dtlsParameters as DtlsParameters).toMap(),
    //   });
    // });
    sendTransport.on('connect', (dtlsParameters) {
      socketService.socket.emit('connectTransport', {
        // 'transportId': data['id'],
        'dtlsParameters': DtlsParameters.fromMap(dtlsParameters),
        'roomId': 'room1',
        'userId': '2',
        'role': 'caster',
        'type': 'send',
      });
    });
    debugPrint('Step5️⃣ Send transport connected');
    // Step 4: Handle Produce event (when sending audio/video track)
    sendTransport.on('produce', (produceData) {
      socketService.socket.emitWithAck(
        'produce',
        {
          'roomId': 'room1',
          'userId': '2',
          'role': 'caster',
          // 'transportId': data['id'],
          'kind': produceData['kind'],
          'rtpParameters':
              (produceData['rtpParameters'] as RtpParameters).toMap(),
          // 'appData': produceData['appData'],
        },
        ack: (producerId) {
          return producerId; // return the producer ID from server
        },
      );
    });
    debugPrint('Step6️⃣ Send transport produced');
    return sendTransport;
  }

  // Step 5: Create Recv Transport (for receiving other peers' media)
  // Future<Transport> createRecvTransport() async {
  //   final data = await socketService.createTransport();

  //   final recvTransport = device.createRecvTransport(
  //     id: data['id'],
  //     iceParameters: IceParameters.fromMap(data['iceParameters']),
  //     iceCandidates:
  //         (data['iceCandidates'] as List)
  //             .map((c) => IceCandidate.fromMap(c))
  //             .toList(),
  //     dtlsParameters: DtlsParameters.fromMap(data['dtlsParameters']),
  //   );

  //   recvTransport.on('connect', (dtlsParameters) {
  //     socketService.socket.emit('connectTransport', {
  //       'transportId': data['id'],
  //       'dtlsParameters': (dtlsParameters as DtlsParameters).toMap(),
  //     });
  //   });

  //   return recvTransport;
  // }
}
