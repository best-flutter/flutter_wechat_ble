package org.zoomdev.flutter.ble;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.os.Build;

import java.util.Collection;
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
    private final Map<String, DeviceAdapter> connectedDevices;
    private final Map<String, DeviceAdapter> deviceMap;
    private BleListener listener;

    public BleAdapter(Context context) {
        this.context = context;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            scanner = new BleScanner5();
        } else {
            scanner = new BleScanner4();
        }
        deviceMap = new ConcurrentHashMap<String, DeviceAdapter>();
        connectedDevices = new ConcurrentHashMap<String, DeviceAdapter>();
    }

    public synchronized void setListener(BleListener listener) {
        this.listener = listener;
    }


    public boolean isAvaliable(){
        BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        if (bluetoothManager == null) {
            return false;
        }
        BluetoothAdapter adapter = bluetoothManager.getAdapter();
        if (adapter == null) {
            //不支持
            return false;
        }
        return true;
    }

    /**
     * 启用蓝牙，注意这个方法需要和close互斥
     *
     * @return
     */
    public synchronized boolean open() {
        if(this.mBluetoothAdapter!=null){
            if (!mBluetoothAdapter.enable()) {
                mBluetoothAdapter.enable();
            }
            return true;
        }
        BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        if (bluetoothManager == null) {
            return false;
        }
        BluetoothAdapter adapter = bluetoothManager.getAdapter();
        if (adapter == null) {
            //不支持
            return false;
        }


        this.mBluetoothAdapter = adapter;

        if (!adapter.enable()) {
            adapter.enable();
        }

        return true;
    }

    /**
     * 关闭蓝牙，注意这个方法需要和open互斥
     */
    public synchronized void close() {
        for (Map.Entry<String, DeviceAdapter> entry : connectedDevices.entrySet()) {
            DeviceAdapter adapter = entry.getValue();
            adapter.disconnect();
        }
        connectedDevices.clear();
        deviceMap.clear();
        mBluetoothAdapter = null;
    }


    public synchronized BluetoothAdapterResult startScan() {
        if (mBluetoothAdapter == null) {
            return BluetoothAdapterResult.BluetoothAdapterResultNotInit;
        }
        deviceMap.clear();
        scanner.startScan(mBluetoothAdapter, this);
        discovering = true;
        return BluetoothAdapterResult.BluetoothAdapterResultOk;
    }


    public synchronized void stopScan() {
        scanner.stopScan(mBluetoothAdapter);
        discovering = false;
    }


    public synchronized DeviceAdapter getDevice(String deviceId) {
        return deviceMap.get(deviceId);
    }


    public synchronized DeviceAdapter getConnectedDevice(String deviceId) {
        return connectedDevices.get(deviceId);
    }


    /**
     * 注意这里的访问也应该是线程安全的
     *
     * @param deviceId
     * @return
     */
    public synchronized boolean isConnected(String deviceId) {
        return connectedDevices.containsKey(deviceId);

    }

    public synchronized BluetoothAdapterResult disconnectDevice(String deviceId) {
        if (mBluetoothAdapter == null) {
            return BluetoothAdapterResult.BluetoothAdapterResultNotInit;
        }

        DeviceAdapter device = getDevice(deviceId);
        if (device == null) {
            return BluetoothAdapterResult.BluetoothAdapterResultDeviceNotFound;
        }

        DeviceAdapter adapter = connectedDevices.get(deviceId);
        if (adapter != null) {
            adapter.disconnect();
            //通知一下
            connectedDevices.remove(deviceId);

            return BluetoothAdapterResult.BluetoothAdapterResultOk;
        }

        return BluetoothAdapterResult.BluetoothAdapterResultOk;
    }

    public synchronized BluetoothAdapterResult connectDevice(String deviceId) {
        if (mBluetoothAdapter == null) {
            return BluetoothAdapterResult.BluetoothAdapterResultNotInit;
        }

        DeviceAdapter device = getDevice(deviceId);
        if (device == null) {
            return BluetoothAdapterResult.BluetoothAdapterResultDeviceNotFound;
        }

        DeviceAdapter connectedDevice = connectedDevices.get(deviceId);
        if (connectedDevice != null) {
            //直接返回结果,表示在缓存里面已经有了
            if (connectedDevice.isConnected()) {
                if(listener!=null){
                    listener.onDeviceConnected(connectedDevice);
                }
            }else{
               // connectedDevice.connect(context);
            }

            return BluetoothAdapterResult.BluetoothAdapterResultOk;
        }

        connectedDevices.put(deviceId,device);
        //如果已经在连接了,就不用连接了
        device.connect(context);

        return BluetoothAdapterResult.BluetoothAdapterResultOk;

    }

    @Override
    public void onDeviceFound(BluetoothDevice device, int rssi) {
        String uuid = Utils.getDeviceId(device);

        DeviceAdapter deviceAdapter = deviceMap.get(uuid);
        if(deviceAdapter==null){
            deviceAdapter = new DeviceAdapter(device,this);
            deviceMap.put(uuid, deviceAdapter);
        }else{
            assert (deviceAdapter.getDevice() == device);
        }
        deviceAdapter.setRssi(rssi);
        if (listener != null) {
            listener.onDeviceFound(deviceAdapter);
        }

    }


    @Override
    public void onDisconnected(DeviceAdapter device) {
        connectedDevices.remove(device.getDeviceId());
        if (listener != null) {
            listener.onDeviceDisconnected(device);
        }
    }

    @Override
    public void onConnected(DeviceAdapter device) {
        connectedDevices.put(device.getDeviceId(),device);
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

    @Override
    public void onNotifyChanged(DeviceAdapter deviceAdapter, BluetoothGattCharacteristic characteristic,boolean success) {
        if (listener != null) {
            listener.onNotifyChanged(deviceAdapter, characteristic, success);
        }
    }


    public  Collection<DeviceAdapter> getDevices() {
        return deviceMap.values();
    }

    public  Collection<DeviceAdapter> getConnectedDevices(){
        return connectedDevices.values();
    }

    private boolean discovering;
    public  boolean isDiscovering() {
        return discovering;
    }
}
