package org.zoomdev.ble;

import android.bluetooth.BluetoothGattCharacteristic;

public interface CharacteristicActionListener {

    void onResult(DeviceAdapter device,BluetoothGattCharacteristic characteristic, boolean success);

}
