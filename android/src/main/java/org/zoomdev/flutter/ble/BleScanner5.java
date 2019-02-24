package org.zoomdev.flutter.ble;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.os.Build;

import java.util.List;

/**
 * Created by renxueliang on 2017/8/9.
 */

@TargetApi(Build.VERSION_CODES.LOLLIPOP)
class BleScanner5 extends ScanCallback implements BleScanner {
    BluetoothLeScanner scaner;

    private BleScannerListener listener;

    public void startScan(BluetoothAdapter adapter, BleScannerListener listener) {
        this.listener = listener;
        scaner = adapter.getBluetoothLeScanner();
        // scaner.stopScan(this);   // 停止扫描
        scaner.startScan(this);  // 开始扫描

    }

    public void stopScan(BluetoothAdapter adapter) {
        scaner.stopScan(this);   // 停止扫描
    }

    @Override
    public void onScanResult(int callbackType, ScanResult result) {
        if (listener != null) {
            listener.onDeviceFound(result.getDevice(), result.getRssi());
        }

    }

    @Override
    public void onBatchScanResults(List<ScanResult> results) {

        for (ScanResult result : results) {
            if (listener != null) {

                listener.onDeviceFound(result.getDevice(), result.getRssi());
            }
        }

    }

    @Override
    public void onScanFailed(int errorCode) {
        System.out.print(errorCode);
    }
}
