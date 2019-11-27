import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'dart:async';

abstract class BleDeviceConfig extends DeviceConfig {
  //the default service id want to communicate
  final String serviceId;

  //the default notify characteristics id
  final String notifyId;

  //the default write characteristics id
  final String writeId;

  BleDeviceConfig(
      {this.serviceId,
      this.notifyId,
      this.writeId,
      bool checkServicesAndCharacteristics = true,
      Duration connectTimeout = const Duration(seconds: 10),
      Duration dataTimeout = const Duration(milliseconds: 200)})
      : super(
            checkServicesAndCharacteristics: checkServicesAndCharacteristics,
            connectTimeout: connectTimeout,
            dataTimeout: dataTimeout);

  @override
  BluetoothServiceDevice createBleServiceDevice(
      BluetoothService service, BleDevice device, DeviceConfig config) {
    return service.createBleDevice(device, config);
  }
}

abstract class DeviceConfig {
  ///
  final bool checkServicesAndCharacteristics;

  // time out of send data and receive data
  final Duration dataTimeout;

  /// time out of connect to device
  final Duration connectTimeout;

  DeviceConfig(
      {this.checkServicesAndCharacteristics = true,
      this.connectTimeout = const Duration(seconds: 10),
      this.dataTimeout = const Duration(milliseconds: 200)});

  // is the device acceptable?
  bool accept(BleDevice device);
  // this function will be called when  not in ask and answer mode
  void onExtraPack(HexValue value);

  /// handle the package logic
  HexValue onValueChange(BluetoothServiceBleDevice device, BleValue value);

  // create the service device
  BluetoothServiceDevice createBleServiceDevice(
      BluetoothService service, BleDevice device, DeviceConfig config);

  dynamic onStartup(BluetoothService service, BluetoothServiceDevice device);

  // called when the device is closed and released
  void onClose(BluetoothService service, BluetoothServiceDevice device);
}

///
abstract class BluetoothServiceDevice {
  final BleDevice device;
  final DeviceConfig config;

  BluetoothServiceDevice({this.device, this.config});

  void onReceiveData(BleValue value);

  dynamic startup();

  String get deviceId => device.deviceId;
  String get name => device.name;

  Future close();

  Future<HexValue> write(var value);
}

abstract class HexValue {
  String get string;
  List<int> get bytes;
}

class StringHexValue extends HexValue {
  final String _string;
  List<int> _bytes;

  StringHexValue(String string) : _string = string;

  @override
  List<int> get bytes {
    if (_bytes == null) {
      _bytes = HexUtils.decodeHex(_string);
    }
    return _bytes;
  }

  @override
  String get string => _string;
}

class BytesHexValue extends HexValue {
  final List<int> _value;
  String _string;

  BytesHexValue(List<int> value) : _value = value;

  @override
  List<int> get bytes => _value;

  @override
  String get string {
    if (_string == null) {
      _string = HexUtils.encodeHex(_value);
    }
    return _string;
  }
}

class DeviceBuffer {
  List<int> buffer = [];

  DeviceBuffer();

  void appendValue(value) {
    if (value is String) {
      buffer.addAll(HexUtils.decodeHex(value));
    } else if (value is List<int>) {
      buffer.addAll(value);
    } else {
      throw new AssertionError("Value must be String or List<int>");
    }
  }

  HexValue getValue() {
    return new BytesHexValue(buffer);
  }

  HexValue copyValue() {
    return new BytesHexValue(new List<int>()..addAll(buffer));
  }

  void clear() {
    buffer.clear();
  }
}

class BluetoothServiceBleDevice extends BluetoothServiceDevice {
  final DeviceBuffer _buffer = new DeviceBuffer();

  // user define value
  dynamic tag;

  // user define value
  int packageCount;

  final BleDeviceConfig _config;

  BluetoothServiceBleDevice({BleDevice device, BleDeviceConfig config})
      : _config = config,
        super(device: device, config: config);

  // value is string or List<int>
  void appendValue(var value) {
    _buffer.appendValue(value);
  }

  HexValue getValue() {
    return _buffer.getValue();
  }

  HexValue getValueAndClear() {
    HexValue value = getValue();
    clearBuffer();
    return value;
  }

  HexValue copyValue() {
    return _buffer.copyValue();
  }

  void clearBuffer() {
    _buffer.clear();
  }

  @override
  void onReceiveData(BleValue value) async {
    try {
      print("receive data : ${value.value}");
      HexValue result = await config.onValueChange(this, value);
      if (result != null) {
        if (_completer != null) {
          //report the data
          Completer<HexValue> completer = this._completer;
          this._completer = null;
          completer.complete(result);
        } else {
          //extra data
          config.onExtraPack(result);
        }
      }
    } catch (e) {
      if (_completer != null) {
        Completer<HexValue> completer = this._completer;
        this._completer = null;
        completer.completeError(e);
      }
    }
  }

  /// startup the device
  /// we just do some work for prepare the device
  ///
  @override
  dynamic startup() async {
    // open connection
    await FlutterWechatBle.createBLEConnection(deviceId: deviceId);
    // get services
    List<BleService> services =
        await FlutterWechatBle.getBLEDeviceServices(deviceId: deviceId);
    for (BleService service in services) {
      List<BleCharacteristic> characterisrics =
          await FlutterWechatBle.getBLEDeviceCharacteristics(
              deviceId: deviceId, serviceId: service.uuid);
    }

    await setNotify(
        serviceId: _config.serviceId, characteristicId: _config.notifyId);
  }

