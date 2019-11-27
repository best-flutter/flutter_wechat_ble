import 'package:flutter/material.dart';
import 'package:flutter_wechat_ble_example/screens/ble_helper.dart';
import 'package:flutter_wechat_ble_example/screens/connect_to_tkb.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new ListView(
        children: <Widget>[
          new InkWell(
            child: new Padding(
              padding: new EdgeInsets.all(10.0),
              child: new Text("Ble helper"),
            ),
            onTap: () {
              Navigator.push(context,
                  new MaterialPageRoute(builder: (BuildContext context) {
                return new BleHelper();
              }));
            },
          ),
          new InkWell(
            child: new Padding(
              padding: new EdgeInsets.all(10.0),
              child: new Text("Connect to TKB_BLE"),
            ),
            onTap: () {
              Navigator.push(context,
                  new MaterialPageRoute(builder: (BuildContext context) {
                return new ConnectToTkb();
              }));
            },
          ),
        ],
      ),
    );
  }
}
