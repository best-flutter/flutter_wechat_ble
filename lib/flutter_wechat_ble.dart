import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

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
    switch(code){
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
  final String deviceId;
  final String name;
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
  final String uuid;
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

class BleCharacteristic {
  final String uuid;
  final bool read;
  final bool write;
  final bool notify;
  final bool indicate;

  // this property is valid only if notify = true
  bool active = false;

  BleCharacteristic(
      {this.uuid, this.read, this.write, this.notify, this.indicate});
}

@immutable
class DiscoveryOptions {
  final bool allowDuplicatesKey;
  final List<String> services;
  final int interval;
  final FoundDeviceCallback success;

  const DiscoveryOptions(
      {this.allowDuplicatesKey: false,
      this.services: const <String>[],
      this.interval: 0,
      this.success});
}

typedef void FoundDeviceCallback(BleDevice device);
typedef void ValueChangeCallback(BleDevice device, BleService service,
    BleCharacteristic characteristic, String value);



class FlutterWechatBle {
  static const String code = "code";
  static const MethodChannel _channel =
      const MethodChannel('flutter_wechat_ble');

  // static StreamController<BleDevice> _foundDeviceController = new StreamController.broadcast();

  static DiscoveryOptions _discoveryOptions;

  /// we must make sure, same deviceId is not dup
  static Map<String, BleDevice> _devices = new Map();

  static Future handler(MethodCall call) {
    String name = call.method;
    var data = call.arguments;
    switch (name) {
      case "foundDevice":
        {
          String deviceId = data['deviceId'];
          _devices.update(deviceId, (BleDevice device) {
            if (_discoveryOptions.allowDuplicatesKey) {
              _discoveryOptions?.success(device);
            }
            return device;
          }, ifAbsent: () {
            BleDevice device =
                new BleDevice(name: data['name'], deviceId: data['deviceId']);
            _discoveryOptions?.success(device);
            return device;
          });
        }
        break;
      case "valueUpdate":
        {
          String deviceId = data['deviceId'];
          String serviceId = data['serviceId'];
          String characteristicId = data['characteristicId'];

          BleDevice device = _devices[deviceId];
          if (device == null) {
            print("Error device id $deviceId not found in cached devices!!");
            break;
          }

          BleService service = device.getService(serviceId);
          if (service == null) {
            print("Error service id $serviceId not found in cached services!!");
            break;
          }

          BleCharacteristic characteristic =
              service.getCharacteristic(characteristicId);
          if (characteristic == null) {
            print(
                "Error characteristic id $characteristicId not found in cached characteristics!!");
            break;
          }

          String value = data['value'];

          if (_valueChangeCallback != null) {
            _valueChangeCallback(device, service, characteristic, value);
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
    return result;
  }

  static Future startBluetoothDevicesDiscovery(
      {DiscoveryOptions options: const DiscoveryOptions()}) async {
    _discoveryOptions = options;
    var result =
        await _channel.invokeMethod('startBluetoothDevicesDiscovery', {});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }

  static Future stopBluetoothDevicesDiscovery() async {
    var result =
        await _channel.invokeMethod('stopBluetoothDevicesDiscovery', {});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }

  static Future createBLEConnection({BleDevice device}) async {
    var result = await _channel
        .invokeMethod('createBLEConnection', {"deviceId": device.deviceId});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }

  static Future closeBLEConnection({BleDevice device}) async {
    assert(device != null);
    _devices.remove(device.deviceId);
    var result = await _channel
        .invokeMethod('closeBLEConnection', {"deviceId": device.deviceId});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }

  static Future<List<BleDevice>> getBluetoothDevices() async {
    var result = await _channel.invokeMethod('getBluetoothDevices');
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    List<BleDevice> list = [];
    _devices.forEach((_, BleDevice device) {
      list.add(device);
    });
    return list;
  }

  static Future getConnectedBluetoothDevices() async {
    var result = await _channel.invokeMethod('getConnectedBluetoothDevices');
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }

  static ValueChangeCallback _valueChangeCallback;

  static void onBLECharacteristicValueChange(ValueChangeCallback callback) {
    _valueChangeCallback = callback;
  }

  static Future<List<BleService>> getBLEDeviceServices(
      {BleDevice device}) async {
    assert(device != null);

    /// we just get services from cache
    if (device.services != null) {
      return device.services;
    }
    var result = await _channel
        .invokeMethod('getBLEDeviceServices', {"deviceId": device.deviceId});
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }

    List rawServices = result['services'];
    //services
    List<BleService> services = rawServices
        .map((data) =>
            new BleService(uuid: data['uuid'], isPrimary: data['isPrimary']))
        .toList();
    device.setServices(services);

    return services;
  }

  static Future<List<BleCharacteristic>> getBLEDeviceCharacteristics(
      {BleDevice device, BleService service}) async {
    if (service.characteristics != null) {
      return service.characteristics;
    }

    var result = await _channel.invokeMethod('getBLEDeviceCharacteristics',
        {"deviceId": device.deviceId, "serviceId": service.uuid});
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
    service.setCharacteristic(characteristics);

    return characteristics;
  }

  static Future readBLECharacteristicValue() async {
    var result = await _channel.invokeMethod('readBLECharacteristicValue');
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }

  static Future writeBLECharacteristicValue(
      {BleDevice device,
      BleService service,
      BleCharacteristic characteristic,
      String value}) async {
    var result = await _channel.invokeMethod('writeBLECharacteristicValue', {
      "deviceId": device.deviceId,
      "serviceId": service.uuid,
      "characteristicId": characteristic.uuid,
      "value": value
    });
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }

  static Future notifyBLECharacteristicValueChange(
      {BleDevice device,
      BleService service,
      BleCharacteristic characteristic,
      bool state}) async {
    var result =
        await _channel.invokeMethod('notifyBLECharacteristicValueChange', {
      "deviceId": device.deviceId,
      "serviceId": service.uuid,
      "characteristicId": characteristic.uuid,
      "state": state
    });
    if (result[code] != null) {
      throw new BleError(code: result[code]);
    }
    return result;
  }
}
