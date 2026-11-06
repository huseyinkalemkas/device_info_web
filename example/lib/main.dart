import 'dart:async';

import 'package:device_info_web/device_info_web.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DeviceInfoApp());
}

class DeviceInfoApp extends StatelessWidget {
  const DeviceInfoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web cihaz bilgisi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6E6E)),
        useMaterial3: true,
      ),
      home: const DeviceInfoPage(),
    );
  }
}

/// Ada veya kimliğe göre süzer. Boş sorgu listeyi olduğu gibi bırakır.
List<BleDevice> visibleBluetoothDevices(List<BleDevice> devices, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return devices;
  return [
    for (final device in devices)
      if ((device.name ?? '').toLowerCase().contains(needle) ||
          device.id.toLowerCase().contains(needle))
        device,
  ];
}

List<BleDevice> mergeBluetoothDevices(
  List<BleDevice> current,
  Iterable<BleDevice> incoming,
) {
  final byId = {for (final device in current) device.id: device};
  for (final device in incoming) {
    byId[device.id] = device;
  }
  final merged = byId.values.toList();
  merged.sort((a, b) {
    final left = (a.name ?? a.id).toLowerCase();
    final right = (b.name ?? b.id).toLowerCase();
    return left.compareTo(right);
  });
  return merged;
}

class DeviceInfoPage extends StatefulWidget {
  const DeviceInfoPage({super.key});

  @override
  State<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  final DeviceInfoWeb _plugin = DeviceInfoWeb();
  final TextEditingController _filterController = TextEditingController();
  StreamSubscription<BleNotification>? _notifications;

  BrowserDeviceInfo? _browser;
  bool? _bluetoothAvailable;
  BleDevice? _device;
  List<BleDevice> _found = const [];
  String _filter = '';
  GattDeviceInfo? _gatt;
  String? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _loadBrowser();
    _notifications = _plugin.notifications.listen(
      _onNotification,
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _notifications?.cancel();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _loadBrowser() async {
    try {
      final info = await _plugin.getBrowserDeviceInfo();
      final available = await _plugin.getBluetoothAvailability();
      if (!mounted) return;
      setState(() {
        _browser = info;
        _bluetoothAvailable = available;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  void _onNotification(BleNotification event) {
    if (event.kind != BleNotificationKind.discovered || !mounted) return;
    setState(() {
      _found = mergeBluetoothDevices(_found, [
        BleDevice(id: event.deviceId, name: event.name, connected: false),
      ]);
    });
  }

  Future<void> _findBluetooth() async {
    final prefix = _filterController.text.trim();
    final pending = _plugin.findBluetoothDevices(
      namePrefix: prefix,
      onDiscovered: (device) {
        if (!mounted) return;
        setState(() {
          _found = mergeBluetoothDevices(_found, [device]);
          _error = null;
        });
      },
    );
    setState(() {
      _busy = true;
      _found = const [];
      _device = null;
      _gatt = null;
      _error = null;
    });
    try {
      final devices = await pending;
      if (!mounted) return;
      final found = mergeBluetoothDevices(_found, devices);
      final selected = devices.length == 1
          ? devices.first
          : _device;
      setState(() {
        _found = found;
        _device = selected;
        _error = found.isEmpty ? 'Bluetooth cihazı bulunamadı.' : null;
      });
      if (selected != null && devices.length == 1) {
        await _readInfo(selected);
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _readInfo([BleDevice? device]) async {
    final target = device ?? _device;
    if (target == null) return;
    setState(() {
      _busy = true;
      _device = target;
      _error = null;
    });
    try {
      final info = await _plugin.readDeviceInformation(target.id);
      if (!mounted) return;
      setState(() => _gatt = info);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final device = _device;
    if (device == null) return;
    try {
      await _plugin.disconnect(device.id);
      if (!mounted) return;
      setState(() {
        _device = BleDevice(id: device.id, name: device.name, connected: false);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final browser = _browser;
    final visible = visibleBluetoothDevices(_found, _filter);
    return Scaffold(
      appBar: AppBar(title: const Text('Web cihaz bilgisi')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Bluetooth', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Yalnızca Bluetooth LE cihazları aranır. Wi-Fi aranmaz.'),
          const SizedBox(height: 12),
          TextField(
            controller: _filterController,
            decoration: const InputDecoration(
              labelText: 'Filtre',
              hintText: 'Ad veya kimlik',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _filter = value),
            onSubmitted: (_) => _findBluetooth(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _busy ? null : _findBluetooth,
                child: const Text('Bluetooth bul'),
              ),
              OutlinedButton(
                onPressed: _busy || _device == null ? null : _readInfo,
                child: const Text('Cihaz bilgisini oku'),
              ),
              TextButton(
                onPressed: _device == null ? null : _disconnect,
                child: const Text('Bağlantıyı kes'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _busy
                ? 'Taranıyor… (${visible.length})'
                : 'Bulunan cihazlar (${visible.length})',
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            Text(
              _busy
                  ? 'Taranıyor…'
                  : _found.isEmpty
                  ? 'Henüz Bluetooth cihazı yok.'
                  : 'Filtreye uyan cihaz yok.',
            )
          else
            Card(
              child: Column(
                children: [
                  for (final device in visible)
                    ListTile(
                      selected: _device?.id == device.id,
                      title: Text(device.name ?? '(isimsiz)'),
                      subtitle: Text(device.id),
                      onTap: () => _readInfo(device),
                    ),
                ],
              ),
            ),
          if (_device != null) ...[
            const SizedBox(height: 12),
            _InfoCard(
              rows: [
                _Row('Ad', _device!.name ?? '(isimsiz)'),
                _Row('Kimlik', _device!.id),
              ],
            ),
          ],
          if (_gatt != null) ...[
            const SizedBox(height: 12),
            _InfoCard(
              rows: [
                _Row('Üretici', _gatt!.manufacturer ?? '-'),
                _Row('Model', _gatt!.model ?? '-'),
                _Row('Seri', _gatt!.serialNumber ?? '-'),
                _Row('Yazılım', _gatt!.firmwareRevision ?? '-'),
                _Row('Donanım', _gatt!.hardwareRevision ?? '-'),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          Text('Tarayıcı', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (browser == null)
            const Text('Tarayıcı bilgisi bekleniyor.')
          else
            _InfoCard(
              rows: [
                _Row('User agent', browser.userAgent),
                _Row('Platform', browser.platform),
                _Row('Dil', browser.language),
                _Row('Çekirdek', '${browser.hardwareConcurrency ?? '-'}'),
                _Row(
                  'Bellek',
                  browser.deviceMemoryGb == null
                      ? '-'
                      : '${browser.deviceMemoryGb} GB',
                ),
                _Row('Ekran', '${browser.screenWidth}×${browser.screenHeight}'),
                _Row('Piksel oranı', '${browser.devicePixelRatio}'),
                _Row('Model', _show(browser.model)),
                _Row(
                  'Bluetooth',
                  _bluetoothAvailable == null
                      ? '-'
                      : (_bluetoothAvailable! ? 'Hazır' : 'Kapalı veya yok'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

String _show(String? value) {
  if (value == null || value.trim().isEmpty) return '-';
  return value;
}

class _Row {
  const _Row(this.label, this.value);
  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 120, child: Text(row.label)),
                    Expanded(child: Text(row.value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
