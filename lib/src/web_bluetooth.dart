// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'gatt_uuids.dart';
import 'js_values.dart';
import 'models.dart';

extension type NavigatorBluetooth(web.Navigator _) implements web.Navigator {
  external Bluetooth? get bluetooth;
}

extension type OptionalNavigator(JSObject _) implements JSObject {
  external JSAny? get deviceMemory;
  external JSAny? get userAgentData;
}

extension type Bluetooth._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> getAvailability();
  external JSPromise<JSArray<BluetoothDevice>> getDevices();
  external JSPromise<BluetoothDevice> requestDevice(JSAny? options);
  external JSPromise<BluetoothLeScan> requestLEScan(JSAny? options);
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
  external set onadvertisementreceived(JSAny? handler);
}

extension type BluetoothLeScan._(JSObject _) implements JSObject {
  external void stop();
}

extension type BluetoothAdvertisingEvent(JSObject _) implements JSObject {
  external BluetoothDevice get device;
  external String? get name;
}

extension type BluetoothDevice._(JSObject _) implements JSObject {
  external String get id;
  external String? get name;
  external BluetoothRemoteGattServer? get gatt;
  external set ongattserverdisconnected(JSAny? handler);
}

extension type BluetoothRemoteGattServer._(JSObject _) implements JSObject {
  external bool get connected;
  external JSPromise<BluetoothRemoteGattServer> connect();
  external void disconnect();
  external JSPromise<BluetoothRemoteGattService> getPrimaryService(
    String service,
  );
}

extension type BluetoothRemoteGattService._(JSObject _) implements JSObject {
  external JSPromise<BluetoothRemoteGattCharacteristic> getCharacteristic(
    String characteristic,
  );
}

extension type BluetoothRemoteGattCharacteristic._(JSObject _)
    implements JSObject {
  external JSDataView? get value;
  external JSPromise<JSDataView> readValue();
  external JSPromise<JSAny?> writeValue(JSUint8Array value);
  external JSPromise<JSAny?> writeValueWithResponse(JSUint8Array value);
  external JSPromise<JSAny?> writeValueWithoutResponse(JSUint8Array value);
  external JSPromise<BluetoothRemoteGattCharacteristic> startNotifications();
  external JSPromise<BluetoothRemoteGattCharacteristic> stopNotifications();
  external set oncharacteristicvaluechanged(JSAny? handler);
}

extension type NavigatorUaData(JSObject _) implements JSObject {
  external JSBoolean get mobile;
  external String get platform;
  external JSArray<JSObject> get brands;
  external JSPromise<JSObject> getHighEntropyValues(JSArray<JSString> hints);
}

/// Seçilen cihazları tutar ve GATT çağrılarını tarayıcıya iletir.
class BluetoothSession {
  BluetoothSession._();

  static final BluetoothSession instance = BluetoothSession._();

  final StreamController<Map<String, Object?>> events =
      StreamController<Map<String, Object?>>.broadcast();

  final Map<String, BluetoothDevice> _devices = {};
  final Set<String> _disconnectHooks = {};
  final Map<String, BluetoothRemoteGattCharacteristic> _notifications = {};
  BluetoothLeScan? _activeScan;
  JSFunction? _advertisementListener;
  var _scanGeneration = 0;

  Bluetooth? get _bluetooth {
    try {
      return NavigatorBluetooth(web.window.navigator).bluetooth;
    } on Object {
      return null;
    }
  }

  Future<BrowserDeviceInfo> browserDeviceInfo() async {
    final navigator = web.window.navigator;
    final screen = web.window.screen;
    final loose = OptionalNavigator(navigator as JSObject);
    final hints = await _clientHints(loose.userAgentData);
    return BrowserDeviceInfo(
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      vendor: navigator.vendor,
      language: navigator.language,
      languages: navigator.languages.toDart
          .map((language) => language.toDart)
          .toList(),
      hardwareConcurrency: navigator.hardwareConcurrency,
      deviceMemoryGb: jsDouble(loose.deviceMemory),
      maxTouchPoints: navigator.maxTouchPoints,
      screenWidth: screen.width,
      screenHeight: screen.height,
      availWidth: screen.availWidth,
      availHeight: screen.availHeight,
      devicePixelRatio: web.window.devicePixelRatio,
      mobile: hints.mobile,
      uaPlatform: hints.platform,
      brands: hints.brands,
      architecture: hints.architecture,
      model: hints.model,
      platformVersion: hints.platformVersion,
      bitness: hints.bitness,
    );
  }

