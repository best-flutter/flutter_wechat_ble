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
  void onClose(BluetoothService service, BluetoothServiceDevice device) {
    // TODO: implement onClose
  }

  @override
  void onExtraPack(HexValue value) {
    // TODO: implement onExtraPack
  }

  @override
  onStartup(BluetoothService service, BluetoothServiceDevice device) async {
    //这里需要等一下，否则容易收不到数据
    await Future.delayed(new Duration(milliseconds: 200));
    return null;
  }

  @override
  HexValue onValueChange(BluetoothServiceBleDevice device, BleValue value) {
    List<int> bytes = value.bytes;
    int firstByte = bytes[0];

    //头一个字节如果是0xc的话，那么表示是后续序列，否则为第一个序列
    if ((firstByte & 0xc0) == 0xc0) {
      //后续序列
      device.appendValue(value.value.substring(2));

      device.packageCount--;
      if (device.packageCount == 0) {
        //这里已经获取到了完整的数据包，所以返回了
        return device.getValueAndClear();
      }
    } else {
      //第一个序列
      int len = firstByte & 0x3f;
      if (len == 0) {
        //如果后续序列是0个数量，则这里返回完整的数据包s
        return new StringHexValue(value.value.substring(2));
      }

      //第一个序列的有效数据包增加到设备缓存里面
      device.appendValue(value.value.substring(2));
      //剩余的序列数量
      device.packageCount = len;
    }

    //如果没有完整的数据包，则返回null
    return null;
  }
}
