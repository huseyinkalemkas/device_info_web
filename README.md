# device_info_web

Flutter web için tarayıcı cihaz bilgisi ve BLE GATT yönetimi. Hazır Bluetooth paketi kullanmaz; tarayıcı API'sine kendi bağlarımız gider.

Uygulama `MethodChannel('device_info_web')` ile konuşur. Web kaydı `DeviceInfoWebWeb.registerWith` içinde bu kanalı dinler. Bildirimler `EventChannel('device_info_web/events')` üzerinden gelir.

Cihaz penceresi (`navigator.bluetooth.requestDevice`) kanal mesajına konmaz. Tarayıcı bu pencereyi yalnızca gerçek tıklamanın aynı turunda açar. `requestDevice` bir düğmenin `onPressed` içinden, öncesinde başka `await` olmadan çağrılır.

```dart
final plugin = DeviceInfoWeb();

final browser = await plugin.getBrowserDeviceInfo();

final devices = await plugin.findBluetoothDevices();
final device = devices.single;

final info = await plugin.readDeviceInformation(device.id);
await plugin.disconnect(device.id);
```

Okunacak servis, seçim anında `optionalServices` içinde olmalıdır. Chrome, Edge ve Opera'da `localhost` veya `https` gerekir. Firefox ve Safari Web Bluetooth sunmaz.

Örnek uygulama `example/` altındadır:

```bash
cd example
flutter run -d chrome
```