  Future<bool> availability() async {
    final bluetooth = _bluetooth;
    if (bluetooth == null) return false;
    try {
      final available = await bluetooth.getAvailability().toDart;
      return available.toDart;
    } on Object {
      return false;
    }
  }

  /// Yakındaki Bluetooth LE ilanlarını toplar. Wi-Fi sorgulanmaz.
  ///
  /// [onDiscovered] her yeni Bluetooth cihazında, tarama bitmeden çağrılır.
  /// `requestLEScan` bu metodun ilk bekleyişinden önce çağrılır.
  Future<List<BleDevice>> findBluetoothDevices(
    String namePrefix, [
    void Function(BleDevice device)? onDiscovered,
  ]) async {
    final prefix = namePrefix.trim();
    final bluetooth = _requireBluetooth();
    if (!jsHas(bluetooth as JSObject, 'requestLEScan')) {
      final device = await requestDevice(
        BleDeviceRequest(
          filters: prefix.isEmpty ? const [] : [BleFilter(namePrefix: prefix)],
          optionalServices: const [
            GattUuid.deviceInformation,
            GattUuid.battery,
          ],
        ),
      );
      _publish(device, onDiscovered);
      return [device];
    }

    _stopAdvertisements(bluetooth);
    _activeScan?.stop();
    final generation = ++_scanGeneration;
    final found = <String, BleDevice>{};
    final scan = await _guard(
      () => bluetooth.requestLEScan(_leScanOptions(prefix)).toDart,
    );
    _activeScan = scan;
    _advertisementListener = ((JSObject event) {
      final advertised = BluetoothAdvertisingEvent(event);
      final device = advertised.device;
      if (device.id.isEmpty) return;
      _remember(device);
      final described = _describe(device);
      final listed = BleDevice(
        id: described.id,
        name: described.name ?? _present(advertised.name),
        connected: described.connected,
      );
      final isNew = !found.containsKey(device.id);
      found[device.id] = listed;
      if (isNew) _publish(listed, onDiscovered);
    }).toJS;
    bluetooth.addEventListener(
      'advertisementreceived',
      _advertisementListener!,
    );

    await Future<void>.delayed(const Duration(seconds: 8));
    scan.stop();
    if (generation == _scanGeneration) {
      _stopAdvertisements(bluetooth);
      _activeScan = null;
    }
    return found.values.toList();
  }

  void _publish(
    BleDevice device,
    void Function(BleDevice device)? onDiscovered,
  ) {
    onDiscovered?.call(device);
    if (events.isClosed) return;
    events.add({
      'kind': 'discovered',
      'deviceId': device.id,
      'name': device.name,
    });
  }

  void _stopAdvertisements(Bluetooth bluetooth) {
    final listener = _advertisementListener;
    if (listener == null) return;
    bluetooth.removeEventListener('advertisementreceived', listener);
    _advertisementListener = null;
  }

  /// JS `requestDevice` bu metodun ilk bekleyişinden önce çağrılır.
  Future<BleDevice> requestDevice(BleDeviceRequest request) async {
    final bluetooth = _requireBluetooth();
    final device = await _guard(
      () => bluetooth.requestDevice(_requestOptions(request)).toDart,
    );
    _remember(device);
    return _describe(device);
  }

  Future<List<BleDevice>> permittedDevices() async {
    final bluetooth = _requireBluetooth();
    final devices = await _guard(() => bluetooth.getDevices().toDart);
    return devices.toDart.map((device) {
      _remember(device);
      return _describe(device);
    }).toList();
  }

  Future<void> connect(String deviceId) async {
    final gatt = _requireGatt(deviceId);
    if (gatt.connected) return;
    await _guard(() => gatt.connect().toDart);
  }

  void disconnect(String deviceId) {
    _requireGatt(deviceId).disconnect();
  }

