import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter_wechat_ble_example/screens/ble_helper.dart';

import 'package:easy_alert/easy_alert.dart';
import 'package:flutter_wechat_ble_example/screens/home.dart';
import 'package:flutter_wechat_ble_example/services/TkbDeviceConfig.dart';
import 'package:flutter_wechat_ble/bluetooth_service.dart';

void main() => runApp(new AlertProvider(
      child: MyApp(),
    ));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
//  static DeviceConfig config = new TbkDeviceConfig();
//  static BluetoothService bluetoothService = new BluetoothService(configs: [config]);

  @override
  void initState() {
    super.initState();

    // startup();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: new Home(),
    );
  }
}
