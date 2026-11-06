import 'dart:typed_data';

import 'gatt_uuids.dart';

/// Tarayıcının gördüğü bu bilgisayar / telefon.
class BrowserDeviceInfo {
  const BrowserDeviceInfo({
    required this.userAgent,
    required this.platform,
    required this.vendor,
    required this.language,
    required this.languages,
    required this.hardwareConcurrency,
    required this.deviceMemoryGb,
    required this.maxTouchPoints,
    required this.screenWidth,
    required this.screenHeight,
    required this.availWidth,
    required this.availHeight,
    required this.devicePixelRatio,
    required this.mobile,
    required this.uaPlatform,
    required this.brands,
    required this.architecture,
    required this.model,
    required this.platformVersion,
    required this.bitness,
  });

  factory BrowserDeviceInfo.fromMap(Map<String, Object?> map) {
    return BrowserDeviceInfo(
      userAgent: _string(map['userAgent']) ?? '',
      platform: _string(map['platform']) ?? '',
      vendor: _string(map['vendor']) ?? '',
      language: _string(map['language']) ?? '',
      languages: _stringList(map['languages']),
      hardwareConcurrency: _int(map['hardwareConcurrency']),
      deviceMemoryGb: _double(map['deviceMemoryGb']),
      maxTouchPoints: _int(map['maxTouchPoints']) ?? 0,
      screenWidth: _int(map['screenWidth']) ?? 0,
      screenHeight: _int(map['screenHeight']) ?? 0,
      availWidth: _int(map['availWidth']) ?? 0,
      availHeight: _int(map['availHeight']) ?? 0,
      devicePixelRatio: _double(map['devicePixelRatio']) ?? 1,
      mobile: map['mobile'] is bool ? map['mobile'] as bool : null,
      uaPlatform: _string(map['uaPlatform']),
      brands: _stringList(map['brands']),
      architecture: _string(map['architecture']),
      model: _string(map['model']),
      platformVersion: _string(map['platformVersion']),
      bitness: _string(map['bitness']),
    );
  }

  final String userAgent;
  final String platform;
  final String vendor;
  final String language;
  final List<String> languages;
  final int? hardwareConcurrency;

  /// Chrome'un yaklaşık GB değeri. Firefox bu alanı vermez.
  final double? deviceMemoryGb;
  final int maxTouchPoints;
  final int screenWidth;
  final int screenHeight;
  final int availWidth;
  final int availHeight;
  final double devicePixelRatio;
  final bool? mobile;
  final String? uaPlatform;
  final List<String> brands;
  final String? architecture;
  final String? model;
  final String? platformVersion;
  final String? bitness;

  Map<String, Object?> toMap() {
    return {
      'userAgent': userAgent,
      'platform': platform,
      'vendor': vendor,
      'language': language,
      'languages': languages,
      'hardwareConcurrency': hardwareConcurrency,
      'deviceMemoryGb': deviceMemoryGb,
      'maxTouchPoints': maxTouchPoints,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'availWidth': availWidth,
      'availHeight': availHeight,
      'devicePixelRatio': devicePixelRatio,
      'mobile': mobile,
      'uaPlatform': uaPlatform,
      'brands': brands,
      'architecture': architecture,
      'model': model,
      'platformVersion': platformVersion,
      'bitness': bitness,
    };
  }
}

/// Kullanıcının seçtiği BLE cihazı.
class BleDevice {
  const BleDevice({
    required this.id,
    required this.name,
    required this.connected,
  });

  factory BleDevice.fromMap(Map<String, Object?> map) {
    return BleDevice(
      id: _string(map['id']) ?? '',
      name: _string(map['name']),
      connected: map['connected'] == true,
    );
  }

  final String id;
  final String? name;
  final bool connected;

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'connected': connected};
  }
}

/// `requestDevice` süzgeci. En az bir alan dolu olmalı.
class BleFilter {
  BleFilter({this.name, this.namePrefix, this.services = const []}) {
    if (name == null && namePrefix == null && services.isEmpty) {
      throw ArgumentError('BleFilter name, namePrefix veya services ister.');
    }
  }

  final String? name;
  final String? namePrefix;
  final List<String> services;

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'namePrefix': namePrefix,
      'services': services,
    };
  }
}

