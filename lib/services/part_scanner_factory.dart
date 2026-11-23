import '../config/app_config.dart';
import 'on_device_scanner.dart';
import 'part_scanner.dart';

/// Chooses the scanner:
///   1. AI server, when AI_SCANNER_URL is set (PC or hosted server),
///   2. the model inside the app (no server, no internet),
///   3. the demo scanner, when the on-device model is switched off.
class PartScannerFactory {
  PartScannerFactory._();

  static PartScanner create() {
    if (AppConfig.aiScannerConfigured) return RemotePartScanner();
    if (AppConfig.useOnDeviceModel) return OnDevicePartScanner();
    return MockPartScanner();
  }
}
