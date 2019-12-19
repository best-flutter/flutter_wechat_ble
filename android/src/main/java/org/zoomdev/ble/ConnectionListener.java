package org.zoomdev.ble;

public interface ConnectionListener {
    void onDeviceConnected(DeviceAdapter device,boolean success);
}
