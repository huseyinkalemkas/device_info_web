import 'package:device_info_web/device_info_web.dart';
import 'package:device_info_web_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('örnek sayfa başlığı görünür', (tester) async {
    await tester.pumpWidget(const DeviceInfoApp());
    expect(find.text('Web cihaz bilgisi'), findsOneWidget);
    expect(find.text('Bluetooth bul'), findsOneWidget);
    expect(find.text('Filtre'), findsOneWidget);
    expect(find.text('Bulunan cihazlar (0)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'kulak');
    await tester.pump();
    expect(find.text('Filtreye uyan cihaz yok.'), findsNothing);
    await tester.pump();
  });

  test('filtre ad ve kimliğe bakar', () {
    const devices = [
      BleDevice(id: 'aa-1', name: 'Kulaklık', connected: false),
      BleDevice(id: 'bb-2', name: 'Saat', connected: false),
    ];
    final visible = visibleBluetoothDevices(devices, 'kulak');
    expect(visible.single.name, 'Kulaklık');
    final byId = visibleBluetoothDevices(devices, 'bb');
    expect(byId.single.id, 'bb-2');
  });
}
