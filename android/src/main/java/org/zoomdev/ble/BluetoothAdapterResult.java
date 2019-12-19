package org.zoomdev.ble;

/**
 * Created by jzoom on 2018/1/25.
 */

public enum BluetoothAdapterResult {
    BluetoothAdapterResultOk,
    BluetoothAdapterResultNotInit,
    BluetoothAdapterResultDeviceNotFound,
    BluetoothAdapterResultDeviceNotConnected,
    BluetoothAdapterResultServiceNotFound,
    BluetoothAdapterResultCharacteristicsNotFound,
    BluetoothAdapterResultCharacteristicsPropertyNotSupport,   //不支持
}