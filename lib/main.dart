import 'package:flutter/material.dart';

import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:real_multicasting/screen_service.dart';
import 'sfu_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Device? _device;
  bool _isLoading = true;
  final _sfuService = SFUService();

  @override
  void initState() {
    super.initState();
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
                    ElevatedButton(
                      onPressed: () async {
                        // Step 6: Create send transport
                        final sendTransport =
                            await _sfuService.createSendTransport();

                        // Start screen service (your own logic)
                        startScreenService();

                        // Get screen + audio media stream
                        final stream = await navigator.mediaDevices
                            .getDisplayMedia({'audio': false, 'video': true});

                        // ✅ Handle audio track safely
                        // final audioTracks = stream.getAudioTracks();
                        // if (audioTracks.isNotEmpty) {
                        //   final audioTrack = audioTracks.first;
                        //   sendTransport.produce(
                        //     track: audioTrack,
                        //     stream: stream,
                        //     source: 'mic',
                        //   );
                        // } else {
                        //   debugPrint(
                        //     "⚠️ No audio track found in display media stream",
                        //   );
                        // }

                        // ✅ Handle video track safely
                        final videoTracks = stream.getVideoTracks();
                        if (videoTracks.isNotEmpty) {
                          final videoTrack = videoTracks.first;
                          sendTransport.produce(
                            track: videoTrack,
                            stream: stream,
                            source:
                                'screen', // 👈 use 'screen' since it's display media
                          );
                        } else {
                          debugPrint(
                            "⚠️ No video track found in display media stream",
                          );
                        }
                      },

                      child: const Text("Start Camera/Mic"),
                    ),
                  ],
                ),
      ),
    );
  }
}
