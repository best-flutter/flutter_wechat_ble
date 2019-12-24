import 'package:easy_alert/easy_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat_ble_example/services/TkbDeviceConfig.dart';
import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:simple_permissions/simple_permissions.dart';

class ConnectToTkb extends StatefulWidget {
  @override
  _ConnectToTkbState createState() => _ConnectToTkbState();
}

class _ConnectToTkbState extends State<ConnectToTkb> {
  static DeviceConfig config = new TbkDeviceConfig();

  List<String> messages = [];

  @override
  void initState() {
    super.initState();

    this.startup();
  }

  void startup() async {
    if (!await SimplePermissions.checkPermission(
        Permission.AccessCoarseLocation)) {
      if (PermissionStatus.authorized !=
          await SimplePermissions.requestPermission(
              Permission.AccessCoarseLocation)) {
        Alert.alert(context, title: "请打开蓝牙");
        return;
      }
    }
    BluetoothService bluetoothService = BluetoothService.getInstance();
    bluetoothService.setEnable(index: 0,enable: true);
    bluetoothService.setEnable(index: 1,enable: false);
    bluetoothService.setEnable(index: 2,enable: false);
    await setState(() {
      messages.add("searing devices...");
    });
    await bluetoothService.shutdown();
    bluetoothService.onServiceDeviceFound(onServiceDeviceFound);
    await bluetoothService.startScan();
  }

  void onServiceDeviceFound(BluetoothServiceDevice device) async {
    print("device ${device.device} ${device.name}");
    await setState(() {
      messages.add("startup devices with name TKB_BLE...${device.name}");
    });
    try {
      BluetoothService bluetoothService = BluetoothService.getInstance();
      await bluetoothService.stopScan();
      await bluetoothService.startupDevice(device.deviceId);

      await setState(() {
        messages.add("writing data : 000062");
      });
      print("write data");
      HexValue value = await device.write("000062");
      print("write data success");
      await setState(() {
        messages.add("writing data success, response: ${value.string}");
      });
      print("=================" + value.string);
    } on BleError catch (e) {
      print(
          ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ${e.code} ${e.message}");
      setState(() {
        messages.add("Ble error : ${e.code} ${e.message}");
      });
    } catch (e) {
      print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $e");
      setState(() {
        messages.add("other error : ${e.code} ${e.message}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Connect to tkb"),
        actions: <Widget>[
          new IconButton(
              icon: new Icon(Icons.refresh),
              onPressed: () {
                startup();
              })
        ],
      ),
      body: new ListView(
        children: messages.map((text) => new Text(text)).toList(),
      ),
    );
  }
}
