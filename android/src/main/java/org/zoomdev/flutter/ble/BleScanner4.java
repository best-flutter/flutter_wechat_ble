package org.zoomdev.flutter.ble;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.os.Build;

/**
 * Created by renxueliang on 2017/8/9.
 */

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
class BleScanner4 implements BleScanner, BluetoothAdapter.LeScanCallback {
    private BleScannerListener listener;

    @Override
    public void startScan(BluetoothAdapter adapter, BleScannerListener listener) {
        this.listener = listener;
        adapter.stopLeScan(this);   // 停止扫描
        adapter.startLeScan(this);  // 开始扫描
    }

    @Override
    public void stopScan(BluetoothAdapter adapter) {
        adapter.stopLeScan(this);   // 停止扫描
        listener = null;
    }

    @Override
    public void onLeScan(BluetoothDevice bluetoothDevice, int i, byte[] bytes) {
        listener.onDeviceFound(bluetoothDevice, i);
    }
}
