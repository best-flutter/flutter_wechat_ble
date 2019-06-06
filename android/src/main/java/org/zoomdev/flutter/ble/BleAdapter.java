package org.zoomdev.flutter.ble;

import android.Manifest;
import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Created by jzoom on 2018/1/4.
 */
@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
class BleAdapter implements BleScanner.BleScannerListener, DeviceListener {


    private final BleScanner scanner;
    private Context context;
    private BluetoothAdapter mBluetoothAdapter;
    private BluetoothGattService mLeDeviceListAdapter;
    private BluetoothGatt mBluetoothGatt;
    private Map<String, DeviceAdapter> connectedDevcie;
    private Map<String, BluetoothDevice> deviceMap;
    private BleListener listener;

    public BleAdapter(Context context) {
        this.context = context;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            scanner = new BleScanner5();
        } else {
            scanner = new BleScanner4();
        }
    }

    public void setListener(BleListener listener) {
        synchronized (this) {
            this.listener = listener;
        }
    }

    /**
     * 启用蓝牙，注意这个方法需要和close互斥
     *
     * @return
     */
    public boolean open() {
        synchronized (this) {
            BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
            if (bluetoothManager == null) {
                return false;
            }
            BluetoothAdapter adapter = bluetoothManager.getAdapter();
            if (adapter == null) {
                //不支持
                return false;
            }

            deviceMap = new ConcurrentHashMap<String, BluetoothDevice>();
            connectedDevcie = new ConcurrentHashMap<String, DeviceAdapter>();
            this.mBluetoothAdapter = adapter;

            if (!adapter.enable()) {
                adapter.enable();
            }


        }

        return true;
    }

    /**
     * 关闭蓝牙，注意这个方法需要和open互斥
     */
    public void close() {
        synchronized (this) {
            if (connectedDevcie != null) {
                for (Map.Entry<String, DeviceAdapter> entry : connectedDevcie.entrySet()) {
                    DeviceAdapter adapter = entry.getValue();
                    adapter.disconnect();
                }
                connectedDevcie.clear();
                connectedDevcie = null;
            }
            deviceMap = null;
            mBluetoothAdapter = null;
        }
    }


    public BluetoothAdapterResult startScan() {



        synchronized (this) {
            if (mBluetoothAdapter == null) {
                return BluetoothAdapterResult.BluetoothAdapterResultNotInit;
            }
            scanner.startScan(mBluetoothAdapter, this);
            return BluetoothAdapterResult.BluetoothAdapterResultOk;
        }
    }


    public void stopScan() {
        synchronized (this) {
            scanner.stopScan(mBluetoothAdapter);
        }
    }


    public BluetoothDevice getDevice(String deviceId) {
        synchronized (this) {
            return deviceMap.get(deviceId);
        }
    }


    public DeviceAdapter getConnectedDevice(String deviceId) {
        return connectedDevcie.get(deviceId);
    }


    /**
     * 注意这里的访问也应该是线程安全的
     *
     * @param deviceId
     * @return
     */
    public boolean isConnected(String deviceId) {
        synchronized (this) {
            return connectedDevcie.containsKey(deviceId);
        }

    }

    public BluetoothAdapterResult disconnectDevice(String deviceId) {
        synchronized (this) {
            if (mBluetoothAdapter == null) {
                return BluetoothAdapterResult.BluetoothAdapterResultNotInit;
            }

            BluetoothDevice device = getDevice(deviceId);
            if (device == null) {
                return BluetoothAdapterResult.BluetoothAdapterResultDeviceNotFound;
            }

            DeviceAdapter adapter = connectedDevcie.get(deviceId);
            if (adapter != null) {
                adapter.disconnect();
                return BluetoothAdapterResult.BluetoothAdapterResultOk;
            }

            return BluetoothAdapterResult.BluetoothAdapterResultOk;
        }
    }

    public BluetoothAdapterResult connectDevice(String deviceId) {
        synchronized (this) {
            if (mBluetoothAdapter == null) {
                return BluetoothAdapterResult.BluetoothAdapterResultNotInit;
            }

            BluetoothDevice device = getDevice(deviceId);
            if (device == null) {
                return BluetoothAdapterResult.BluetoothAdapterResultDeviceNotFound;
            }

            DeviceAdapter adapter = connectedDevcie.get(deviceId);
            if (adapter != null) {
                //直接返回结果,表示在缓存里面已经有了
                if (adapter.isConnected() && listener != null) {
                    listener.onDeviceConnected(adapter);
                }

                return BluetoothAdapterResult.BluetoothAdapterResultOk;
            }
            //如果已经在连接了,就不用连接了
            adapter = new DeviceAdapter(device, this);
            connectedDevcie.put(deviceId, adapter);
            adapter.connect(context);

            return BluetoothAdapterResult.BluetoothAdapterResultOk;
        }

    }

    @Override
    public void onDeviceFound(BluetoothDevice device, int rssi) {
        String uuid = Utils.getDeviceId(device);

        synchronized (this) {
            if (!deviceMap.containsKey(uuid)) {
                //通知一下
                if (listener != null) {
                    listener.onDeviceFound(device, rssi);
                }
            }
            deviceMap.put(uuid, device);
        }
    }


    @Override
    public void onDisconnected(DeviceAdapter device) {
        if (listener != null) {
            listener.onDeviceDisconnected(device);
        }
    }

    @Override
    public void onConnected(DeviceAdapter device) {
        if (listener != null) {
            listener.onDeviceConnected(device);
        }
    }

    @Override
    public void onConnectFailed(DeviceAdapter device) {
        if (listener != null) {
            listener.onDeviceConnectFailed(device);
        }
    }


    @Override
    public void onCharacteristicChanged(DeviceAdapter device, BluetoothGattCharacteristic characteristic) {
        if (listener != null) {
            listener.onCharacteristicChanged(device, characteristic);
        }
    }

    @Override
    public void onCharacteristicWrite(DeviceAdapter device, BluetoothGattCharacteristic characteristic, boolean success) {
        if (listener != null) {
            listener.onCharacteristicWrite(device, characteristic, success);
        }
    }

    @Override
    public void onCharacteristicRead(DeviceAdapter device, BluetoothGattCharacteristic characteristic, boolean success) {
        if (listener != null) {
            listener.onCharacteristicRead(device, characteristic, success);
        }
    }


}
