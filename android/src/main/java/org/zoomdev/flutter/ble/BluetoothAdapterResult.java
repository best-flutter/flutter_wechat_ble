package org.zoomdev.flutter.ble;

/**
 * Created by jzoom on 2018/1/25.
 */

enum BluetoothAdapterResult {
    BluetoothAdapterResultOk,
    BluetoothAdapterResultNotInit,
    BluetoothAdapterResultDeviceNotFound,
    BluetoothAdapterResultDeviceNotConnected,
    BluetoothAdapterResultServiceNotFound,
    BluetoothAdapterResultCharacteristicsNotFound,
    BluetoothAdapterResultCharacteristicsPropertyNotSupport,   //不支持
}