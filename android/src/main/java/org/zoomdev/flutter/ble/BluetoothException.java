package org.zoomdev.flutter.ble;

class BluetoothException extends Exception {

    protected final BluetoothAdapterResult ret;

    BluetoothException(BluetoothAdapterResult ret, String message) {
        super(message);
        this.ret = ret;
    }

    public BluetoothException(BluetoothAdapterResult ret) {
        super();
        this.ret = ret;
    }




}
