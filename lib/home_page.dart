import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'sfu_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Device? _device;
  bool _isLoading = true;
  final _sfuService = SFUService();
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  DesktopCapturerSource? selected_source_;
  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    _initDevice();
  }

  Future<void> _initDevice() async {
    try {
      final device = await _sfuService.getDevice();
      setState(() {
        _device = device;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error initializing device: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _hangUp() async {
    await _stop();
    setState(() {
      _inCalling = false;
    });
  }

  Future<void> _stop() async {
    try {
      if (kIsWeb) {
        _localStream?.getTracks().forEach((track) => track.stop());
      }
      await _localStream?.dispose();
      _localStream = null;
      _localRenderer.srcObject = null;
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> selectScreenSourceDialog(BuildContext context) async {
    if (WebRTC.platformIsAndroid) {
      // Android specific
      Future<void> requestBackgroundPermission([bool isRetry = false]) async {
        // Required for android screenshare.
        try {
          var hasPermissions = await FlutterBackground.hasPermissions;
          if (!isRetry) {
            const androidConfig = FlutterBackgroundAndroidConfig(
              notificationTitle: 'Screen Sharing',
              notificationText: 'LiveKit Example is sharing the screen.',
              notificationImportance: AndroidNotificationImportance.normal,
              notificationIcon: AndroidResource(
                name: 'livekit_ic_launcher',
                defType: 'mipmap',
              ),
            );
            hasPermissions = await FlutterBackground.initialize(
              androidConfig: androidConfig,
            );
          }
          if (hasPermissions &&
              !FlutterBackground.isBackgroundExecutionEnabled) {
            await FlutterBackground.enableBackgroundExecution();
          }
        } catch (e) {
          if (!isRetry) {
            return await Future<void>.delayed(
              const Duration(seconds: 1),
              () => requestBackgroundPermission(true),
            );
          }
          print('could not publish video: $e');
        }
      }

      await requestBackgroundPermission();
    }
    await _makeCall(null);
  }

  Future<void> _makeCall(DesktopCapturerSource? source) async {
    final sendTransport = await _sfuService.createSendTransport();
    setState(() {
      selected_source_ = source;
    });

    try {
      // Simpler constraints to avoid plugin warnings
      final videoConstraint =
          selected_source_ == null
              ? true
              : {
                // deviceId shape varies by platform; keep it simple
                'deviceId': selected_source_?.id,
                // prefer top-level frameRate numeric property if supported
                'frameRate': 30,
              };

      final stream = await navigator.mediaDevices.getDisplayMedia(
        <String, dynamic>{
          'video': videoConstraint,
          // audio false for screen share in your code
          'audio': false,
        },
      );

      // handle ended
      stream.getTracks().forEach((t) {
        t.onEnded = () {
          debugPrint('Screen sharing stopped (onEnded).');
        };
      });

      _localStream = stream;
      _localRenderer.srcObject = _localStream;

      final videoTracks = stream.getVideoTracks();
      if (videoTracks.isEmpty) {
        debugPrint('No video tracks found in display media.');
        return;
      }
      final videoTrack = videoTracks.first;
      debugPrint('----> producing track: $videoTrack');

      // await the produce call and catch runtime errors
      try {
        sendTransport.produce(
          track: videoTrack,
          stream: stream,
          source: 'screen',
        );
        debugPrint('Produced track successfully.');
      } catch (produceError) {
        debugPrint('Error during produce(): ${produceError.toString()}');
        // Optionally stop tracks to clean up
        stream.getTracks().forEach((t) => t.stop());
        rethrow;
      }
    } catch (e, st) {
      debugPrint('makeCall error: $e\n$st');
    }

    if (!mounted) return;

    setState(() {
      _inCalling = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SFU Example")),
      body: Center(
        child:
            _isLoading
                ? const Text('')
                : _device == null
                ? const Text("Failed to load device ❌")
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Device loaded successfully ✅"),
                    // ElevatedButton(
                    //   onPressed: () async {
                    //     // Step 6: Create send transport
                    //     final sendTransport =
                    //         await _sfuService.createSendTransport();
                    //     debugPrint('Send transport pan aala re $sendTransport');
                    //     // Start screen service (your own logic)

                    //     // Get screen + audio media stream
                    //     final stream = await navigator.mediaDevices
                    //         .getDisplayMedia({'audio': false, 'video': true});

                    //     // ✅ Handle video track safely
                    //     final videoTracks = stream.getTracks();
                    //     print(
                    //       'Here are the video tracks that we are looking for: ${videoTracks}',
                    //     );
                    //     if (videoTracks.isNotEmpty) {
                    //       final videoTrack = videoTracks.first;
                    //       debugPrint(videoTrack.toString());
                    //       sendTransport.produce(
                    //         track: videoTrack,
                    //         stream: stream,
                    //         source:
                    //             'screen', // 👈 use 'screen' since it's display media
                    //       );
                    //       debugPrint(sendTransport.toString());
                    //     } else {
                    //       debugPrint(
                    //         "⚠️ No video track found in display media stream",
                    //       );
                    //     }
                    //   },

                    //   child: const Text("Start Camera/Mic"),
                    // ),
                    SizedBox(
                      height: 500,
                      width: 500,
                      child: RTCVideoView(_localRenderer),
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _inCalling ? _hangUp() : selectScreenSourceDialog(context);
        },
        tooltip: _inCalling ? 'Hangup' : 'Call',
        child: Icon(_inCalling ? Icons.call_end : Icons.phone),
      ),
    );
  }
}
