package org.zoomdev.flutter.ble;

import android.bluetooth.BluetoothGattCharacteristic;

/**
 * Created by jzoom on 2018/1/27.
 */

public interface DeviceListener {


    /**
     * 启动了连接
     *
     * @param device
     */
    void onConnected(DeviceAdapter device);

    /**
     * 连接失败
     *
     * @param device
     */
    void onConnectFailed(DeviceAdapter device);

    /**
     * 断开连接
     *
     * @param device
     */
    void onDisconnected(DeviceAdapter device);


    /**
     * value changed
     *
     * @param device
     * @param characteristic
     */
    void onCharacteristicChanged(DeviceAdapter device, BluetoothGattCharacteristic characteristic);

    void onCharacteristicWrite(DeviceAdapter device, BluetoothGattCharacteristic characteristic, boolean success);

    void onCharacteristicRead(DeviceAdapter device, BluetoothGattCharacteristic characteristic, boolean success);

    void onNotifyChanged(DeviceAdapter deviceAdapter, BluetoothGattCharacteristic characteristic,boolean success);
}
