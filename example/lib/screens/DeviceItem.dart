import 'package:easy_alert/easy_alert.dart';
import 'package:flutter/material.dart';

import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter_wechat_ble_example/screens/device.dart';
import 'package:flutter_wechat_ble_example/services/BleModel.dart';
import 'package:flutter_wechat_ble_example/widgets/ErrorView.dart';
import 'package:flutter_wechat_ble_example/widgets/LoadingView.dart';


class DeviceItem extends StatelessWidget {
  final BleDevice device;

  DeviceItem({this.device});

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
              new Column(
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
              )
            ],
          )
        ],
      ),
    );
  }
}