/// Tarayıcı cihaz penceresinin seçenekleri.
///
/// [filters] boşsa tüm cihazlar listelenir. Doluysa yalnızca eşleşenler görünür.
/// [optionalServices] içine yazılmayan servis, seçimden sonra okunamaz.
class BleDeviceRequest {
  const BleDeviceRequest({
    this.filters = const [],
    this.optionalServices = const [GattUuid.deviceInformation],
  });

  factory BleDeviceRequest.fromMap(Map<String, Object?> map) {
    final rawFilters = map['filters'];
    final filters = <BleFilter>[];
    if (rawFilters is List) {
      for (final item in rawFilters) {
        if (item is Map) {
          filters.add(
            BleFilter(
              name: _string(item['name']),
              namePrefix: _string(item['namePrefix']),
              services: _stringList(item['services']),
            ),
          );
        }
      }
    }
    final services = _stringList(map['optionalServices']);
    return BleDeviceRequest(
      filters: filters,
      optionalServices: services.isEmpty
          ? const [GattUuid.deviceInformation]
          : services,
    );
  }

  final List<BleFilter> filters;
  final List<String> optionalServices;

  bool get acceptAllDevices => filters.isEmpty;

  Map<String, Object?> toMap() {
    return {
      'filters': filters.map((filter) => filter.toMap()).toList(),
      'optionalServices': optionalServices,
    };
  }
}

/// Device Information servisi (`0x180A`) metinleri.
class GattDeviceInfo {
  const GattDeviceInfo({
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.firmwareRevision,
    this.hardwareRevision,
    this.softwareRevision,
  });

  factory GattDeviceInfo.fromMap(Map<String, Object?> map) {
    return GattDeviceInfo(
      manufacturer: _string(map['manufacturer']),
      model: _string(map['model']),
      serialNumber: _string(map['serialNumber']),
      firmwareRevision: _string(map['firmwareRevision']),
      hardwareRevision: _string(map['hardwareRevision']),
      softwareRevision: _string(map['softwareRevision']),
    );
  }

  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final String? firmwareRevision;
  final String? hardwareRevision;
  final String? softwareRevision;

  bool get isEmpty =>
      manufacturer == null &&
      model == null &&
      serialNumber == null &&
      firmwareRevision == null &&
      hardwareRevision == null &&
      softwareRevision == null;

  Map<String, Object?> toMap() {
    return {
      'manufacturer': manufacturer,
      'model': model,
      'serialNumber': serialNumber,
      'firmwareRevision': firmwareRevision,
      'hardwareRevision': hardwareRevision,
      'softwareRevision': softwareRevision,
    };
  }
}

enum BleNotificationKind { value, disconnected, discovered }

final Uint8List _emptyBytes = Uint8List(0);

/// GATT bildirimi veya beklenmedik kopma.
class BleNotification {
  BleNotification({
    required this.kind,
    required this.deviceId,
    this.name,
    this.serviceUuid,
    this.characteristicUuid,
    Uint8List? value,
  }) : value = value ?? _emptyBytes;

  factory BleNotification.fromMap(Map<String, Object?> map) {
    return BleNotification(
      kind: switch (map['kind']) {
        'disconnected' => BleNotificationKind.disconnected,
        'discovered' => BleNotificationKind.discovered,
        _ => BleNotificationKind.value,
      },
      deviceId: _string(map['deviceId']) ?? '',
      name: _string(map['name']),
      serviceUuid: _string(map['serviceUuid']),
      characteristicUuid: _string(map['characteristicUuid']),
      value: _bytes(map['value']),
    );
  }

  final BleNotificationKind kind;
  final String deviceId;
  final String? name;
  final String? serviceUuid;
  final String? characteristicUuid;
  final Uint8List value;

  Map<String, Object?> toMap() {
    return {
      'kind': switch (kind) {
        BleNotificationKind.disconnected => 'disconnected',
        BleNotificationKind.discovered => 'discovered',
        BleNotificationKind.value => 'value',
      },
      'deviceId': deviceId,
      'name': name,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
      'value': value,
    };
  }
}

String? _string(Object? value) => value is String ? value : null;

int? _int(Object? value) => value is num ? value.toInt() : null;

double? _double(Object? value) => value is num ? value.toDouble() : null;

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const [];
}

Uint8List _bytes(Object? value) {
  if (value is Uint8List) return value;
  if (value is List) {
    return Uint8List.fromList(value.whereType<int>().toList());
  }
  return Uint8List(0);
}
