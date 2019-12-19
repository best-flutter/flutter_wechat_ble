package org.zoomdev.ble;

import java.util.Arrays;

public class HexUtil {
    private static final char[] DIGITS_LOWER = new char[]{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
    private static final char[] DIGITS_UPPER = new char[]{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

    public HexUtil() {
    }

    public static short toShort(byte[] data, int start) {
        return (short) (data[start + 1] << 8 & '\uff00' | data[start] & 255);
    }

    public static int toInt(byte[] data, int start) {
        return data[start + 3] << 24 & -16777216 | data[start + 2] << 16 & 16711680 | data[start + 1] << 8 & '\uff00' | data[start] & 255;
    }

    public static byte[] copy(byte[] bytes, int dataStart, short len) {
        return Arrays.copyOfRange(bytes, dataStart, len);
    }

    public static char[] encodeHex(byte[] data) {
        return encodeHex(data, true);
    }

    public static char[] encodeHex(byte[] data, boolean toLowerCase) {
        return encodeHex(data, data.length, toLowerCase ? DIGITS_LOWER : DIGITS_UPPER);
    }

    protected static char[] encodeHex(byte[] data, int l, char[] toDigits) {
        char[] out = new char[l << 1];
        int i = 0;

        for (int var5 = 0; i < l; ++i) {
            out[var5++] = toDigits[(240 & data[i]) >>> 4];
            out[var5++] = toDigits[15 & data[i]];
        }

        return out;
    }

    public static String encodeHexStr(byte[] data) {
        return encodeHexStr(data, true);
    }

    public static String encodeHexStr(byte[] data, int len) {
        return encodeHexStr(data, len, true);
    }

    public static String encodeHexStr(byte[] data, boolean toLowerCase) {
        return encodeHexStr(data, data.length, toLowerCase ? DIGITS_LOWER : DIGITS_UPPER);
    }

    public static String encodeHexStr(byte[] data, int len, boolean toLowerCase) {
        return encodeHexStr(data, len, toLowerCase ? DIGITS_LOWER : DIGITS_UPPER);
    }

    protected static String encodeHexStr(byte[] data, int len, char[] toDigits) {
        return new String(encodeHex(data, len, toDigits));
    }

    public static byte[] decodeHex(String data) {
        return decodeHex(data.toCharArray());
    }

    public static byte[] decodeHex(char[] data) {
        int len = data.length;
        if ((len & 1) != 0) {
            throw new RuntimeException("Odd number of characters.");
        } else {
            byte[] out = new byte[len >> 1];
            int i = 0;

            for (int j = 0; j < len; ++i) {
                int f = toDigit(data[j], j) << 4;
                ++j;
                f |= toDigit(data[j], j);
                ++j;
                out[i] = (byte) (f & 255);
            }

            return out;
        }
    }

    protected static int toDigit(char ch, int index) {
        int digit = Character.digit(ch, 16);
        if (digit == -1) {
            throw new RuntimeException("Illegal hexadecimal character " + ch + " at index " + index);
        } else {
            return digit;
        }
    }

    public static String int2HexStr(int value, int len) {
        String result = Integer.toHexString(value);
        int i = result.length();
        if (i > len) {
            return result.substring(i - len);
        } else if (i >= len) {
            return result;
        } else {
            StringBuilder sb = new StringBuilder(len);

            for (int j = i; j < len; ++j) {
                sb.append('0');
            }

            sb.append(result);
            return sb.toString();
        }
    }

    public static int toInt(byte[] b, int s, int n) {
        int ret = 0;
        int e = s + n;

        for (int i = s; i < e; ++i) {
            ret <<= 8;
            ret |= b[i] & 255;
        }

        return ret;
    }

    public static String formatHex(String str) {
        int len = str.length();
        StringBuilder sb = new StringBuilder();

        for (int i = 0; i < len; i += 8) {
            sb.append(str.substring(i, Math.min(i + 8, str.length())));
            sb.append(' ');
        }

        return sb.toString();
    }
}