  Future<GattDeviceInfo> readDeviceInformation(String deviceId) async {
    await connect(deviceId);
    final gatt = _requireGatt(deviceId);
    final service = await _guard(
      () => gatt.getPrimaryService(GattUuid.deviceInformation).toDart,
    );
    return GattDeviceInfo(
      manufacturer: await _readText(service, GattUuid.manufacturerName),
      model: await _readText(service, GattUuid.modelNumber),
      serialNumber: await _readText(service, GattUuid.serialNumber),
      firmwareRevision: await _readText(service, GattUuid.firmwareRevision),
      hardwareRevision: await _readText(service, GattUuid.hardwareRevision),
      softwareRevision: await _readText(service, GattUuid.softwareRevision),
    );
  }

  Future<Uint8List> readCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final characteristic = await _characteristic(
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );
    final view = await _guard(() => characteristic.readValue().toDart);
    return _copyBytes(view);
  }

  Future<void> writeCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List value,
    bool withResponse = true,
  }) async {
    final characteristic = await _characteristic(
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );
    final data = value.toJS;
    final object = characteristic as JSObject;
    await _guard(() {
      if (withResponse && jsHas(object, 'writeValueWithResponse')) {
        return characteristic.writeValueWithResponse(data).toDart;
      }
      if (!withResponse && jsHas(object, 'writeValueWithoutResponse')) {
        return characteristic.writeValueWithoutResponse(data).toDart;
      }
      return characteristic.writeValue(data).toDart;
    });
  }

  Future<void> startNotifications({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final characteristic = await _characteristic(
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );
    final key = _notificationKey(deviceId, serviceUuid, characteristicUuid);
    characteristic.oncharacteristicvaluechanged = ((JSAny _) {
      final view = characteristic.value;
      events.add({
        'kind': 'value',
        'deviceId': deviceId,
        'serviceUuid': serviceUuid,
        'characteristicUuid': characteristicUuid,
        'value': view == null ? Uint8List(0) : _copyBytes(view),
      });
    }).toJS;
    await _guard(() => characteristic.startNotifications().toDart);
    _notifications[key] = characteristic;
  }

  Future<void> stopNotifications({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final key = _notificationKey(deviceId, serviceUuid, characteristicUuid);
    final characteristic = _notifications.remove(key);
    if (characteristic == null) return;
    characteristic.oncharacteristicvaluechanged = null;
    await _guard(() => characteristic.stopNotifications().toDart);
  }

  Future<_ClientHints> _clientHints(JSAny? raw) async {
    if (raw == null || raw.isUndefined || raw.isNull || !raw.isA<JSObject>()) {
      return const _ClientHints();
    }
    final data = NavigatorUaData(raw as JSObject);
    final brands = <String>[];
    for (final brand in data.brands.toDart) {
      final name = jsString(brand, 'brand');
      final version = jsString(brand, 'version');
      if (name == null || name.isEmpty) continue;
      brands.add(version == null || version.isEmpty ? name : '$name $version');
    }
    String? architecture;
    String? model;
    String? platformVersion;
    String? bitness;
    try {
      final hints = <JSString>[
        'architecture'.toJS,
        'bitness'.toJS,
        'model'.toJS,
        'platformVersion'.toJS,
      ].toJS;
      final values = await data.getHighEntropyValues(hints).toDart;
      architecture = jsString(values, 'architecture');
      model = jsString(values, 'model');
      platformVersion = jsString(values, 'platformVersion');
      bitness = jsString(values, 'bitness');
    } on Object {
      // Yüksek entropi ipuçları her tarayıcıda yok.
    }
    return _ClientHints(
      mobile: data.mobile.toDart,
      platform: data.platform,
      brands: brands,
      architecture: architecture,
      model: model,
      platformVersion: platformVersion,
      bitness: bitness,
    );
  }

  /// Bluetooth LE tarama seçenekleri. Ağ veya Wi-Fi alanı yok.
  JSAny? _leScanOptions(String namePrefix) {
    if (namePrefix.isEmpty) {
      return {
        'acceptAllAdvertisements': true,
        'keepRepeatedDevices': false,
      }.jsify();
    }
    return {
      'keepRepeatedDevices': false,
      'filters': [
        {'namePrefix': namePrefix},
      ],
    }.jsify();
  }

  String? _present(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  JSAny? _requestOptions(BleDeviceRequest request) {
    final options = <String, Object?>{
      'optionalServices': request.optionalServices,
      if (request.acceptAllDevices) 'acceptAllDevices': true,
      if (!request.acceptAllDevices)
        'filters': request.filters.map((filter) {
          return {
            if (filter.name != null) 'name': filter.name,
            if (filter.namePrefix != null) 'namePrefix': filter.namePrefix,
            if (filter.services.isNotEmpty) 'services': filter.services,
          };
        }).toList(),
    };
    return options.jsify();
  }

  Bluetooth _requireBluetooth() {
    final bluetooth = _bluetooth;
    if (bluetooth == null) {
      throw PlatformException(
        code: 'unsupported',
        message: 'Bu tarayıcı Web Bluetooth sunmuyor.',
      );
    }
    return bluetooth;
  }

  BluetoothDevice _requireDevice(String deviceId) {
    final device = _devices[deviceId];
    if (device == null) {
      throw PlatformException(
        code: 'not_found',
        message: 'Cihaz seçilmedi: $deviceId',
      );
    }
    return device;
  }

  BluetoothRemoteGattServer _requireGatt(String deviceId) {
    final gatt = _requireDevice(deviceId).gatt;
    if (gatt == null) {
      throw PlatformException(
        code: 'unsupported',
        message: 'Bu cihaz GATT sunmuyor.',
      );
    }
    return gatt;
  }

  Future<BluetoothRemoteGattCharacteristic> _characteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    await connect(deviceId);
    final service = await _guard(
      () => _requireGatt(deviceId).getPrimaryService(serviceUuid).toDart,
    );
    return _guard(
      () => service.getCharacteristic(characteristicUuid).toDart,
    );
  }

  Future<String?> _readText(
    BluetoothRemoteGattService service,
    String characteristicUuid,
  ) async {
    try {
      final characteristic = await service
          .getCharacteristic(characteristicUuid)
          .toDart;
      final bytes = _copyBytes(await characteristic.readValue().toDart);
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      if (text.isEmpty) return null;
      return text;
    } on Object catch (error) {
      final platform = _asPlatform(error);
      if (platform.code == 'NotFoundError' ||
          platform.code == 'SecurityError') {
        return null;
      }
      throw platform;
    }
  }

  void _remember(BluetoothDevice device) {
    _devices[device.id] = device;
    if (!_disconnectHooks.add(device.id)) return;
    device.ongattserverdisconnected = ((JSAny _) {
      events.add({'kind': 'disconnected', 'deviceId': device.id});
    }).toJS;
  }

  BleDevice _describe(BluetoothDevice device) {
    final name = device.name;
    return BleDevice(
      id: device.id,
      name: name == null || name.isEmpty ? null : name,
      connected: device.gatt?.connected ?? false,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _asPlatform(error);
    }
  }

  PlatformException _asPlatform(Object error) {
    if (error is PlatformException) return error;
    final object = _jsObject(error);
    if (object != null) {
      final name = jsString(object, 'name');
      final message = jsString(object, 'message');
      if (name != null || message != null) {
        return PlatformException(code: name ?? 'web_error', message: message);
      }
    }
    return PlatformException(code: 'web_error', message: error.toString());
  }

  JSObject? _jsObject(Object error) {
    try {
      return error as JSObject;
    } on Object {
      return null;
    }
  }

  Uint8List _copyBytes(JSDataView view) {
    final data = view.toDart;
    return Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  String _notificationKey(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) {
    return '$deviceId|$serviceUuid|$characteristicUuid';
  }
}

class _ClientHints {
  const _ClientHints({
    this.mobile,
    this.platform,
    this.brands = const [],
    this.architecture,
    this.model,
    this.platformVersion,
    this.bitness,
  });

  final bool? mobile;
  final String? platform;
  final List<String> brands;
  final String? architecture;
  final String? model;
  final String? platformVersion;
  final String? bitness;
}
