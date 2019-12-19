package org.zoomdev.ble;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.os.Build;
import android.util.Log;

import java.util.List;
import java.util.UUID;

/**
 * Created by jzoom on 2018/1/26.
 */

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
public class DeviceAdapter extends BluetoothGattCallback {

    private boolean connected;
    private BluetoothGatt gatt;

    public int getRssi() {
        return rssi;
    }

    public void setRssi(int rssi) {
        this.rssi = rssi;
    }

    private int rssi;

    private final BluetoothDevice device;
    private List<BluetoothGattService> services;
    private final DeviceListener listener;

    public DeviceAdapter(BluetoothDevice device, DeviceListener listener) {
        this.device = device;
        this.listener = listener;
    }


    public String getDeviceId() {
        return Utils.getDeviceId(device);
    }

    public DeviceListener getListener() {
        return listener;
    }

    private int retryCount = 1;
    @Override
    public synchronized void onConnectionStateChange(BluetoothGatt gatt, final int status, final int newState) {
        super.onConnectionStateChange(gatt, status, newState);
        Log.d("BLE","onConnectionStateChange " + status + " " + newState);
        if (status != BluetoothGatt.GATT_SUCCESS) { // 连接失败判断
            if(retryCount > 0){
                this.retryCount--;
                this.clear();
                this.connect(context);
            }else{
                //连接失败
                Log.d("BLE","连接失败");
                connected = false;
                this.clear();
                DeviceListener listener = getListener();

                if (listener != null) {
                    listener.onConnectFailed(this);
                }
            }

            return;
        }
        if (newState == BluetoothProfile.STATE_CONNECTED) { // 连接成功判断
            //mBluetoothGatt.discoverServices(); // 发现服务
            Log.d("BLE","连接成功");
            //成功之后加入到缓存
            connected = true;
            DeviceListener listener = getListener();
            if (listener != null) {
                listener.onConnected(this);
            }
            return;
        }
        if (newState == BluetoothProfile.STATE_DISCONNECTED) {  // 连接断开判断
            this.clear();
            connected = false;
            DeviceListener listener = getListener();
            if (listener != null) {
                listener.onDisconnected(this);
            }
            return;
        }
    }


    @Override
    public synchronized void onServicesDiscovered(BluetoothGatt gatt, final int status) {
        super.onServicesDiscovered(gatt, status);

        this.services = gatt.getServices();
        if (getServicesListener != null) {
            getServicesListener.onGetServices(services, status == BluetoothGatt.GATT_SUCCESS);
            getServicesListener = null;
        }

    }

