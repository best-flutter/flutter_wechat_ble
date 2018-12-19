import 'dart:async';

import 'package:flutter/services.dart';

class FlutterWechatBle {
  static const MethodChannel _channel =
      const MethodChannel('flutter_wechat_ble');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
