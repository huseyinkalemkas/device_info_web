import 'package:device_info_web/device_info_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tarayıcı bilgisi boş değildir', (tester) async {
    final info = await DeviceInfoWeb().getBrowserDeviceInfo();
    expect(info.userAgent, isNotEmpty);
    expect(info.screenWidth, greaterThan(0));
  });
}
