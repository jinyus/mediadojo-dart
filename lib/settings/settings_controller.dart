import 'package:state_beacon/state_beacon.dart';

import '../common/extenal_path_service.dart';
import '../extensions/shared_preferences_x.dart';
import 'settings_service.dart';

class SettingsController with BeaconController {
  SettingsController({
    required SettingsService service,
    required ExternalPathService externalPathService,
  }) : _service = service,
       _externalPathService = externalPathService;

  final SettingsService _service;
  final ExternalPathService _externalPathService;

  late final WritableBeacon<AsyncValue<String>> currentDir = B.writable(
    AsyncData(_service.downloadsDir ?? ''),
  );

  Future<void> changeDownloadDir() async {
    await AsyncValue.tryCatch(() async {
      final path = await _externalPathService.getPathOfDirectory();
      if (path != null) {
        await _service.setValue(SPKeys.downloads, path);
      }
      return _service.downloadsDir ?? '';
    }, beacon: currentDir);
  }
}
