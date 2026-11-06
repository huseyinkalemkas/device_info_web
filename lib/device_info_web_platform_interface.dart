import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'device_info_web_method_channel.dart';
import 'src/models.dart';

abstract class DeviceInfoWebPlatform extends PlatformInterface {
  DeviceInfoWebPlatform() : super(token: _token);

  static final Object _token = Object();

  static DeviceInfoWebPlatform _instance = MethodChannelDeviceInfoWeb();

  static DeviceInfoWebPlatform get instance => _instance;

  static set instance(DeviceInfoWebPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<BrowserDeviceInfo> getBrowserDeviceInfo() {
    throw UnimplementedError('getBrowserDeviceInfo()');
  }

  Future<bool> getBluetoothAvailability() {
    throw UnimplementedError('getBluetoothAvailability()');
  }

  /// Yakındaki Bluetooth LE cihazlarını arar. Wi-Fi aramaz.
  ///
  /// Web'de kullanıcı tıklamasıyla aynı turda çalışmalıdır.
  Future<List<BleDevice>> findBluetoothDevices(
    String namePrefix, [
    void Function(BleDevice device)? onDiscovered,
  ]) {
    throw UnimplementedError('findBluetoothDevices()');
  }

  /// Web'de kullanıcı tıklamasıyla aynı turda çalışmalıdır.
  Future<BleDevice> requestDevice(BleDeviceRequest request) {
    throw UnimplementedError('requestDevice()');
  }

  Future<List<BleDevice>> getPermittedDevices() {
    throw UnimplementedError('getPermittedDevices()');
  }

  Future<void> connect(String deviceId) {
    throw UnimplementedError('connect()');
  }

  Future<void> disconnect(String deviceId) {
    throw UnimplementedError('disconnect()');
  }

  Future<GattDeviceInfo> readDeviceInformation(String deviceId) {
    throw UnimplementedError('readDeviceInformation()');
  }

  Future<Uint8List> readCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    throw UnimplementedError('readCharacteristic()');
  }

  Future<void> writeCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List value,
    bool withResponse = true,
  }) {
    throw UnimplementedError('writeCharacteristic()');
  }

  Future<void> startNotifications({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    throw UnimplementedError('startNotifications()');
  }

  Future<void> stopNotifications({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    throw UnimplementedError('stopNotifications()');
  }

  Stream<BleNotification> get notifications {
    throw UnimplementedError('notifications');
  }
}
