import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'dart:async';
import 'dart:math';

typedef void OnServiceDeviceStateChangeCallback(BluetoothServiceDevice device);
typedef void OnServiceDeviceFoundCallback(BluetoothServiceDevice device);

const int kDataTimeout = 500;
const int kConnectTimeout = 10;
const int kConnectRetryInterval = 500;
const int kConnectRetryCount = 1;
const int kMaxConnectRetryCount = 10;

abstract class BleDeviceConfig extends DeviceConfig {
  //the default service id want to communicate
  final String serviceId;

  //the default notify characteristics id
  // 设置之后，将会自动将本id对应的特征值设置通知模式
  final String notifyId;

  //the default write characteristics id
  final String writeId;

  BleDeviceConfig(
      {this.serviceId,
      this.notifyId,
      this.writeId,
      bool checkServicesAndCharacteristics = false,
      bool enable = true,
      String tag,
      Duration connectTimeout = const Duration(seconds: kConnectTimeout),
      Duration dataTimeout = const Duration(milliseconds: kDataTimeout),
      Duration connectRetryInterval =
          const Duration(milliseconds: kConnectRetryInterval),
      int connectRetryCount = kConnectRetryCount})
      : super(
            tag: tag,
            checkServicesAndCharacteristics: checkServicesAndCharacteristics,
            connectTimeout: connectTimeout,
            dataTimeout: dataTimeout,
            enable: enable,
            connectRetryInterval: connectRetryInterval,
            connectRetryCount: connectRetryCount);

  @override
  BluetoothServiceDevice createBleServiceDevice(
      BluetoothService service, BleDevice device, DeviceConfig config) {
    return service.createBleDevice(device, config);
  }
}

abstract class DeviceConfig {
  ///
  final bool checkServicesAndCharacteristics;

  // tag to id the device
  final String tag;

  // time out of send data and receive data
  final Duration dataTimeout;

  // time out of connect to device
  final Duration connectTimeout;

  final Duration connectRetryInterval;

  final int connectRetryCount;

  bool enable;

  DeviceConfig(
      {this.checkServicesAndCharacteristics,
      this.connectTimeout,
      this.dataTimeout,
      this.connectRetryCount,
      this.connectRetryInterval,
      this.enable,
      this.tag});

  // is the device acceptable?
  bool accept(BleDevice device);
  // this function will be called when  not in ask and answer mode
  void onExtraPack(BluetoothServiceBleDevice device, HexValue value) {}

  /// handle the package logic
  HexValue onValueChange(BluetoothServiceBleDevice device, BleValue value);

  // create the service device
  BluetoothServiceDevice createBleServiceDevice(
      BluetoothService service, BleDevice device, DeviceConfig config);

  dynamic onStartup(BluetoothService service, BluetoothServiceDevice device) {}

  // called when the device is closed and released
  void onClose(BluetoothService service, BluetoothServiceDevice device) {}
}

///
abstract class BluetoothServiceDevice {
  final BleDevice device;

  //the device config
  final DeviceConfig config;

  // this value will be changed when connection state changed
  bool connected;

  BluetoothServiceDevice({this.device, this.config, this.connected = false});

  void onReceiveData(BleValue value);

  // connect tot the device and do other prepare work
  dynamic startup();

  String get deviceId => device.deviceId;
  String get name => device.name;

  Future close();

  //
  Future<HexValue> write(var value);

  //
  Future writeWithoutReturnData(var value);
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
          config.onExtraPack(this, result);
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

  _connectDevice() async {
    await FlutterWechatBle.createBLEConnection(deviceId: deviceId);
  }

