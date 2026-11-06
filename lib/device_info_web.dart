import 'dart:typed_data';

import 'device_info_web_platform_interface.dart';
import 'src/models.dart';

export 'src/gatt_uuids.dart';
export 'src/models.dart';

/// Web tarayıcı bilgisi ve BLE GATT yönetimi.
class DeviceInfoWeb {
  DeviceInfoWeb({DeviceInfoWebPlatform? platform})
    : _platform = platform ?? DeviceInfoWebPlatform.instance;

  final DeviceInfoWebPlatform _platform;

  /// `navigator` ve ekran. Bluetooth izni istemez.
  Future<BrowserDeviceInfo> getBrowserDeviceInfo() {
    return _platform.getBrowserDeviceInfo();
  }

  /// Adaptör var mı. API yoksa `false`.
  Future<bool> getBluetoothAvailability() {
    return _platform.getBluetoothAvailability();
  }

  /// Yakındaki Bluetooth LE cihazlarını arar.
  ///
  /// Wi-Fi ağlarına bakmaz. Düğmenin `onPressed` içinden, araya başka `await`
  /// koymadan çağır.
  /// [namePrefix] doluysa tarama ve liste yalnızca bu adla başlayan
  /// Bluetooth cihazlarını alır.
  Future<List<BleDevice>> findBluetoothDevices({
    String namePrefix = '',
    void Function(BleDevice device)? onDiscovered,
  }) {
    return _platform.findBluetoothDevices(namePrefix, onDiscovered);
  }

  /// Cihaz penceresini açar.
  ///
  /// Bunu bir düğmenin `onPressed` içinden, araya başka `await` koymadan çağır.
  Future<BleDevice> requestDevice([
    BleDeviceRequest request = const BleDeviceRequest(),
  ]) {
    return _platform.requestDevice(request);
  }

  /// Bu kökenin daha önce izin aldığı cihazlar.
  Future<List<BleDevice>> getPermittedDevices() {
    return _platform.getPermittedDevices();
  }

  Future<void> connect(String deviceId) => _platform.connect(deviceId);

  Future<void> disconnect(String deviceId) => _platform.disconnect(deviceId);

  /// `0x180A` Device Information karakteristiklerini okur.
  ///
  /// Servis, [requestDevice] sırasında `optionalServices` içinde istenmiş olmalı.
  Future<GattDeviceInfo> readDeviceInformation(String deviceId) {
    return _platform.readDeviceInformation(deviceId);
  }

  Future<Uint8List> readCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return _platform.readCharacteristic(
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );
  }

  Future<void> writeCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List value,
    bool withResponse = true,
  }) {
    return _platform.writeCharacteristic(
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      value: value,
      withResponse: withResponse,
    );
  }

  Future<void> startNotifications({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return _platform.startNotifications(
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );
  }

  Future<void> stopNotifications({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return _platform.stopNotifications(
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );
  }

  /// Bildirim baytları ve GATT kopmaları.
  Stream<BleNotification> get notifications => _platform.notifications;
}
