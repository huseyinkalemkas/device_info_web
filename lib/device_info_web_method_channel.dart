import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'device_info_web_platform_interface.dart';
import 'src/models.dart';

/// Web eklentisine giden metot ve olay kanalları.
class MethodChannelDeviceInfoWeb extends DeviceInfoWebPlatform {
  static const methodChannelName = 'device_info_web';
  static const eventChannelName = 'device_info_web/events';

  /// Web kaydı bu kancayı doldurur.
  ///
  /// Cihaz penceresi, kancanın aynı çağrı turunda `navigator.bluetooth.requestDevice`
  /// demesine bağlıdır. Bu alanın önüne `await` koyma.
  static Future<BleDevice> Function(BleDeviceRequest request)?
  directRequestDevice;

  /// Bluetooth taraması da tıklamayla aynı turda başlar.
  static Future<List<BleDevice>> Function(
    String namePrefix, [
    void Function(BleDevice device)? onDiscovered,
  ])?
  directFindBluetoothDevices;

  @visibleForTesting
  final methodChannel = const MethodChannel(methodChannelName);

  @visibleForTesting
  final eventChannel = const EventChannel(eventChannelName);

  @override
  Future<BrowserDeviceInfo> getBrowserDeviceInfo() async {
    final raw = await methodChannel.invokeMapMethod<Object?, Object?>(
      'getBrowserDeviceInfo',
    );
    return BrowserDeviceInfo.fromMap(_stringMap(raw));
  }

  @override
  Future<bool> getBluetoothAvailability() async {
    final available = await methodChannel.invokeMethod<bool>(
      'getBluetoothAvailability',
    );
    return available ?? false;
  }

  @override
  Future<List<BleDevice>> findBluetoothDevices(
    String namePrefix, [
    void Function(BleDevice device)? onDiscovered,
  ]) {
    final direct = directFindBluetoothDevices;
    if (direct != null) {
      return direct(namePrefix, onDiscovered);
    }
    return _findBluetoothDevicesOverChannel(namePrefix, onDiscovered);
  }

  Future<List<BleDevice>> _findBluetoothDevicesOverChannel(
    String namePrefix,
    void Function(BleDevice device)? onDiscovered,
  ) async {
    final subscription = onDiscovered == null
        ? null
        : notifications.listen((event) {
            if (event.kind != BleNotificationKind.discovered) return;
            onDiscovered(
              BleDevice(
                id: event.deviceId,
                name: event.name,
                connected: false,
              ),
            );
          });
    try {
      final raw = await methodChannel.invokeMethod<Object?>(
        'findBluetoothDevices',
        {'namePrefix': namePrefix},
      );
      if (raw is! List) return const [];
      return raw
          .map((item) => BleDevice.fromMap(_stringMap(item as Map?)))
          .toList();
    } finally {
      await subscription?.cancel();
    }
  }

  @override
  Future<BleDevice> requestDevice(BleDeviceRequest request) {
    final direct = directRequestDevice;
    if (direct != null) {
      return direct(request);
    }
    return _requestDeviceOverChannel(request);
  }

  Future<BleDevice> _requestDeviceOverChannel(BleDeviceRequest request) async {
    final raw = await methodChannel.invokeMapMethod<Object?, Object?>(
      'requestDevice',
      request.toMap(),
    );
    return BleDevice.fromMap(_stringMap(raw));
  }

  @override
  Future<List<BleDevice>> getPermittedDevices() async {
    final raw = await methodChannel.invokeMethod<Object?>('getPermittedDevices');
    if (raw is! List) return const [];
    return raw
        .map((item) => BleDevice.fromMap(_stringMap(item as Map?)))
        .toList();
  }

  @override
  Future<void> connect(String deviceId) {
    return methodChannel.invokeMethod<void>('connect', {'deviceId': deviceId});
  }

  @override
  Future<void> disconnect(String deviceId) {
    return methodChannel.invokeMethod<void>('disconnect', {
      'deviceId': deviceId,
    });
  }

  @override
  Future<GattDeviceInfo> readDeviceInformation(String deviceId) async {
    final raw = await methodChannel.invokeMapMethod<Object?, Object?>(
      'readDeviceInformation',
      {'deviceId': deviceId},
    );
    return GattDeviceInfo.fromMap(_stringMap(raw));
  }

  @override
  Future<Uint8List> readCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final raw = await methodChannel.invokeMethod<Object?>('readCharacteristic', {
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });
    return _bytes(raw);
  }

  @override
  Future<void> writeCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List value,
    bool withResponse = true,
  }) {
    return methodChannel.invokeMethod<void>('writeCharacteristic', {
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
      'value': value,
      'withResponse': withResponse,
    });
  }

  @override
  Future<void> startNotifications({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return methodChannel.invokeMethod<void>('startNotifications', {
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });
  }

  @override
  Future<void> stopNotifications({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return methodChannel.invokeMethod<void>('stopNotifications', {
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });
  }

  @override
  late final Stream<BleNotification> notifications = eventChannel
      .receiveBroadcastStream()
      .map((event) => BleNotification.fromMap(_stringMap(event as Map?)));
}

Map<String, Object?> _stringMap(Map? raw) {
  if (raw == null) return const {};
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

Uint8List _bytes(Object? value) {
  if (value is Uint8List) return value;
  if (value is List<int>) return Uint8List.fromList(value);
  if (value is List) {
    return Uint8List.fromList(value.cast<int>());
  }
  return Uint8List(0);
}
