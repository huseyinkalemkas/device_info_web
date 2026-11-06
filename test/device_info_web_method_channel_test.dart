import 'package:device_info_web/device_info_web.dart';
import 'package:device_info_web/device_info_web_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelDeviceInfoWeb.methodChannelName);
  const events = EventChannel(MethodChannelDeviceInfoWeb.eventChannelName);
  late MethodChannelDeviceInfoWeb platform;

  setUp(() {
    platform = MethodChannelDeviceInfoWeb();
    MethodChannelDeviceInfoWeb.directRequestDevice = null;
    MethodChannelDeviceInfoWeb.directFindBluetoothDevices = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getBrowserDeviceInfo':
              return {
                'userAgent': 'channel-agent',
                'platform': 'Win',
                'vendor': '',
                'language': 'tr',
                'languages': ['tr'],
                'hardwareConcurrency': 4,
                'maxTouchPoints': 1,
                'screenWidth': 800,
                'screenHeight': 600,
                'availWidth': 800,
                'availHeight': 600,
                'devicePixelRatio': 2,
              };
            case 'getBluetoothAvailability':
              return true;
            case 'getPermittedDevices':
              return [
                {'id': 'saved', 'name': 'Kayıtlı', 'connected': false},
              ];
            case 'readCharacteristic':
              return Uint8List.fromList([9]);
            case 'readDeviceInformation':
              return {'manufacturer': 'Acme', 'model': 'M1'};
            default:
              return null;
          }
        });
  });

  tearDown(() {
    MethodChannelDeviceInfoWeb.directRequestDevice = null;
    MethodChannelDeviceInfoWeb.directFindBluetoothDevices = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(events.name, null);
  });

  test('tarayıcı bilgisi kanaldan çözülür', () async {
    final info = await platform.getBrowserDeviceInfo();
    expect(info.userAgent, 'channel-agent');
    expect(info.devicePixelRatio, 2);
    expect(info.languages, ['tr']);
  });

  test('izinli cihaz listesi kanaldan çözülür', () async {
    final devices = await platform.getPermittedDevices();
    expect(devices.single.id, 'saved');
    expect(devices.single.name, 'Kayıtlı');
  });

  test('karakteristik baytları kanaldan çözülür', () async {
    final bytes = await platform.readCharacteristic(
      deviceId: 'saved',
      serviceUuid: GattUuid.battery,
      characteristicUuid: '00002a19-0000-1000-8000-00805f9b34fb',
    );
    expect(bytes, [9]);
  });

  test('cihaz seçimi web kancasına gider', () async {
    var calls = 0;
    MethodChannelDeviceInfoWeb.directRequestDevice = (request) {
      calls += 1;
      expect(request.optionalServices, contains(GattUuid.deviceInformation));
      return Future<BleDevice>.value(
        const BleDevice(id: 'picked', name: 'Kalem', connected: false),
      );
    };

    final device = await platform.requestDevice(const BleDeviceRequest());
    expect(calls, 1);
    expect(device.id, 'picked');
  });

  test('bluetooth araması web kancasına gider', () async {
    var calls = 0;
    var seenLive = false;
    MethodChannelDeviceInfoWeb.directFindBluetoothDevices =
        (namePrefix, [onDiscovered]) {
          calls += 1;
          expect(namePrefix, 'Kulak');
          const device = BleDevice(
            id: 'ble-1',
            name: 'Kulaklık',
            connected: false,
          );
          onDiscovered?.call(device);
          seenLive = true;
          return Future<List<BleDevice>>.value(const [device]);
        };

    final devices = await platform.findBluetoothDevices('Kulak', (device) {
      expect(device.name, 'Kulaklık');
    });
    expect(calls, 1);
    expect(seenLive, isTrue);
    expect(devices.single.name, 'Kulaklık');
  });
}