  // close the device
  Future close() async {
    try {
      //call the onDataTimeout in order to avoid memory leak
      await _onDataTimeout();
    } catch (e) {
      //do not handle the onDataTimeout callback error
    }

    this.clearBuffer();
    await FlutterWechatBle.closeBLEConnection(deviceId: deviceId);
  }

  void setNotify(
      {String serviceId, String characteristicId, bool state = true}) async {
    await FlutterWechatBle.notifyBLECharacteristicValueChange(
        deviceId: deviceId,
        serviceId: serviceId,
        characteristicId: characteristicId,
        state: true);
  }

  Future writeValue(String serviceId, String characteristicId, var value) {
    return FlutterWechatBle.writeBLECharacteristicValue(
        deviceId: deviceId,
        serviceId: _config.serviceId,
        characteristicId: _config.writeId,
        value: value);
  }

  // waiting for receive a whole package
  Completer<HexValue> _completer;
  Timer _timer;
  // write the value to the devices the value must be a whole package
  // we handle the package logic in DeviceConfig {@see DeviceConfig}
  Future<HexValue> write(var value) {
    if (_completer != null) {
      throw new AssertionError(
          "Cannot send another data when data is not completed");
    }
    _completer = new Completer<HexValue>();
    _timer = new Timer(_config.dataTimeout, _onDataTimeout);
    _completer.future;
    writeValue(_config.serviceId, _config.writeId, value);
    return _completer.future;
  }

  _onSuccess(HexValue value) {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    return value;
  }

  void _onDataTimeout() {
    if (_completer != null) {
      Completer<HexValue> completer = this._completer;
      this._completer = null;
      completer.completeError(new TimeoutException("Data timeout"));
    }

    _timer = null;
  }
}

typedef void OnServiceDeviceFoundCallback(BluetoothServiceDevice device);

class BluetoothService {
  final List<DeviceConfig> _configs;
  Map<String, BluetoothServiceDevice> _serviceDevices = {};

  BluetoothService({
    List<DeviceConfig> configs,
  }) : this._configs = configs;

  BluetoothServiceDevice createBleDevice(
      BleDevice device, DeviceConfig config) {
    return new BluetoothServiceBleDevice(device: device, config: config);
  }

  Future startScan() async {
    await FlutterWechatBle.openBluetoothAdapter();
    await FlutterWechatBle.startBluetoothDevicesDiscovery();
    FlutterWechatBle.onBluetoothDeviceFound(_onRowDeviceFound);
    FlutterWechatBle.onBLECharacteristicValueChange(
        _onBLECharacteristicValueChange);
  }

  void stopScan() async {
    await FlutterWechatBle.stopBluetoothDevicesDiscovery();
  }

  OnServiceDeviceFoundCallback _onServiceDeviceFoundCallback;

  void onServiceDeviceFound(OnServiceDeviceFoundCallback callback) {
    _onServiceDeviceFoundCallback = callback;
  }

  void _onBLECharacteristicValueChange(BleValue value) {
    BluetoothServiceDevice device = getDeviceById(value.deviceId);
    if (device == null) {
      throw new AssertionError(
          "Cannot find device ${value.deviceId} when receiving data");
    }
    device.onReceiveData(value);
  }

  BluetoothServiceDevice getDeviceById(String deviceId) {
    return _serviceDevices[deviceId];
  }

  dynamic startupDevice(String deviceId) async {
    BluetoothServiceDevice serviceDevice = getDeviceById(deviceId);
    if (serviceDevice == null) {
      throw new AssertionError("Cannot find device by id :${deviceId}");
    }
    await serviceDevice.startup();
    return await serviceDevice.config.onStartup(this, serviceDevice);
  }

  void _onRowDeviceFound(BleDevice device) {
    for (DeviceConfig config in _configs) {
      if (config.accept(device)) {
        BluetoothServiceDevice serviceDevice =
            config.createBleServiceDevice(this, device, config);
        this._serviceDevices[device.deviceId] = serviceDevice;
        if (_onServiceDeviceFoundCallback != null) {
          _onServiceDeviceFoundCallback(serviceDevice);
        }

        break;
      }
    }
  }

  void shutdownDevice(String deviceId) async {
    BluetoothServiceDevice serviceDevice = getDeviceById(deviceId);
    if (serviceDevice == null) {
      throw new AssertionError("Cannot find device by id :${deviceId}");
    }

    try {
      await serviceDevice.close();
    } catch (e) {
      await serviceDevice.close();
    } finally {
      await serviceDevice.config.onClose(this, serviceDevice);
    }
  }

  Future shutdown() async {
    for (BluetoothServiceDevice serviceDevice in _serviceDevices.values) {
      try {
        await serviceDevice.close();
      } catch (e) {
        //do not handle error when close the device
      } finally {
        await serviceDevice.config.onClose(this, serviceDevice);
      }
    }

    try {
      await FlutterWechatBle.stopBluetoothDevicesDiscovery();
      await FlutterWechatBle.closeBluetoothAdapter();
    } catch (e) {
      //do not handle error when close the device
    } finally {
      // remove all the cached devices
      this._serviceDevices.clear();
    }
  }
}
