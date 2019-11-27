import 'package:easy_alert/easy_alert.dart';
import 'package:flutter/material.dart';

import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter_wechat_ble_example/screens/DeviceItem.dart';
import 'package:flutter_wechat_ble_example/screens/device.dart';
import 'package:flutter_wechat_ble_example/services/BleModel.dart';
import 'package:flutter_wechat_ble_example/widgets/ErrorView.dart';
import 'package:flutter_wechat_ble_example/widgets/LoadingView.dart';

class BleHelper extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new BleHelperState();
  }
}


class BleHelperState extends State<BleHelper> {
  List<BleDevice> data = [];

  void openDeviceView(BuildContext context, BleDevice data) async {
    try {
      //stop discovery first
      BleModel.getInstance().stopScan();

      await Navigator.push(context, new MaterialPageRoute(builder: (c) {
        return new Device(
          device: data,
        );
      }));
    } finally {
//      try {
//        await BleModel.getInstance().close(data);
//      } catch (e) {}
//
//      await BleModel.getInstance().shutdown();
//
//      await this.startup();
    }
  }

  List<Widget> render(BuildContext context, List<BleDevice> children) {
    return ListTile.divideTiles(
        context: context,
        tiles: children.map((BleDevice data) {
          return new InkWell(
            child: new DeviceItem(
              device: data,
            ),
            onTap: () async {
              openDeviceView(context, data);
            },
          );
        })).toList();
  }

  void foundDeviceCallback(BleDevice device) {
    setState(() {
      loading = false;
    });
    print("Found device : " + device.name);
    setState(() {
      data.add(device);
    });
  }

  bool loading = true;
  String error;

  @override
  void initState() {
    this.startup();
    super.initState();
  }

  void valueChangeCallback(BleValue value) {
    //LoggerModel.getInstance().add(value);

    BleModel.logger.add("Value changed: $value");
  }

  void startup() async {
    setState(() {
      data.clear();
      loading = true;
    });

    try {
      BleModel.getInstance()
          .onConnectionStateChange((String deviceId, bool connected) {
        Alert.toast(context, "Device $deviceId state change to $connected");
      });
      await BleModel.getInstance().shutdown();
      await BleModel.getInstance().startup(foundDeviceCallback);
      BleModel.getInstance().listenValueChanged(valueChangeCallback);
    } on BleError catch (e) {
      setState(() {
        error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Bluetooth Helper'),
          actions: <Widget>[
            new IconButton(
                icon: new Icon(Icons.refresh),
                onPressed: () {
                  startup();
                })
          ],
        ),
        body: new ErrorView(
          message: error,
          child: new LoadingView(
            child: new ListView(children: render(context, data)),
            loading: loading,
          ),
        ));
  }
}
