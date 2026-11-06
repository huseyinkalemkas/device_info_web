import 'dart:typed_data';

import 'package:device_info_web/device_info_web.dart';
import 'package:device_info_web/device_info_web_method_channel.dart';
import 'package:device_info_web/device_info_web_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeDeviceInfoWebPlatform
    with MockPlatformInterfaceMixin
    implements DeviceInfoWebPlatform {
  @override
  Future<BrowserDeviceInfo> getBrowserDeviceInfo() async {
    return const BrowserDeviceInfo(
      userAgent: 'test-agent',
      platform: 'Test',
      vendor: 'Test',
      language: 'tr',
      languages: ['tr'],
      hardwareConcurrency: 8,
      deviceMemoryGb: 8,
      maxTouchPoints: 0,
      screenWidth: 1920,
      screenHeight: 1080,
      availWidth: 1920,
      availHeight: 1040,
      devicePixelRatio: 1,
      mobile: false,
      uaPlatform: 'Windows',
      brands: ['Test'],
      architecture: 'x86',
      model: '',
      platformVersion: '15',
      bitness: '64',
    );
  }

  @override
  Future<bool> getBluetoothAvailability() async => true;

  @override
  Future<List<BleDevice>> findBluetoothDevices(
    String namePrefix, [
    void Function(BleDevice device)? onDiscovered,
  ]) async {
    const device = BleDevice(id: 'dev-1', name: 'Sensör', connected: false);
    onDiscovered?.call(device);
    return const [device];
  }

  @override
  Future<BleDevice> requestDevice(BleDeviceRequest request) async {
    return const BleDevice(id: 'dev-1', name: 'Sensör', connected: false);
  }

  @override
  Future<List<BleDevice>> getPermittedDevices() async => const [];

  @override
  Future<void> connect(String deviceId) async {}

  @override
  Future<void> disconnect(String deviceId) async {}

  @override
  Future<GattDeviceInfo> readDeviceInformation(String deviceId) async {
    return const GattDeviceInfo(manufacturer: 'Acme', model: 'A1');
  }

  @override
  Future<Uint8List> readCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> writeCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List value,
    bool withResponse = true,
  }) async {}

  @override
  Future<void> startNotifications({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {}

  @override
  Future<void> stopNotifications({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {}

  @override
  Stream<BleNotification> get notifications => const Stream.empty();
}

void main() {
  final DeviceInfoWebPlatform initialPlatform = DeviceInfoWebPlatform.instance;

  tearDown(() {
    DeviceInfoWebPlatform.instance = initialPlatform;
  });

  test('varsayılan örnek metot kanalıdır', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDeviceInfoWeb>());
  });

  test('tarayıcı bilgisi platformdan okunur', () async {
    DeviceInfoWebPlatform.instance = FakeDeviceInfoWebPlatform();
    final info = await DeviceInfoWeb().getBrowserDeviceInfo();
    expect(info.userAgent, 'test-agent');
    expect(info.hardwareConcurrency, 8);
  });

  test('yalnızca bluetooth listesi platformdan okunur', () async {
    DeviceInfoWebPlatform.instance = FakeDeviceInfoWebPlatform();
    final devices = await DeviceInfoWeb().findBluetoothDevices();
    expect(devices.single.name, 'Sensör');
  });

  test('cihaz seçimi ve GATT bilgisi', () async {
    DeviceInfoWebPlatform.instance = FakeDeviceInfoWebPlatform();
    final plugin = DeviceInfoWeb();
    final device = await plugin.requestDevice();
    final gatt = await plugin.readDeviceInformation(device.id);
    expect(device.name, 'Sensör');
    expect(gatt.manufacturer, 'Acme');
  });

  test('boş süzgeç reddedilir', () {
    expect(() => BleFilter(), throwsArgumentError);
  });

  test('bildirim haritası çözülür', () {
    final notification = BleNotification.fromMap({
      'kind': 'discovered',
      'deviceId': 'dev-1',
      'name': 'Kulaklık',
    });
    expect(notification.kind, BleNotificationKind.discovered);
    expect(notification.name, 'Kulaklık');
  });
}
