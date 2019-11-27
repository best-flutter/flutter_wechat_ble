import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter_wechat_ble_example/screens/home.dart';

import 'package:easy_alert/easy_alert.dart';
import 'package:flutter_wechat_ble_example/services/TbkDeviceConfig.dart';
import 'package:flutter_wechat_ble_example/services/bluetooth_service.dart';

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

//  void startup() async {
//    await bluetoothService.shutdown();
//    bluetoothService.onServiceDeviceFound(onServiceDeviceFound);
//    await bluetoothService.startScan();
//  }
//
//  void onServiceDeviceFound(BluetoothServiceDevice device) async {
//    print("device ${device.device} ${device.name}");
//
//    new Timer(new Duration(seconds: 1), () {
//      print("timeout");
//    });
//    try {
//      await bluetoothService.stopScan();
//      await bluetoothService.startupDevice(device.deviceId);
//      print("write data");
//      HexValue value = await device.write("000062");
//      print("write data success");
//
//      print("=================" + value.string);
//    } on BleError catch (e) {
//      print(
//          ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ${e.code} ${e.message}");
//    } catch (e) {
//      print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $e");
//    }
//  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: new Home(),
    );
  }
}
