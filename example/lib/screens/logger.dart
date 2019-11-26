import 'package:easy_alert/easy_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter_wechat_ble_example/services/BleModel.dart';
import 'dart:math';

class Logger extends StatefulWidget {
  final BleDevice device;
  final BleService service;
  final BleCharacteristic characteristic;

  Logger({this.device, this.service, this.characteristic});

  @override
  State<StatefulWidget> createState() {
    return new LoggerState();
  }
}

class LoggerState extends State<Logger> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    controller = new TextEditingController();
    BleModel.logger.addListener(onChange);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    BleModel.logger.removeListener(onChange);
    super.dispose();
  }

  void onChange() {
    setState(() {});
  }

  TextEditingController controller;

  String str = "";

  void writeValue(String value) async {
    try {
      BleModel.history = value;
      BleModel.logger
          .add("Write value to ${widget.characteristic.uuid}:$value");
      await BleModel.getInstance().writeValue(
          widget.device, widget.service, widget.characteristic, value);
      BleModel.logger.add("Write value success");
    } on BleError catch (e) {
      BleModel.logger..add("Write value fail ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Logger"),
        actions: <Widget>[
          new InkWell(
            child: new Center(
              child: new Padding(
                padding: new EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                child: new Text("Clear"),
              ),
            ),
            onTap: () {
              BleModel.logger.clear();
            },
          )
        ],
      ),
      body: new Column(
        children: <Widget>[
          new Row(
            children: <Widget>[
              new Expanded(
                  child: new TextField(
                autocorrect: false,
                controller: controller,
                onSubmitted: writeValue,
                onChanged: (String text) {},
              )),
              new InkWell(
                child: new Padding(
                  padding: new EdgeInsets.all(10.0),
                  child: new Text("Send"),
                ),
                onTap: () {
                  writeValue(str);
                },
              )
            ],
          ),
          new Expanded(
              child: new ListView.builder(
            itemCount: BleModel.logger.length,
            itemBuilder: (c, i) {
              return new Text(BleModel.logger.logger[i]);
            },
          )),
          new SizedBox(
            height: 200,
            child: new NumberKeyboard(
              onPress: (text) {
                if (text == 'X') {
                  if (str.length > 0) {
                    str = str.substring(0, str.length - 1);
                  }
                } else {
                  str += text;
                }

                controller.text = str;
              },
            ),
          )
        ],
      ),
    );
  }
}

typedef void NumberCallback(String number);

class NumberKey extends StatelessWidget {
  final NumberCallback onPress;
  final String text;

  NumberKey({this.text, this.onPress});

  @override
  Widget build(BuildContext context) {
    return new Expanded(
        child: new Container(
          color: Colors.white,
          child: new InkWell(
            child: new Center(
              child: new Text(
                text,
                style: new TextStyle(fontSize: 20.0),
              ),
            ),
            onTap: () {
              onPress(text);
            },
          ),
        ));
  }
}

/**
 *
 * 1 2 3 4
 * 5 6 7 8
 * 9 a b c
 * d e f 0
 * 返回 删除
 *
 */
class NumberKeyboard extends StatelessWidget {
  final NumberCallback onPress;

  NumberKeyboard({this.onPress});

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.grey,
      child: new Column(
        children: <Widget>[
          new Container(height:1),
          new Expanded(
              child: new Row(
            children: <Widget>[
              new NumberKey(
                text: "0",
                onPress: onPress,
              ),
              new NumberKey(
                text: "1",
                onPress: onPress,
              ),
              new NumberKey(
                text: "2",
                onPress: onPress,
              ),
              new NumberKey(
                text: "3",
                onPress: onPress,
              ),
            ],
          )),
          new Container(height:1),
          new Expanded(
              child: new Row(
            children: <Widget>[
              new NumberKey(
                text: "4",
                onPress: onPress,
              ),
              new NumberKey(
                text: "5",
                onPress: onPress,
              ),
              new NumberKey(
                text: "6",
                onPress: onPress,
              ),
              new NumberKey(
                text: "7",
                onPress: onPress,
              ),
            ],
          )),
          new Container(height:1),
          new Expanded(
              child: new Row(
            children: <Widget>[
              new NumberKey(
                text: "8",
                onPress: onPress,
              ),
              new NumberKey(
                text: "9",
                onPress: onPress,
              ),
              new NumberKey(
                text: "A",
                onPress: onPress,
              ),
              new NumberKey(
                text: "B",
                onPress: onPress,
              ),
            ],
          )),
          new Container(height:1),
          new Expanded(
              child: new Row(
            children: <Widget>[
              new NumberKey(
                text: "C",
                onPress: onPress,
              ),
              new NumberKey(
                text: "D",
                onPress: onPress,
              ),
              new NumberKey(
                text: "E",
                onPress: onPress,
              ),
              new NumberKey(
                text: "F",
                onPress: onPress,
              ),
            ],
          )),
          new Container(height:1),
          new Expanded(
              child: new Row(
            children: <Widget>[
              new NumberKey(
                text: "FF",
                onPress: onPress,
              ),
              new NumberKey(
                text: "00",
                onPress: onPress,
              ),
              new NumberKey(
                text: "X",
                onPress: onPress,
              ),
            ],
          )),
        ],
      ),
    );
  }
}
