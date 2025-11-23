import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app_config.dart';
import 'collection/collection_manager.dart';
import 'common/extenal_path_service.dart';
import 'common/platforms.dart';
import 'notifications/notifications_service.dart';
import 'online_art/online_art_service.dart';
import 'player/player_manager.dart';
import 'podcasts/download_manager.dart';
import 'podcasts/podcast_library_service.dart';
import 'podcasts/podcast_manager.dart';
import 'podcasts/podcast_service.dart';
import 'radio/radio_library_service.dart';
import 'radio/radio_manager.dart';
import 'radio/radio_service.dart';
import 'search/search_manager.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_service.dart';

final dioRef = Ref.singleton(Dio.new);

late final SingletonRef<SharedPreferences> sharedPrefRef;

final playerManagerRef = Ref.singleton<PlayerManager>(() {
  final controller = VideoController(
    Player(configuration: const PlayerConfiguration(title: AppConfig.appName)),
  );
  return PlayerManager(controller: controller);
});

final settingServiceRef = Ref.singleton<SettingsService>(
  () => SettingsService(sharedPreferences: sharedPrefRef())..init(),
);

final notificationServiceRef = Ref.singleton(NotificationsService.new);

final podcastLibraryServiceRef = Ref.singleton<PodcastLibraryService>(
  () => PodcastLibraryService(sharedPreferences: sharedPrefRef()),
);

final podcastServiceRef = Ref.singleton(
  () => PodcastService(
    libraryService: podcastLibraryServiceRef(),
    notificationsService: notificationServiceRef(),
    settingsService: settingServiceRef(),
  ),
);

final searchManagerRef = Ref.singleton(SearchManager.new);

final collectionManagerRef = Ref.singleton(CollectionManager.new);

final podcastManagerRef = Ref.singleton(
  () => PodcastManager(
    podcastService: podcastServiceRef(),
    searchManager: searchManagerRef(),
    collectionManager: collectionManagerRef(),
    podcastLibraryService: podcastLibraryServiceRef(),
  ),
);

final externalPathServiceRef = Ref.singleton(() => const ExternalPathService());

final settingsControllerRef = Ref.singleton(
  () => SettingsController(
    service: settingServiceRef(),
    externalPathService: externalPathServiceRef(),
  ),
);

final downloadManagerRef = Ref.singleton(
  () => DownloadManager(
    libraryService: podcastLibraryServiceRef(),
    settingsService: settingServiceRef(),
    dio: dioRef(),
  ),
);

final radioLibraryServiceRef = Ref.singleton(
  () => RadioLibraryService(sharedPreferences: sharedPrefRef()),
);

final onlineArtServiceRef = Ref.singleton(
  () => OnlineArtService(dio: dioRef()),
);

final radioServiceRef = Ref.singleton(
  () => RadioService(
    playerManager: playerManagerRef(),
    onlineArtService: onlineArtServiceRef(),
  ),
);

final radioManagerRef = Ref.singleton(
  () => RadioManager(
    radioLibraryService: radioLibraryServiceRef(),
    radioService: radioServiceRef(),
    searchManager: searchManagerRef(),
    collectionManager: collectionManagerRef(),
  ),
);

Future<void> startUp() async {
  final wm = WindowManager.instance;
  await wm.ensureInitialized();
  await wm.waitUntilReadyToShow(
    const WindowOptions(
      backgroundColor: Colors.transparent,
      minimumSize: Size(500, 700),
      size: Size(900, 800),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  final sharedPref = await SharedPreferences.getInstance();
  sharedPrefRef = Ref.singleton<SharedPreferences>(() => sharedPref);

  MediaKit.ensureInitialized();

  await AudioService.init(
    config: AudioServiceConfig(
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      androidNotificationChannelName: AppConfig.appName,
      androidNotificationChannelId: Platforms.isAndroid || Platforms.isWindows
          ? AppConfig.appId
          : null,
      androidNotificationChannelDescription: 'MusicPod Media Controls',
    ),
    builder: () => playerManagerRef.instance,
  );
}
