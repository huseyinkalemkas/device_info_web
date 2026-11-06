import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'device_info_web_method_channel.dart';
import 'src/web_bluetooth.dart';

/// Web tarafındaki kanal dinleyicisi.
///
/// `requestDevice` kanal mesajına konmaz. Tarayıcı, cihaz penceresini yalnızca
/// tıklamanın aynı turundaki doğrudan çağrıda açar. [registerWith] bu yüzden
/// ayrı bir kanca bağlar; diğer GATT işleri [MethodChannel] üzerinden gelir.
class DeviceInfoWebWeb {
  static void registerWith(Registrar registrar) {
    final session = BluetoothSession.instance;
    MethodChannelDeviceInfoWeb.directRequestDevice = session.requestDevice;
    MethodChannelDeviceInfoWeb.directFindBluetoothDevices =
        (namePrefix, [onDiscovered]) {
          return session.findBluetoothDevices(namePrefix, onDiscovered);
        };

    MethodChannel(
      MethodChannelDeviceInfoWeb.methodChannelName,
      const StandardMethodCodec(),
      registrar,
    ).setMethodCallHandler(handleMethodCall);

    PluginEventChannel<Map<String, Object?>>(
      MethodChannelDeviceInfoWeb.eventChannelName,
      const StandardMethodCodec(),
      registrar,
    ).setController(session.events);
  }

  static Future<dynamic> handleMethodCall(MethodCall call) async {
    final session = BluetoothSession.instance;
    final args = _args(call.arguments);
    switch (call.method) {
      case 'getBrowserDeviceInfo':
        return (await session.browserDeviceInfo()).toMap();
      case 'getBluetoothAvailability':
        return session.availability();
      case 'findBluetoothDevices':
        final prefix = args['namePrefix'];
        final devices = await session.findBluetoothDevices(
          prefix is String ? prefix : '',
        );
        return devices.map((device) => device.toMap()).toList();
      case 'getPermittedDevices':
        final devices = await session.permittedDevices();
        return devices.map((device) => device.toMap()).toList();
      case 'connect':
        await session.connect(_text(args, 'deviceId'));
        return null;
      case 'disconnect':
        session.disconnect(_text(args, 'deviceId'));
        return null;
      case 'readDeviceInformation':
        return (await session.readDeviceInformation(
          _text(args, 'deviceId'),
        )).toMap();
      case 'readCharacteristic':
        return session.readCharacteristic(
          deviceId: _text(args, 'deviceId'),
          serviceUuid: _text(args, 'serviceUuid'),
          characteristicUuid: _text(args, 'characteristicUuid'),
        );
      case 'writeCharacteristic':
        await session.writeCharacteristic(
          deviceId: _text(args, 'deviceId'),
          serviceUuid: _text(args, 'serviceUuid'),
          characteristicUuid: _text(args, 'characteristicUuid'),
          value: _bytes(args['value']),
          withResponse: args['withResponse'] != false,
        );
        return null;
      case 'startNotifications':
        await session.startNotifications(
          deviceId: _text(args, 'deviceId'),
          serviceUuid: _text(args, 'serviceUuid'),
          characteristicUuid: _text(args, 'characteristicUuid'),
        );
        return null;
      case 'stopNotifications':
        await session.stopNotifications(
          deviceId: _text(args, 'deviceId'),
          serviceUuid: _text(args, 'serviceUuid'),
          characteristicUuid: _text(args, 'characteristicUuid'),
        );
        return null;
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: call.method,
        );
    }
  }
}

Map<String, Object?> _args(Object? raw) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

String _text(Map<String, Object?> args, String key) {
  final value = args[key];
  if (value is! String || value.isEmpty) {
    throw PlatformException(code: 'invalid_argument', message: key);
  }
  return value;
}

Uint8List _bytes(Object? value) {
  if (value is Uint8List) return value;
  if (value is List<int>) return Uint8List.fromList(value);
  if (value is List) return Uint8List.fromList(value.cast<int>());
  throw PlatformException(code: 'invalid_argument', message: 'value');
}
