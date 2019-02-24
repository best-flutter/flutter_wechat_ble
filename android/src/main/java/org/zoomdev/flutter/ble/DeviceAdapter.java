package org.zoomdev.flutter.ble;

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

import java.util.List;
import java.util.UUID;

/**
 * Created by jzoom on 2018/1/26.
 */

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
class DeviceAdapter extends BluetoothGattCallback {

    private boolean connected;
    private BluetoothGatt gatt;

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


    @Override
    public synchronized void onConnectionStateChange(BluetoothGatt gatt, final int status, final int newState) {
        super.onConnectionStateChange(gatt, status, newState);
        if (status != BluetoothGatt.GATT_SUCCESS) { // 连接失败判断
            //连接失败
            connected = false;
            DeviceListener listener = getListener();
            if (listener != null) {
                listener.onConnectFailed(this);
            }
            return;
        }
        if (newState == BluetoothProfile.STATE_CONNECTED) { // 连接成功判断
            //mBluetoothGatt.discoverServices(); // 发现服务
            //成功之后加入到缓存
            connected = true;
            DeviceListener listener = getListener();
            if (listener != null) {
                listener.onConnected(this);
            }
            return;
        }
        if (newState == BluetoothProfile.STATE_DISCONNECTED) {  // 连接断开判断
            disconnect();
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
        DeviceListener listener = getListener();

        this.services = gatt.getServices();
        if (getServicesListener != null) {
            getServicesListener.onGetServices(services, status == BluetoothGatt.GATT_SUCCESS);
            getServicesListener = null;
        }

    }

    @Override
    public synchronized void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, final int status) {
        super.onDescriptorWrite(gatt, descriptor, status);
        if (status != BluetoothGatt.GATT_SUCCESS) {  // 写Descriptor失败
            return;
        }
        //不是失败的情况就是成功

    }

    @Override
    public synchronized void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
        super.onCharacteristicChanged(gatt, characteristic);
        //BLE设备主动向手机发送的数据时收到的数据回调
        if (listener != null) {
            listener.onCharacteristicChanged(this, characteristic);
        }
    }

    @Override
    public synchronized void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
        super.onCharacteristicWrite(gatt, characteristic, status);


        if(listener!=null){
            listener.onCharacteristicWrite(this,characteristic,status == BluetoothGatt.GATT_SUCCESS);
        }
    }

    @Override
    public synchronized void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
        super.onCharacteristicRead(gatt, characteristic, status);
        if(listener!=null){
            listener.onCharacteristicRead(this,characteristic,status == BluetoothGatt.GATT_SUCCESS);
        }
    }

    @Override
    public synchronized void onDescriptorRead(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
        super.onDescriptorRead(gatt, descriptor, status);
        if (status != BluetoothGatt.GATT_SUCCESS) {  // 写数据失败
            return;
        }
    }

    @Override
    public synchronized void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {
        super.onMtuChanged(gatt, mtu, status);
        if (status != BluetoothGatt.GATT_SUCCESS) {  // 写数据失败
            return;
        }
    }

    @Override
    public synchronized void onReadRemoteRssi(BluetoothGatt gatt, int rssi, int status) {
        super.onReadRemoteRssi(gatt, rssi, status);
        if (status != BluetoothGatt.GATT_SUCCESS) {  // 写数据失败
            return;
        }
    }

    @Override
    public synchronized void onReliableWriteCompleted(BluetoothGatt gatt, int status) {
        super.onReliableWriteCompleted(gatt, status);
        if (status != BluetoothGatt.GATT_SUCCESS) {  // 写数据失败
            return;
        }
    }


    public synchronized void close() {
        //////////////////////
        disconnect();

    }

    /**
     * 强制断开和设备的连接
     */
    public synchronized void disconnect() {
        try {
            if (this.gatt != null) {
                this.gatt.close();
                this.gatt = null;
            }
        } catch (Throwable t) {

        }
    }


    public BluetoothDevice getDevice() {
        return device;
    }

    public synchronized boolean isConnected() {
        return connected;
    }

    public void connect(Context context) {
        // We want to directly connect to the device, so we are setting the autoConnect
        // parameter to false.
        this.gatt = device.connectGatt(context, false, this);

    }

    public List<BluetoothGattService> getServices() {
        return services;
    }

    public String getName() {
        return device.getName();
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


    public List<BluetoothGattCharacteristic> getCharacteristics(BluetoothGattService service) {
        return service.getCharacteristics();
    }

    public void read(String serviceId, String characteristicId) throws BluetoothException {
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

    public void write(String serviceId, String characteristicId, byte[] bytes) throws BluetoothException {
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

    public void setNotify(String serviceId, String characteristicId, boolean notify) throws BluetoothException {
        BluetoothGattService bluetoothGattService = getService(serviceId);
        if (bluetoothGattService == null) {
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultServiceNotFound);
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
