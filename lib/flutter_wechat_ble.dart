import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_wechat_ble/utils.dart';

/**
 * #define NOT_INIT @"10000"
    #define NOT_AVALIABLE @"10001"
    #define NO_DEVICE @"10002"
    #define CONNECTION_FAIL @"10003"
    #define NO_SERVICE @"10004"
    #define NO_CHARACTERISTIC @"10005"
    #define NO_CONNECTION @"10006"
    #define PROPERTY_NOT_SUPPOTT @"10007"
    #define SYSTEM_ERROR @"10008"
    #define SYSTEM_NOT_SUPPORT @"10009"
 */
class BleError extends Error {
  String code;

  BleError({this.code});

  String get message {
    switch (code) {
      case "10000":
        return "openBluetoothAdapter not called yet!";
      case "10001":
        return "Bluetooth is not opened!";
      case "10002":
        return "Cannot find device id ";
      case "10003":
        return "Connection fail";
      case "10004":
        return "Cannot find service";
      case "10005":
        return "CHARACTERISTIC  not found";
      case "10006":
        return "No connection found";
      case "10007":
        return "Property not support";
      case "10008":
        return "System error!";
    }
  }
}

class BleDevice {

  /// uuid of the device
  final String deviceId;

  /// device name
  final String name;

  /// RSSI
  final String RSSI;

  List<BleService> services;

  BleDevice({this.deviceId, this.name, this.RSSI});

  void setServices(List<BleService> services) {
    this.services = services;
  }

  BleService getService(String serviceId) {
    return services
        ?.firstWhere((BleService service) => serviceId == service.uuid);
  }
}

class BleService {

  /// uuid of the service
  final String uuid;

  /// always true in android and the `isPrimary` field of the class `CBService` in ios
  final bool isPrimary;

  List<BleCharacteristic> characteristics;

  BleService({this.uuid, this.isPrimary});

  void setCharacteristic(List<BleCharacteristic> characteristics) {
    this.characteristics = characteristics;
  }

  BleCharacteristic getCharacteristic(String characteristicId) {
    return characteristics?.firstWhere((BleCharacteristic characteristic) =>
    characteristicId == characteristic.uuid);
  }
}

class BleValue {
  BleValue({this.deviceId, this.serviceId, this.characteristicId, this.value});

  factory BleValue.fromMap(data){
    String deviceId = data['deviceId'];
    String serviceId = data['serviceId'];
    String characteristicId = data['characteristicId'];
    String value = data['value'];
    BleValue bleValue = new BleValue(
        deviceId: deviceId,
        serviceId: serviceId,
        characteristicId: characteristicId,
        value: value);
    return bleValue;
  }

  final String deviceId;
  final String serviceId;
  final String characteristicId;
  final String value;

  List<int> _bytes;

  List<int> get bytes {
    if (_bytes == null) {
      if (value == null) {
        return null;
      }
      _bytes = Utils.decodeHex(value);
    }
    return _bytes;
  }

  @override
  String toString() {
    return value;
  }
}

class BleCharacteristic {

  /// uuid of the characteristic
  final String uuid;

  /// support read
  final bool read;

  /// support write
  final bool write;

  /// support notify
  final bool notify;

  /// support indicate
  final bool indicate;

  // this property is valid only if notify = true
  bool active = false;

  BleCharacteristic(
      {this.uuid, this.read, this.write, this.notify, this.indicate});
}

typedef void FoundDeviceCallback(BleDevice device);
typedef void ValueChangeCallback(BleValue value);
typedef void ConnectionStateChangeCallback(String deviceId,bool connected);

class FlutterWechatBle {
  static const String code = "code";
  static const MethodChannel _channel =
  const MethodChannel('flutter_wechat_ble');

  static bool allowDuplicatesKey;

  static List<String> services;

  static int interval;
  // static StreamController<BleDevice> _foundDeviceController = new StreamController.broadcast();

  /// we must make sure, same deviceId is not dup
  static Map<String, BleDevice> _devices = new Map();

  static Map<String,BleDevice> _connectedDevices = new Map();

  static FoundDeviceCallback _onBluetoothDeviceFoundCallback;

  static Future handler(MethodCall call) {
    String name = call.method;
    var data = call.arguments;
    switch (name) {
      case "foundDevice":
        {
          String deviceId = data['deviceId'];
          _devices.update(deviceId, (BleDevice oldDevice) {
            if (allowDuplicatesKey) {
              if (_onBluetoothDeviceFoundCallback != null) {
                _onBluetoothDeviceFoundCallback(oldDevice);
              }
            }
            /// update the RSSI

            return oldDevice;
          }, ifAbsent: () {
            BleDevice device = new BleDevice(name: data['name'], deviceId: data['deviceId']);
            if (_onBluetoothDeviceFoundCallback != null) {
              _onBluetoothDeviceFoundCallback(device);
            }
            return device;
          });
        }
        break;
      case "valueUpdate":
        {
          if (_valueChangeCallback != null) {
            _valueChangeCallback(BleValue.fromMap(data));
          }
        }
        break;
      case "stateChange":
        {
          if(_connectionStateChangeCallback!=null){
            _connectionStateChangeCallback(data['deviceId'],data['connected']);
          }
        }
        break;
    }
  }

