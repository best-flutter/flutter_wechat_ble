import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter_wechat_ble/bluetooth_service.dart';

class AcrDeviceConfig extends BleDeviceConfig {
  AcrDeviceConfig()
      : super(
            serviceId: "0000FFF0-0000-1000-8000-00805F9B34FB",
            notifyId: "0000FFF2-0000-1000-8000-00805F9B34FB",
            writeId: "0000FFF1-0000-1000-8000-00805F9B34FB");

  @override
  bool accept(BleDevice device) {
    return device.name.startsWith("ACR");
  }

  @override
  onStartup(BluetoothService service, BluetoothServiceDevice device) async {
    //这里需要等一下，否则容易收不到数据
    await Future.delayed(new Duration(milliseconds: 200));
    return null;
  }

  @override
  HexValue onValueChange(BluetoothServiceBleDevice device, BleValue value) {
    //如果没有完整的数据包，则返回null
    return null;
  }
}