  /// startup the device
  /// we just do some work for prepare the device
  ///
  @override
  dynamic startup() async {
    // open connection
    await _connectDevice();

    // get services
    List<BleService> services =
        await FlutterWechatBle.getBLEDeviceServices(deviceId: deviceId);
    for (BleService service in services) {
      List<BleCharacteristic> characterisrics =
          await FlutterWechatBle.getBLEDeviceCharacteristics(
              deviceId: deviceId, serviceId: service.uuid);
    }

    if (_config.checkServicesAndCharacteristics) {
      bool serviceOk = false;
      bool writeOk = false;
      bool notifyOk = false;
      for (BleService service in services) {
        if (service.uuid == _config.serviceId) {
          serviceOk = true;
          for (BleCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid == _config.writeId &&
                characteristic.write) {
              writeOk = true;
            }
            if (characteristic.uuid == _config.notifyId &&
                characteristic.notify) {
              notifyOk = true;
            }
          }
          break;
        }
      }

      if (!serviceOk) {
        throw new AssertionError(
            "Cannot find service by serviceId ${_config.serviceId}");
      }

      if (!writeOk) {
        throw new AssertionError(
            "Cannot find write characteristic by writeId ${_config.writeId}");
      }

      if (!notifyOk) {
        throw new AssertionError(
            "Cannot find notify characteristic by notifyId ${_config.notifyId}");
      }
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

  @override
  Future writeWithoutReturnData(value) {
    return writeValue(_config.serviceId, _config.writeId, value);
  }
}

class BluetoothService {
  List<DeviceConfig> _configs;
  Map<String, BluetoothServiceDevice> _serviceDevices = {};

  static BluetoothService _instance;

  static BluetoothService getInstance() {
    return _instance;
  }

  static BluetoothService createInstance(List<DeviceConfig> configs) {
    _instance = new BluetoothService._(configs: configs);
    return _instance;
  }

  BluetoothService._({
    List<DeviceConfig> configs,
  }) : this._configs = configs;

  void setConfigs(List<DeviceConfig> configs) {
    this._configs = configs;
  }

  Iterable<BluetoothServiceDevice> getDevices() {
    return _serviceDevices.values;
  }

  Iterable<BluetoothServiceDevice> getConnectedDevices() {
    return _serviceDevices.values
        .where((BluetoothServiceDevice device) => device.connected);
  }

  // 通过配置的下标后者标志(tag)来控制是否启用
  void setEnable({int index, bool enable: true, String tag}) {
    if (index != null) {
      if (index < 0 || index >= _configs.length) {
        throw new AssertionError("index is not correct");
      }
      _configs[index].enable = enable;
    } else if (tag != null) {
      _configs.firstWhere((DeviceConfig config) => tag == config.tag);
    } else {
      throw new AssertionError("A index or tag must be given");
    }
  }

  BluetoothServiceDevice createBleDevice(
      BleDevice device, DeviceConfig config) {
    return new BluetoothServiceBleDevice(device: device, config: config);
  }

  Future startScan() async {
    await FlutterWechatBle.openBluetoothAdapter();
    FlutterWechatBle.onBluetoothDeviceFound(_onRowDeviceFound);
    FlutterWechatBle.onBLEConnectionStateChange(_onBLEConnectionStateChange);
    FlutterWechatBle.onBLECharacteristicValueChange(
        _onBLECharacteristicValueChange);
    await FlutterWechatBle.startBluetoothDevicesDiscovery();
  }

  void _onBLEConnectionStateChange(String deviceId, bool connected) {
    BluetoothServiceDevice device = getDeviceById(deviceId);
    if (device == null) {
      throw new AssertionError("Cannot find device :$deviceId");
    }
    device.connected = connected;
    if (_onServiceDeviceStateChangeCallback != null) {
      _onServiceDeviceStateChangeCallback(device);
    }
  }

  void stopScan() async {
    await FlutterWechatBle.stopBluetoothDevicesDiscovery();
  }

  OnServiceDeviceFoundCallback _onServiceDeviceFoundCallback;
  OnServiceDeviceStateChangeCallback _onServiceDeviceStateChangeCallback;

  void onServiceDeviceFound(OnServiceDeviceFoundCallback callback) {
    _onServiceDeviceFoundCallback = callback;
  }

  void onServiceDeviceStateChange(OnServiceDeviceStateChangeCallback callback) {
    _onServiceDeviceStateChangeCallback = callback;
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

  /// startup device
  dynamic startupDevice(String deviceId) async {
    BluetoothServiceDevice serviceDevice = getDeviceById(deviceId);
    if (serviceDevice == null) {
      throw new AssertionError("Cannot find device by id :${deviceId}");
    }
    await serviceDevice.startup();
    serviceDevice.connected = true;
    return await serviceDevice.config.onStartup(this, serviceDevice);
  }

  void _onRowDeviceFound(BleDevice device) {
    for (DeviceConfig config in _configs) {
      if (config.enable && config.accept(device)) {
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
    } catch (e) {} finally {
      serviceDevice.connected = false;
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
