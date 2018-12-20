import 'package:flutter/material.dart';
import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter_wechat_ble_example/screens/service.dart';
import 'package:flutter_wechat_ble_example/services/BleModel.dart';
import 'package:flutter_wechat_ble_example/widgets/ErrorView.dart';
import 'package:flutter_wechat_ble_example/widgets/LoadingView.dart';

class Device extends StatefulWidget {
  final BleDevice device;

  Device({this.device});

  @override
  State<StatefulWidget> createState() {
    return new DeviceState();
  }
}

class ServiceItem extends StatelessWidget {
  final BleService service;

  ServiceItem({this.service});

  @override
  Widget build(BuildContext context) {
    return new ListTile(
      leading: new Icon(Icons.group_work),
      title: new Text(service.uuid),
      subtitle: new Text(service.isPrimary ? "Primary service" : ""),
    );
  }
}

class DeviceState extends State<Device> {
  //

  bool loading = true;
  String error;

  @override
  void initState() {
    super.initState();
    this.connectToTheDevice(widget.device);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void connectToTheDevice(BleDevice device) async {
    /// connect to the device
    try {
      loading = true;
      await BleModel.getInstance().connect(device);
      await this.getServices(device);
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

  void getServices(BleDevice device) async {
    List<BleService> servcies =
        await BleModel.getInstance().getServices(device);
  }

  void openDeviceView(BuildContext context, BleService service) {
    Navigator.push(context,
        new MaterialPageRoute(builder: (BuildContext context) {
      return new Service(
        device: widget.device,
        service: service,
      );
    }));
  }

  List<Widget> render(BuildContext context, List<BleService> children) {
    if (children == null) {
      return [];
    }
    return ListTile.divideTiles(
        context: context,
        tiles: children.map((BleService data) {
          return new InkWell(
            child: new ServiceItem(
              service: data,
            ),
            onTap: () async {
              openDeviceView(context, data);
            },
          );
        })).toList();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Device " + widget.device.name),
      ),
      body: new ErrorView(
        message: error,
        child: new LoadingView(
            loading: loading,
            child: new ListView(
                children: render(context, widget.device.services))),
      ),
    );
  }
}
