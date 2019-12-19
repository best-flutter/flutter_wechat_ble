package org.zoomdev.ble;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;

/**
 * Created by jzoom on 2018/1/4.
 */


/**
 * device scanner
 */
public interface BleScanner {

    /**
     *
     */
    public interface BleScannerListener {
        void onDeviceFound(BluetoothDevice device, int rssi);
    }

    void startScan(BluetoothAdapter adapter, BleScannerListener listener);

    void stopScan(BluetoothAdapter adapter);

}
