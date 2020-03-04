import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';

import 'package:flutter/material.dart';
import 'package:flutter_wechat_ble_example/screens/DeviceItem.dart';
import 'package:flutter_wechat_ble_example/services/AcrDeviceConfig.dart';
import 'package:flutter_wechat_ble_example/services/R30DeviceConfig.dart';
import 'package:flutter_wechat_ble_example/services/TkbDeviceConfig.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:easy_alert/easy_alert.dart';

class DeviceList extends StatefulWidget {
  @override
  _DeviceListState createState() => _DeviceListState();
}

class InnerDeviceItem extends StatelessWidget {
  final BluetoothServiceDevice device;
  Function toggleConnect;

  InnerDeviceItem({this.device, this.toggleConnect});

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.all(10.0),
      child: new Column(
        children: <Widget>[
          new Row(
            children: <Widget>[
              new Padding(
                child: new Icon(Icons.bluetooth),
                padding: new EdgeInsets.all(10.0),
              ),
              new Expanded(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(
                      device.name,
                      style: new TextStyle(fontSize: 25.0),
                    ),
                    new Text(
                      device.deviceId,
                      style: new TextStyle(fontSize: 12.0),
                    )
                  ],
                ),
              ),
              new RaisedButton(
                onPressed: () async {
                  toggleConnect(device);
                },
                child: new Text(device.connected ? "Disconnect" : "Connect"),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _DeviceListState extends State<DeviceList> {
  String message = "Loading...";

  List<BluetoothServiceDevice> devices = [];

  @override
  void initState() {
    //启动系统
    startup();
    super.initState();
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
    bluetoothService.enableAll();
    setState(() {
      devices.addAll(bluetoothService.getDevices());
    });
    // await bluetoothService.shutdown();
    bluetoothService.onServiceDeviceFound(onServiceDeviceFound);
    bluetoothService.onServiceDeviceStateChange((dev) {
      setState(() {});
    });
    await bluetoothService.startScan();
  }

  void onServiceDeviceFound(BluetoothServiceDevice device) async {
    print("device ${device.device} ${device.name}");
    setState(() {
      this.devices.add(device);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Manage device"),
      ),
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          new Text(message),
          new Expanded(
              child: new ListView(
            children: render(context, devices),
          )),
          new RaisedButton(
            onPressed: () async {
              BluetoothService bluetoothService =
                  BluetoothService.getInstance();
              await bluetoothService.stopScan();
              for (BluetoothServiceDevice device in devices) {
                bluetoothService
                    .startupDevice(device.deviceId)
                    .then((data) async {
                  HexValue value = await device.write("000062");
                });
              }
            },
            child: new Text("Copnnect to all"),
          )
        ],
      ),
    );
  }

  List<Widget> render(
      BuildContext context, List<BluetoothServiceDevice> children) {
    return ListTile.divideTiles(
        context: context,
        tiles: children.map((BluetoothServiceDevice data) {
          return new InnerDeviceItem(
            device: data,
            toggleConnect: (BluetoothServiceDevice device) async {
              BluetoothService bluetoothService =
                  BluetoothService.getInstance();

              try {
                if (device.connected) {
                  print("start disconnect device");
                  await bluetoothService.shutdownDevice(device.deviceId);
                  print("disconnect ok");
                  setState(() {
                    message = "disconnect ok";
                  });
                } else {
                  await bluetoothService.startupDevice(device.deviceId);
                  setState(() {
                    message = "connect ok";
                  });
                  HexValue value = await device.write("000062");
                  setState(() {
                    message = "send data and receive data ${value.string}";
                  });
                }
              } on BleError catch (e) {
                setState(() {
                  message = "${e.code} ${e.message}";
                });
                print(e.code);
              } catch (e) {
                print(e);
              }
            },
          );
        })).toList();
  }
}