    @Override
    public synchronized void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, final int status) {
        super.onDescriptorWrite(gatt, descriptor, status);
//        if (status != BluetoothGatt.GATT_SUCCESS) {  // 写Descriptor失败
//            return;
//        }
        //不是失败的情况就是成功


        if(listener!=null){
            listener.onNotifyChanged(this,descriptor.getCharacteristic(),status ==  BluetoothGatt.GATT_SUCCESS);
        }

//        if (listener != null) {
//            listener.onCharacteristicChanged(this, characteristic);
//        }
        Log.d("BLE","onDescriptorWrite");
    }

    @Override
    public synchronized void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
        super.onCharacteristicChanged(gatt, characteristic);
        Log.d("BLE","onCharacteristicChanged");
        //BLE设备主动向手机发送的数据时收到的数据回调
        if (listener != null) {
            listener.onCharacteristicChanged(this, characteristic);
        }
    }

    @Override
    public synchronized void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
        super.onCharacteristicWrite(gatt, characteristic, status);

        Log.d("BLE","onCharacteristicWrite");

        if (listener != null) {
            listener.onCharacteristicWrite(this, characteristic, status == BluetoothGatt.GATT_SUCCESS);
        }
    }

    @Override
    public synchronized void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
        super.onCharacteristicRead(gatt, characteristic, status);
        Log.d("BLE","onCharacteristicRead");
        if (listener != null) {
            listener.onCharacteristicRead(this, characteristic, status == BluetoothGatt.GATT_SUCCESS);
        }
    }

    @Override
    public synchronized void onDescriptorRead(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
        super.onDescriptorRead(gatt, descriptor, status);
        Log.d("BLE","onDescriptorRead");
        if (status != BluetoothGatt.GATT_SUCCESS) {  // 写数据失败
            return;
        }
    }

    public synchronized void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {
        //super.onMtuChanged(gatt, mtu, status);
        Log.d("BLE","onMtuChanged");
        if (status != BluetoothGatt.GATT_SUCCESS) {  // 写数据失败
            return;
        }
    }

    @Override
    public synchronized void onReadRemoteRssi(BluetoothGatt gatt, int rssi, int status) {
        super.onReadRemoteRssi(gatt, rssi, status);
        Log.d("BLE","onReadRemoteRssi");
        if (status != BluetoothGatt.GATT_SUCCESS) {  // 写数据失败
            return;
        }
    }

    @Override
    public synchronized void onReliableWriteCompleted(BluetoothGatt gatt, int status) {
        super.onReliableWriteCompleted(gatt, status);
        Log.d("BLE","onReliableWriteCompleted");
        if (status != BluetoothGatt.GATT_SUCCESS) {  // 写数据失败
            return;
        }
    }


    public synchronized void close() {
        //////////////////////
        disconnect();

    }

    private void clear() {
        if (this.gatt != null){
            this.gatt.close();
            this.gatt = null;
        }
        if(this.services!=null){
            this.services.clear();
            this.services = null;
        }

    }

    /**
     * 强制断开和设备的连接
     */
    public synchronized void disconnect() {

        try {
            if (this.gatt != null) {
                this.gatt.disconnect();
            }
        } catch (Throwable t) {

        }finally {
        }
    }


    public BluetoothDevice getDevice() {
        return device;
    }

    public synchronized boolean isConnected() {
        return connected;
    }

    private Context context;

    public synchronized void connect(Context context) {
        this.context = context;
        // We want to directly connect to the device, so we are setting the autoConnect
        // parameter to false.
        if(this.gatt!=null){
            Log.d("BLE","gatt is not null");
        }
        retryCount = 1;
        this.gatt = device.connectGatt(context, false, this);

    }

    public synchronized List<BluetoothGattService> getServices() {
        return services;
    }

    public synchronized String getName() {
        return device.getName();
    }

    public ConnectionListener getConnectionListener() {
        return connectionListener;
    }

    ConnectionListener connectionListener;
    public void setConnectionListener(ConnectionListener listener) {
        this.connectionListener = listener;
    }




    public static interface GetServicesListener {
        void onGetServices(List<BluetoothGattService> services, boolean success);
    }

    private GetServicesListener getServicesListener;

    public synchronized BluetoothGattService getService(String serviceId) {
        if (services == null) {
            return null;
        }
        for (BluetoothGattService service : services) {
            if (serviceId.equals(Utils.getUuidOfService(service))) {
                return service;
            }
        }
        return null;
    }


    public synchronized List<BluetoothGattCharacteristic> getCharacteristics(BluetoothGattService service) {
        return service.getCharacteristics();
    }

    public synchronized void read(String serviceId, String characteristicId) throws BluetoothException {
        BluetoothGattService bluetoothGattService = getService(serviceId);
        if (bluetoothGattService == null) {
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultServiceNotFound);
        }
        BluetoothGattCharacteristic characteristic = bluetoothGattService.getCharacteristic(UUID.fromString(characteristicId));
        if (characteristic == null) {
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultCharacteristicsNotFound);
        }
        this.gatt.readCharacteristic(characteristic);

    }




    public synchronized void write(
            String serviceId,
            String characteristicId,
            byte[] bytes) throws BluetoothException {
        BluetoothGattService bluetoothGattService = getService(serviceId);
        if (bluetoothGattService == null) {
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultServiceNotFound);
        }
        BluetoothGattCharacteristic characteristic = bluetoothGattService.getCharacteristic(UUID.fromString(characteristicId));
        if (characteristic == null) {
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultCharacteristicsNotFound);
        }

        characteristic.setValue(bytes);
        this.gatt.writeCharacteristic(characteristic);
    }

    public synchronized void setNotify(String serviceId, String characteristicId, boolean notify) throws BluetoothException {
        BluetoothGattService bluetoothGattService = getService(serviceId);
        if (bluetoothGattService == null) {
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultServiceNotFound);
        }
        if(this.gatt == null){
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultDeviceNotConnected);
        }
        BluetoothGattCharacteristic characteristic = bluetoothGattService.getCharacteristic(UUID.fromString(characteristicId));
        if (characteristic == null) {
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultCharacteristicsNotFound);
        }
        if ((characteristic.getProperties() & BluetoothGattCharacteristic.PROPERTY_NOTIFY)
                == BluetoothGattCharacteristic.PROPERTY_NOTIFY) {
            this.gatt.setCharacteristicNotification(characteristic, notify);
            List<BluetoothGattDescriptor> descriptorList = characteristic.getDescriptors();
            if (descriptorList != null) {
                for (BluetoothGattDescriptor descriptor : descriptorList) {
                    byte[] value = notify ? BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE : BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE;
                    descriptor.setValue(value);
                    this.gatt.writeDescriptor(descriptor);
                }
            }
        } else {
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultCharacteristicsPropertyNotSupport);
        }

    }

    public synchronized void getServices(GetServicesListener listener) {
        if (services != null) {
            listener.onGetServices(services, true);
        } else {
            this.getServicesListener = listener;
            this.gatt.discoverServices();
        }
    }


}
