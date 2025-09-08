import 'package:flutter/services.dart';

final channel = MethodChannel('screen_share_channel');

Future<void> startScreenService() async {
  await channel.invokeMethod('startService');
}
