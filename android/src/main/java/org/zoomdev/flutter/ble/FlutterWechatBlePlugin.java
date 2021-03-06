package org.zoomdev.flutter.ble;

import android.annotation.TargetApi;
import android.app.Activity;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;

import org.zoomdev.ble.BleAdapter;
import org.zoomdev.ble.BleListener;
import org.zoomdev.ble.BluetoothAdapterResult;
import org.zoomdev.ble.BluetoothException;
import org.zoomdev.ble.CharacteristicActionListener;
import org.zoomdev.ble.ConnectionListener;
import org.zoomdev.ble.DeviceAdapter;
import org.zoomdev.ble.HexUtil;
import org.zoomdev.ble.Utils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterWechatBlePlugin
 */
@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
public class FlutterWechatBlePlugin implements MethodCallHandler, BleListener, PluginRegistry.RequestPermissionsResultListener {
    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_wechat_ble");
        FlutterWechatBlePlugin plugin = new FlutterWechatBlePlugin(registrar, channel);
        channel.setMethodCallHandler(plugin);
    }
    private static MyHandler hander = new MyHandler(Looper.getMainLooper());

    private MethodChannel channel;
    protected static class MyHandler extends Handler {
        public MyHandler(Looper looper) {
            super(looper);
        }

        @Override
        public void handleMessage(Message msg) {
            Runnable listener = (Runnable) msg.obj;
            if(listener instanceof Activity){
                if(((Activity)listener).isFinishing()){
                    return;
                }
            }
            try{
                listener.run();
            }catch (Throwable t){
                android.util.Log.d("BLE",t.getMessage());
            }

        }
    }

    private void runOnUIThread(Runnable runnable){
        if(Looper.myLooper() == Looper.getMainLooper()){
            runnable.run();
        }else{
            Message msg = Message.obtain();
            msg.obj = runnable;
            hander.sendMessage(msg);
        }

    }


    @Override
    public void onMethodCall(MethodCall call, Result result) {
        String method = call.method;
        if ("openBluetoothAdapter".equals(method)) {
            openBluetoothAdapter(result);
        } else if ("closeBluetoothAdapter".equals(method)) {
            closeBluetoothAdapter(result);
        } else if ("startBluetoothDevicesDiscovery".equals(method)) {
            startBluetoothDevicesDiscovery(result);
        } else if ("stopBluetoothDevicesDiscovery".equals(method)) {
            stopBluetoothDevicesDiscovery(result);
        } else if ("getBLEDeviceServices".equals(method)) {
            getBLEDeviceServices((Map) call.arguments, result);
        } else if ("getBLEDeviceCharacteristics".equals(method)) {
            getBLEDeviceCharacteristics((Map) call.arguments, result);
        } else if ("createBLEConnection".equals(method)) {
            createBLEConnection((Map) call.arguments, result);
        } else if ("closeBLEConnection".equals(method)) {
            closeBLEConnection((Map) call.arguments, result);
        } else if ("notifyBLECharacteristicValueChange".equals(method)) {
            notifyBLECharacteristicValueChange((Map) call.arguments, result);
        } else if ("writeBLECharacteristicValue".equals(method)) {
            writeBLECharacteristicValue((Map) call.arguments, result);
        } else if ("readBLECharacteristicValue".equals(method)) {
            readBLECharacteristicValue((Map) call.arguments, result);
        } else if("getBluetoothDevices".equals(method)){
            List<Map> list = new ArrayList<>();
            for(DeviceAdapter device : adapter.getDevices()){
                deviceToMap(device);
            }
            result.success(list);

        }else if("getConnectedBluetoothDevices".equals(method)){
            List<Map> list = new ArrayList<>();
            for(DeviceAdapter device : adapter.getConnectedDevices()){
                deviceToMap(device);
            }
            result.success(list);
        }else if("getBluetoothAdapterState".equals(method)){
            Map map = new HashMap();
            map.put("discovering",adapter.isAvaliable());
            map.put("available",adapter.isDiscovering());

            result.success(map);
        } else {
            result.notImplemented();
        }
    }


    Registrar registrar;

    public FlutterWechatBlePlugin(Registrar registrar, MethodChannel channel) {
        super();
        this.registrar = registrar;
        adapter = new BleAdapter(registrar.context().getApplicationContext());
        adapter.setListener(this);
        adapter.getDevices();
        this.channel = channel;

        registrar.addRequestPermissionsResultListener(this);
    }



    public static final String NOT_INIT = "10000";
    public static final String NOT_AVALIABLE = "10001";
    public static final String NO_DEVICE = "10002";
    public static final String CONNECTION_FAIL = "10003";
    public static final String NO_SERVICE = "10004";
    public static final String NO_CHARACTERISTIC = "10005";
    public static final String NO_CONNECTION = "10006";
    public static final String PROPERTY_NOT_SUPPOTT = "10007";
    public static final String SYSTEM_ERROR = "10008";
    public static final String SYSTEM_NOT_SUPPORT = "10009";

    private BleAdapter adapter;


    public synchronized void openBluetoothAdapter(Result promise) {
        if (adapter.open()) {
            promise.success(new HashMap<String,Object>());
        } else {
            processError(NOT_AVALIABLE, "Bluetooth is not avaliable", promise);
        }
    }

    private static final int REQUEST_CODE_ACCESS_COARSE_LOCATION = 1;
    public synchronized void startBluetoothDevicesDiscovery(Result promise) {
        //检查权限
        BluetoothAdapterResult ret = adapter.startScan();
        if (BluetoothAdapterResult.BluetoothAdapterResultOk == adapter.startScan()) {
            promise.success(new HashMap<String,Object>());

            adapter.notifyDevices();

        } else {
            retToCallback(ret, promise);
        }
    }


    public synchronized void stopBluetoothDevicesDiscovery(Result promise) {
        adapter.stopScan();
        promise.success(new HashMap<String,Object>());
    }


    public synchronized void readBLECharacteristicValue(Map data, final Result promise) {
        String deviceId = (String) data.get("deviceId");
        if (deviceId == null) {
            retToCallback(BluetoothAdapterResult.BluetoothAdapterResultNotInit, promise);
            return;
        }
        try {
            String serviceId = (String) data.get("serviceId");
            String characteristicId = (String) data.get("characteristicId");

            adapter.readValue(deviceId, serviceId, characteristicId, new CharacteristicActionListener() {
                @Override
                public void onResult(final DeviceAdapter device,
                                     final BluetoothGattCharacteristic characteristic,
                                     final boolean success) {
                    runOnUIThread(new Runnable() {
                        @Override
                        public void run() {
                            if (success) {
                                Map map = new HashMap();
                                map.put("deviceId", device.getDeviceId());
                                map.put("serviceId", Utils.getUuidOfService(characteristic.getService()));
                                map.put("characteristicId", Utils.getUuidOfCharacteristic(characteristic));
                                map.put("value", HexUtil.encodeHexStr(characteristic.getValue()));
                                promise.success(map);
                            } else {
                                processError(SYSTEM_ERROR, "Read value failed", promise);
                            }
                        }
                    });
                }
            });


        } catch (BluetoothException e) {
            retToCallback(e.ret, promise);
        }
    }

    public synchronized void writeBLECharacteristicValue(Map data, final Result promise) {
        String deviceId = (String) data.get("deviceId");
        if (deviceId == null) {
            retToCallback(BluetoothAdapterResult.BluetoothAdapterResultNotInit, promise);
            return;
        }
        try {
            String serviceId = (String) data.get("serviceId");
            String characteristicId = (String) data.get("characteristicId");
            String value = (String) data.get("value");
            byte[] bytes = HexUtil.decodeHex(value);
            Log.d("BLE", String.format("write value %s", value ) );
           // writeListener = promise;
            adapter.writeValue(deviceId, serviceId, characteristicId, bytes, new CharacteristicActionListener() {
                @Override
                public void onResult(DeviceAdapter deviceAdapter,BluetoothGattCharacteristic characteristic, final boolean success) {
                    runOnUIThread(new Runnable() {
                        @Override
                        public void run() {
                            if (success) {
                                promise.success(new HashMap<String,Object>());
                            } else {
                                processError(SYSTEM_ERROR, "Write value failed", promise);
                            }
                        }
                    });
                }
            });
            Log.d("BLE", String.format("write value success %s, waiting for notify", value ) );
        } catch (BluetoothException e) {

            Log.d("BLE", String.format("write value error %s %s",String.valueOf(e.ret),e.getMessage() ) );
            retToCallback(e.ret, promise);
        }


    }


    public synchronized void getBLEDeviceCharacteristics(Map data, final Result promise) {

        String deviceId = (String) data.get("deviceId");
        if (deviceId == null) {
            retToCallback(BluetoothAdapterResult.BluetoothAdapterResultNotInit, promise);
            return;
        }
        DeviceAdapter deviceAdapter = null;
        try {
            deviceAdapter = getConnectedDevice(deviceId);
            if (deviceAdapter.getServices() == null) {
                processError(SYSTEM_ERROR, "Call getBLEDeviceServices first", promise);
                return;
            }

            String serviceId = (String) data.get("serviceId");
            BluetoothGattService service = deviceAdapter.getService(serviceId);
            if (service == null) {
                processError(NO_SERVICE, "Cannot find service", promise);
                return;
            }
            List<BluetoothGattCharacteristic> characteristics = deviceAdapter.getCharacteristics(service);

            List arr = new ArrayList();
            for (BluetoothGattCharacteristic characteristic : characteristics) {
                Map map = new HashMap();
                map.put("uuid", Utils.getUuidOfCharacteristic(characteristic));
                map.put("read",(characteristic.getProperties() & BluetoothGattCharacteristic.PROPERTY_READ) ==BluetoothGattCharacteristic.PROPERTY_READ );
                map.put("write",((characteristic.getProperties() & BluetoothGattCharacteristic.PROPERTY_WRITE) ==BluetoothGattCharacteristic.PROPERTY_WRITE) || (
                        (characteristic.getProperties() & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) ==BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE
                        ) );
                map.put("notify",(characteristic.getProperties() & BluetoothGattCharacteristic.PROPERTY_NOTIFY) ==BluetoothGattCharacteristic.PROPERTY_NOTIFY );
                map.put("indicate",(characteristic.getProperties() & BluetoothGattCharacteristic.PROPERTY_INDICATE) ==BluetoothGattCharacteristic.PROPERTY_INDICATE );
                arr.add(map);
            }
            Map map = new HashMap();
            map.put("characteristics",arr);
            promise.success(map);

        } catch (BluetoothException e) {
            retToCallback(e.ret, promise);
        }
    }

    protected DeviceAdapter getConnectedDevice(String deviceId) throws BluetoothException {
        DeviceAdapter deviceAdapter = adapter.getConnectedDevice(deviceId);
        if (deviceAdapter == null) {
            throw new BluetoothException(BluetoothAdapterResult.BluetoothAdapterResultDeviceNotConnected);
        }

        return deviceAdapter;

    }


    public synchronized void getBLEDeviceServices(Map data, final Result promise) {
        String deviceId = (String) data.get("deviceId");
        if (deviceId == null) {
            retToCallback(BluetoothAdapterResult.BluetoothAdapterResultNotInit, promise);
            return;
        }
        DeviceAdapter deviceAdapter = null;
        try {
            deviceAdapter = getConnectedDevice(deviceId);
            deviceAdapter.getServices(new DeviceAdapter.GetServicesListener() {
                @Override
                public void onGetServices(final List<BluetoothGattService> services, final boolean success) {
                   runOnUIThread(new Runnable() {
                       @Override
                       public void run() {
                           if (success) {
                               List arr = new ArrayList();
                               for (BluetoothGattService service : services) {
                                   Map map = new HashMap();
                                   map.put("uuid", Utils.getUuidOfService(service));
                                   map.put("isPrimary",true);
                                   arr.add(map);
                               }
                               Map<String,Object> data = new HashMap<>();
                               data.put("services",arr);
                               promise.success(data);
                           } else {
                               processError(SYSTEM_ERROR, "Cannot get services", promise);
                           }
                       }
                   });
                }
            });
        } catch (BluetoothException e) {
            retToCallback(e.ret, promise);
        }

    }



    public synchronized void notifyBLECharacteristicValueChange(Map data, final Result promise) {
        String deviceId = (String) data.get("deviceId");
        if (deviceId == null) {
            retToCallback(BluetoothAdapterResult.BluetoothAdapterResultNotInit, promise);
            return;
        }
        try {
            String serviceId = (String) data.get("serviceId");
            String characteristicId = (String) data.get("characteristicId");
            boolean notify = (Boolean) data.get("state");
            adapter.setNotify(deviceId,serviceId,characteristicId,notify, new CharacteristicActionListener() {
                @Override
                public void onResult(DeviceAdapter device, BluetoothGattCharacteristic characteristic, final boolean success) {
                    runOnUIThread(new Runnable() {
                        @Override
                        public void run() {
                            if (success) {
                                promise.success(new HashMap<String,Object>());
                            } else {
                                processError(SYSTEM_ERROR, "SetNotify value failed", promise);
                            }
                        }
                    });
                }
            });
            //promise.success(new HashMap<String,Object>());
        } catch (BluetoothException e) {
            retToCallback(e.ret, promise);
        }
    }



    private void processError(final String code, final String message, final Result promise) {

       runOnUIThread(new Runnable() {
           @Override
           public void run() {
               Map map = new HashMap();
               map.put("code", code);
               map.put("message", message);
               promise.success(map);
           }
       });
    }

    private void retToCallback(final BluetoothAdapterResult ret, final Result promise) {
        switch (ret) {
            case BluetoothAdapterResultNotInit:
                processError(NOT_INIT, "Not initialized", promise);
                break;
            case BluetoothAdapterResultDeviceNotFound:
                processError(NO_DEVICE, "Cannot find the device", promise);
                break;
            case BluetoothAdapterResultDeviceNotConnected:
                processError(NO_CONNECTION, "The device is not connected", promise);
                break;
            case BluetoothAdapterResultServiceNotFound:
                processError(NO_SERVICE, "Cannot find the service", promise);
                break;
            case BluetoothAdapterResultCharacteristicsNotFound:
                processError(NO_CHARACTERISTIC, "Cannot find the characteristic", promise);
                break;
            case BluetoothAdapterResultCharacteristicsPropertyNotSupport:
                processError(PROPERTY_NOT_SUPPOTT, "Property is not supported", promise);
                break;
        }

    }


    public synchronized void closeBluetoothAdapter(Result promise) {
        adapter.close();
        promise.success(new HashMap<String,Object>());
    }


    public synchronized void closeBLEConnection(Map data, Result promise) {
        String deviceId = (String) data.get("deviceId");
        if (deviceId == null) {
            retToCallback(BluetoothAdapterResult.BluetoothAdapterResultNotInit, promise);
            return;
        }
        if (BluetoothAdapterResult.BluetoothAdapterResultOk != adapter.disconnectDevice(deviceId)) {
            retToCallback(BluetoothAdapterResult.BluetoothAdapterResultNotInit, promise);
            return;
        }
        //返回关闭
        promise.success(new HashMap<String,Object>());
    }


    public synchronized void createBLEConnection(Map data, final Result promise) {
        String deviceId = (String) data.get("deviceId");
        if (deviceId == null) {
            retToCallback(BluetoothAdapterResult.BluetoothAdapterResultNotInit, promise);
            return;
        }
        if (BluetoothAdapterResult.BluetoothAdapterResultOk != adapter.connectDevice(deviceId, new ConnectionListener() {
            @Override
            public void onDeviceConnected(final DeviceAdapter device, boolean success) {
                if(success){

                    runOnUIThread(new Runnable() {
                        @Override
                        public void run() {
                            Map map = new HashMap();
                            map.put("deviceId", device.getDeviceId());
                            promise.success(map);

                        }
                    });
                }else{
                    processError(CONNECTION_FAIL, "Connect to device failed", promise);
                }
            }
        })) {
            retToCallback(BluetoothAdapterResult.BluetoothAdapterResultNotInit, promise);
            return;
        }

    }


    @Override
    public synchronized void onDeviceConnected(final DeviceAdapter device) {
       runOnUIThread(new Runnable() {
           @Override
           public void run() {

               dispatchStateChange(device.getDeviceId(), true);
           }
       });

    }

    @Override
    public synchronized void onDeviceConnectFailed(final DeviceAdapter device) {
       runOnUIThread(new Runnable() {
           @Override
           public void run() {
               dispatchStateChange(device.getDeviceId(), false);
           }
       });
    }







    @Override
    public synchronized void onCharacteristicChanged(
            final DeviceAdapter device, final BluetoothGattCharacteristic characteristic) {
      runOnUIThread(new Runnable() {
          @Override
          public void run() {
              Map map = new HashMap();
              map.put("deviceId", device.getDeviceId());
              map.put("serviceId", Utils.getUuidOfService(characteristic.getService()));
              map.put("characteristicId", Utils.getUuidOfCharacteristic(characteristic));
              map.put("value", HexUtil.encodeHexStr(characteristic.getValue()));

              channel.invokeMethod("valueUpdate", map);
          }
      });
    }


    @Override
    public synchronized void onDeviceDisconnected(final DeviceAdapter device) {
        dispatchStateChange(device.getDeviceId(), false);
    }

    private void dispatchStateChange(final String deviceId, final boolean connected) {
        runOnUIThread(new Runnable() {
            @Override
            public void run() {
                Map map = new HashMap();
                map.put("deviceId", deviceId);
                map.put("connected", connected);
                channel.invokeMethod("stateChange", map);
            }
        });
    }

    @Override
    public synchronized void onDeviceFound(final DeviceAdapter device) {
        Log.d("BLE",String.format("found device %s",device.getName()));

        channel.invokeMethod("foundDevice", deviceToMap(device));
    }

    private Map deviceToMap(DeviceAdapter device){
        Map map = new HashMap();
        map.put("deviceId", Utils.getDeviceId(device.getDevice()));
        map.put("name", device.getName() == null ? "" : device.getName());
        map.put("RSSI",device.getRssi());
        return map;
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
//        if (requestCode == REQUEST_CODE_ACCESS_COARSE_LOCATION) {
//            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
//                //用户允许改权限，0表示允许，-1表示拒绝 PERMISSION_GRANTED = 0， PERMISSION_DENIED = -1
//                //permission was granted, yay! Do the contacts-related task you need to do.
//                //这里进行授权被允许的处理
//            } else {
//                //permission denied, boo! Disable the functionality that depends on this permission.
//                //这里进行权限被拒绝的处理
//            }
//
//            return true;
//        } else {
//
//            return false;
//        }
        return false;
    }
}
