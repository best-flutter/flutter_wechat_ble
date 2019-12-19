package org.zoomdev.ble;

public class BluetoothException extends Exception {

    public final BluetoothAdapterResult ret;

    BluetoothException(BluetoothAdapterResult ret, String message) {
        super(message);
        this.ret = ret;
    }

    public BluetoothException(BluetoothAdapterResult ret) {
        super();
        this.ret = ret;
    }




}
