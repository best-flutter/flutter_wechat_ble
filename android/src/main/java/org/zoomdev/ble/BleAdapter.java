package org.zoomdev.ble;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.os.Build;
import android.util.Log;

import java.util.Collection;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Created by jzoom on 2018/1/4.
 */
@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
public class BleAdapter implements BleScanner.BleScannerListener, DeviceListener {


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
        listenerMap.clear();
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

    public synchronized BluetoothAdapterResult connectDevice(String deviceId,ConnectionListener listener) {
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
                    listener.onDeviceConnected(connectedDevice,true);
                }
            }else{
               // connectedDevice.connect(context);
            }

            return BluetoothAdapterResult.BluetoothAdapterResultOk;
        }

        connectedDevices.put(deviceId,device);
        //如果已经在连接了,就不用连接了
        device.connect(context);
        device.setConnectionListener(listener);
        setListener(device.getDeviceId(),listener);
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

    private Map<String,Object> listenerMap = new ConcurrentHashMap<>();

    private String getKey(String name,String deviceId,String serviceId,String characteristicId){
        return new StringBuilder().append(name).append(":").append(deviceId).append(":").append(serviceId).append(":").append(characteristicId).toString();
    }

    private void setListener(String name,String deviceId,String serviceId,String characteristicId,CharacteristicActionListener listener){
        listenerMap.put(getKey(name,deviceId,serviceId,characteristicId),listener);
    }

    private CharacteristicActionListener getActionListener(String name,String deviceId,String serviceId,String characteristicId){
        return (CharacteristicActionListener)listenerMap.remove(getKey(name,deviceId,serviceId,characteristicId));
    }
    private ConnectionListener getConnectionListener(String deviceId){
        return (ConnectionListener)listenerMap.remove(deviceId);
    }

    public static final String NAME_WRITE = "w";
    public static final String NAME_READ = "r";
    public static final String NAME_NOTIFY = "n";

    public void setListener(String deviceId,ConnectionListener listener){
        listenerMap.put(deviceId,listener);
    }




    public void writeValue(
            String deviceId, String serviceId, String characteristicId, byte[] value,CharacteristicActionListener listener ) throws BluetoothException {
        DeviceAdapter deviceAdapter =getConnectedDevice(deviceId);
        if(deviceAdapter==null){
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultDeviceNotConnected);
        }
        setListener(NAME_WRITE,deviceId,serviceId,characteristicId,listener);
        deviceAdapter.write(serviceId,characteristicId,value);
    }

    public void readValue(
            String deviceId, String serviceId, String characteristicId,CharacteristicActionListener listener ) throws BluetoothException {
        DeviceAdapter deviceAdapter =getConnectedDevice(deviceId);
        if(deviceAdapter==null){
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultDeviceNotConnected);
        }
        setListener(NAME_READ,deviceId,serviceId,characteristicId,listener);
        deviceAdapter.read(serviceId,characteristicId);
    }

    public void setNotify(
            String deviceId, String serviceId, String characteristicId,boolean notify,CharacteristicActionListener listener ) throws BluetoothException {
        DeviceAdapter deviceAdapter =getConnectedDevice(deviceId);
        if(deviceAdapter==null){
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultDeviceNotConnected);
        }
        setListener(NAME_NOTIFY,deviceId,serviceId,characteristicId,listener);
        deviceAdapter.setNotify(serviceId,characteristicId,notify);
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
        ConnectionListener connectionListener = getConnectionListener(device.getDeviceId());
        if(connectionListener!=null){
            connectionListener.onDeviceConnected(device,true);
        }
    }

    @Override
    public void onConnectFailed(DeviceAdapter device) {
        if (listener != null) {
            listener.onDeviceConnectFailed(device);
        }
        ConnectionListener connectionListener = getConnectionListener(device.getDeviceId());
        if(connectionListener!=null){
            connectionListener.onDeviceConnected(device,false);
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


        CharacteristicActionListener listener = getActionListener(NAME_WRITE,device.getDeviceId(),Utils.getUuidOfService(characteristic.getService()),Utils.getUuidOfCharacteristic(characteristic));
        if(listener==null){
            Log.e("BLE","Cannot find listener of characteristic"+characteristic);
            return;
        }
        listener.onResult(device,characteristic,success);

    }

    @Override
    public void onCharacteristicRead(DeviceAdapter device, BluetoothGattCharacteristic characteristic, boolean success) {
        CharacteristicActionListener listener = getActionListener(NAME_READ,device.getDeviceId(),Utils.getUuidOfService(characteristic.getService()),Utils.getUuidOfCharacteristic(characteristic));
        if(listener==null){
            Log.e("BLE","Cannot find listener of characteristic"+characteristic);
            return;
        }
        listener.onResult(device,characteristic,success);
    }

    @Override
    public void onNotifyChanged(DeviceAdapter device, BluetoothGattCharacteristic characteristic,boolean success) {
        CharacteristicActionListener listener = getActionListener(NAME_NOTIFY,device.getDeviceId(),Utils.getUuidOfService(characteristic.getService()),Utils.getUuidOfCharacteristic(characteristic));
        if(listener==null){
            Log.e("BLE","Cannot find listener of characteristic"+characteristic);
            return;
        }
        listener.onResult(device,characteristic,success);
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
