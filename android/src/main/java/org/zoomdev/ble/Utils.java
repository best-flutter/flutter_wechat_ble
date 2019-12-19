package org.zoomdev.ble;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.os.Build;

public class Utils {
    public static String getUuidOfService(BluetoothGattService service) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            return service.getUuid().toString().toUpperCase();
        } else {
            return service.toString().toUpperCase();
        }
    }

    public static String getUuidOfCharacteristic(BluetoothGattCharacteristic characteristic) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            return characteristic.getUuid().toString().toUpperCase();
        } else {
            return characteristic.toString().toUpperCase();
        }
    }

    /**
     * 先预留，找到合适的方法再改
     *
     * @param device
     * @return
     */
    public static String getDeviceId(BluetoothDevice device) {
        //这里只要返回唯一就行
        return new StringBuilder().append(device.getAddress()).append(device.hashCode()).toString();//return device.getAddress();
    }
}
