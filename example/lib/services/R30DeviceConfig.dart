import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter_wechat_ble/bluetooth_service.dart';

class R30DeviceConfig extends BleDeviceConfig {
  R30DeviceConfig()
      : super(
            serviceId: "49535343-FE7D-4AE5-8FA9-9FAFD205E455",
            notifyId: "49535343-1E4D-4BD9-BA61-23C647249616",
            writeId: "49535343-8841-43F4-A8D4-ECBE34729BB3");

  @override
  bool accept(BleDevice device) {
    return device.name.startsWith("R30");
  }

  @override
  void onClose(BluetoothService service, BluetoothServiceDevice device) {
    // TODO: implement onClose
  }

  @override
  void onExtraPack(BluetoothServiceDevice device, HexValue value) {
    // TODO: implement onExtraPack
  }

  @override
  onStartup(BluetoothService service, BluetoothServiceDevice device) async {
    //这里需要等一下，否则容易收不到数据

    return null;
  }

  @override
  HexValue onValueChange(BluetoothServiceBleDevice device, BleValue value) {
    print(value.value);
    //如果没有完整的数据包，则返回null
    return null;
  }
}
