package org.zoomdev.flutter.ble;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGattCharacteristic;

/**
 * Created by jzoom on 2018/1/26.
 */

public interface BleListener {

    /**
     * 找到设备
     *
     * @param device
     * @param rssi
     */
    void onDeviceFound(DeviceAdapter device);


    void onDeviceConnected(DeviceAdapter device);

    void onDeviceDisconnected(DeviceAdapter device);

    void onDeviceConnectFailed(DeviceAdapter device);

    void onCharacteristicWrite(DeviceAdapter device, BluetoothGattCharacteristic characteristic, boolean success);

    void onCharacteristicChanged(DeviceAdapter device, BluetoothGattCharacteristic characteristic);

    void onCharacteristicRead(DeviceAdapter device, BluetoothGattCharacteristic characteristic, boolean success);
}