  static Future openBluetoothAdapter() async {
    _channel.setMethodCallHandler(handler);
    var result = await _channel.invokeMethod('openBluetoothAdapter');
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }

  static Future closeBluetoothAdapter() async {
    var result = await _channel.invokeMethod('closeBluetoothAdapter', {});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    _connectedDevices.clear();
    _devices.clear();
    return result;
  }

  static Future startBluetoothDevicesDiscovery(
      {bool allowDuplicatesKey = false,
        List<String> services = const <String>[],
        int interval = 0}) async {
    FlutterWechatBle.allowDuplicatesKey = allowDuplicatesKey;
    FlutterWechatBle.services = services;
    FlutterWechatBle.interval = interval;
    var result = await _channel.invokeMethod('startBluetoothDevicesDiscovery', {});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }

  static Future stopBluetoothDevicesDiscovery() async {
    var result = await _channel.invokeMethod('stopBluetoothDevicesDiscovery', {});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }

  static Future createBLEConnection({String deviceId}) async {
    var result = await _channel
        .invokeMethod('createBLEConnection', {"deviceId": deviceId});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    _connectedDevices[deviceId] = _devices[deviceId];
    return result;
  }

  static Future closeBLEConnection({String deviceId}) async {
    assert(deviceId != null);
    _connectedDevices.remove(deviceId);
    var result = await _channel
        .invokeMethod('closeBLEConnection', {"deviceId": deviceId});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }

    return result;
  }

  static Future<List<BleDevice>> getBluetoothDevices() async {
    return _devices.values.toList();
  }

  static Future<List<BleDevice>> getConnectedBluetoothDevices() async {
    return _connectedDevices.values.toList();
  }

  static ValueChangeCallback _valueChangeCallback;

  static ConnectionStateChangeCallback _connectionStateChangeCallback;

  static void onBLECharacteristicValueChange(ValueChangeCallback callback) {
    _valueChangeCallback = callback;
  }

  static void onBLEConnectionStateChange(ConnectionStateChangeCallback callback){
    _connectionStateChangeCallback = callback;
  }

  static Future<List<BleService>> getBLEDeviceServices(
      {String deviceId}) async {
    assert(deviceId != null);
    /// we just get services from cache
    var result = await _channel.invokeMethod('getBLEDeviceServices', {"deviceId": deviceId});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }

    List rawServices = result['services'];
    //services
    List<BleService> services = rawServices
        .map((data) =>
    new BleService(uuid: data['uuid'], isPrimary: data['isPrimary']))
        .toList();

    return services;
  }

  static void onBluetoothDeviceFound(FoundDeviceCallback callback) {
    FlutterWechatBle._onBluetoothDeviceFoundCallback = callback;
  }

  static Future<List<BleCharacteristic>> getBLEDeviceCharacteristics(
      {String deviceId,String serviceId}) async {


    var result = await _channel.invokeMethod('getBLEDeviceCharacteristics',
        {"deviceId": deviceId, "serviceId": serviceId});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }

    List rawData = result['characteristics'];
    //services
    List<BleCharacteristic> characteristics = rawData
        .map((data) => new BleCharacteristic(
      uuid: data['uuid'],
      read: data['read'],
      write: data['write'],
      notify: data['notify'],
      indicate: data['indicate'],
    ))
        .toList();

    return characteristics;
  }

  static Future<BleValue> readBLECharacteristicValue({
    String deviceId,
    String serviceId,
    String characteristicId,
  }) async {
    assert(deviceId!=null);
    assert(serviceId!=null);
    assert(characteristicId!=null);
    var result = await _channel.invokeMethod('readBLECharacteristicValue',{
    "deviceId": deviceId,
    "serviceId": serviceId,
    "characteristicId": characteristicId,
    });
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return new BleValue.fromMap(result);
  }

  static Future writeBLECharacteristicValue(
      {String deviceId,
        String serviceId,
        String characteristicId,

        /// string or List<int>
        dynamic value}) async {
    assert(value!=null);
    assert(deviceId!=null);
    assert(serviceId!=null);
    assert(characteristicId!=null);
    if(value is List<int>){
      value = Utils.encodeHex(value);
    }else if(!(value is String)){
      throw new Exception("value must be List<int> or String of hex");
    }
    var result = await _channel.invokeMethod('writeBLECharacteristicValue', {
      "deviceId": deviceId,
      "serviceId": serviceId,
      "characteristicId": characteristicId,
      "value": value
    });
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }

  static Future notifyBLECharacteristicValueChange(
      {String deviceId,
        String serviceId,
        String characteristicId,
        bool state}) async {
    assert(deviceId!=null);
    assert(serviceId!=null);
    assert(characteristicId!=null);
    assert(state!=null);
    var result =
    await _channel.invokeMethod('notifyBLECharacteristicValueChange', {
      "deviceId": deviceId,
      "serviceId": serviceId,
      "characteristicId": characteristicId,
      "state": state
    });
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }
}
