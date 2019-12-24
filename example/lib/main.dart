import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter_wechat_ble_example/screens/ble_helper.dart';

import 'package:easy_alert/easy_alert.dart';
import 'package:flutter_wechat_ble_example/screens/home.dart';
import 'package:flutter_wechat_ble_example/services/AcrDeviceConfig.dart';
import 'package:flutter_wechat_ble_example/services/R30DeviceConfig.dart';
import 'package:flutter_wechat_ble_example/services/TkbDeviceConfig.dart';
import 'package:flutter_wechat_ble/bluetooth_service.dart';
import 'package:easy_alert/easy_alert.dart';

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

    BluetoothService.createInstance(
        [new TbkDeviceConfig(), new R30DeviceConfig(), new AcrDeviceConfig()]);

    // startup();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: new AlertProvider(
        child: new Home(),
      ),
    );
  }
}
