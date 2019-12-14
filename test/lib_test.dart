import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';

void main() {
  test("test hex", () {
    List<int> hexValue = [0x1, 0x2, 0x3, 0xe, 0xc, 0xb];
    expect(HexUtils.encodeHex(hexValue), "0102030e0c0b");
    expect(HexUtils.decodeHex("0102030e0c0b"), hexValue);
  });
}
