import 'package:easy_alert/easy_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter_wechat_ble_example/services/BleModel.dart';

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
              new Expanded(child: new TextField(
                autocorrect: false,
                controller: controller,
                onSubmitted: writeValue,
              )),
              new InkWell(
                child: new Padding(padding: new EdgeInsets.all(10.0),child: new Text("Send"),),
                onTap: (){
                  writeValue(controller.text);
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
          ))
        ],
      ),
    );
  }
}
