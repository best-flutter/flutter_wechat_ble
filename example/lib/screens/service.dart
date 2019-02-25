import 'package:flutter/material.dart';
import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter_wechat_ble_example/screens/logger.dart';
import 'package:flutter_wechat_ble_example/services/BleModel.dart';
import 'package:flutter_wechat_ble_example/widgets/ErrorView.dart';
import 'package:flutter_wechat_ble_example/widgets/LoadingView.dart';
import 'package:easy_alert/easy_alert.dart';

class Service extends StatefulWidget {
  final BleDevice device;
  final BleService service;

  Service({this.device, this.service});

  @override
  State<StatefulWidget> createState() {
    return new ServiceState();
  }
}

class CharacteristicItemState extends State<CharacteristicItem> {
  List<Widget> buildProperties(BleCharacteristic characteristic) {
    List<Widget> list = [];
    if (characteristic.read) {
      list.add(new Text("Read"));
    }

    if (characteristic.write) {
      list.add(new Text("Write"));
    }
    if (characteristic.notify) {
      list.add(new Switch(
          value: characteristic.active,
          onChanged: (bool value) {
            try {
              BleModel.getInstance().changeNotifyState(
                  widget.device, widget.service, characteristic, value);
              characteristic.active = value;
              Alert.toast(context, "Change notify state to $value success");
              setState(() {});
            } catch (e) {
              print(e);
              Alert.toast(
                  context,
                  "Change notify state to $value fail becourse :" +
                      e.toString());
            }
          }));
    }
    if (characteristic.indicate) {
      list.add(new Text("Indicate"));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final BleCharacteristic characteristic = widget.characteristic;

    return new Padding(
      padding: new EdgeInsets.all(10.0),
      child: new Row(
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.all(10.0),
            child: new Icon(Icons.cast),
          ),
          new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Text(
                characteristic.uuid,
                style: new TextStyle(fontSize: 12.0),
              ),
              new Row(
                children: buildProperties(characteristic),
                mainAxisAlignment: MainAxisAlignment.start,
              )
            ],
          )
        ],
      ),
    );
  }
}

class CharacteristicItem extends StatefulWidget {
  final BleCharacteristic characteristic;
  final BleDevice device;
  final BleService service;

  CharacteristicItem({this.characteristic, this.device, this.service});

  @override
  State<StatefulWidget> createState() {
    return new CharacteristicItemState();
  }
}

class ServiceState extends State<Service> {
  //

  bool loading = true;
  String error;

  @override
  void initState() {
    super.initState();
    this.getCharacteristics(widget.device, widget.service);
  }

  void getCharacteristics(BleDevice device, BleService service) async {
    /// connect to the device
    try {
      loading = true;
      await BleModel.getInstance().getCharacteristics(device, service);
      setState(() {});
    } on BleError catch (e) {
      setState(() {
        error = e.message;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void getServices(BleDevice device) {
    BleModel.getInstance().getServices(device);
  }

  void openLogView(BuildContext context, BleDevice device, BleService service,
      BleCharacteristic characteristic) {
    Navigator.push(context, new MaterialPageRoute(builder: (c) {
      return new Logger(
        device: device,
        service: service,
        characteristic: characteristic,
      );
    }));
  }

  List<Widget> render(BuildContext context, List<BleCharacteristic> children) {
    if (children == null) {
      return [];
    }
    return ListTile.divideTiles(
        context: context,
        tiles: children.map((BleCharacteristic data) {
          return new InkWell(
            child: new CharacteristicItem(
              characteristic: data,
              device: widget.device,
              service: widget.service,
            ),
            onTap: () async {
              openLogView(context, widget.device, widget.service, data);
            },
          );
        })).toList();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Service " + widget.service.uuid),
      ),
      body: new ErrorView(
        message: error,
        child: new LoadingView(
            loading: loading,
            child: new ListView(
                children: render(context, widget.service.characteristics))),
      ),
    );
  }
}
