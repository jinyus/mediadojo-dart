import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../player/data/station_media.dart';
import '../../player/player_manager.dart';
import '../../register_dependencies.dart';
import 'radio_browser_station_star_button.dart';
import 'radio_host_not_connected_content.dart';
import 'remote_media_list_tile_image.dart';

class RadioBrowser extends StatelessWidget with WatchItMixin {
  const RadioBrowser({super.key});

  @override
  Widget build(BuildContext context) =>
      watch(radioManagerRef().updateSearchCommand.results).value.toWidget(
        whileRunning: (lastResult, param) =>
            const Center(child: CircularProgressIndicator.adaptive()),
        onError: (error, param, lastResult) => RadioHostNotConnectedContent(
          message: 'Error: $error',
          onRetry: radioManagerRef().updateSearchCommand.run,
        ),
        onData: (data, param) => ListView.builder(
          itemCount: data.length,
          padding: const EdgeInsets.symmetric(horizontal: kBigPadding),
          itemBuilder: (context, index) {
            final media = data[index];
            return RadioBrowserTile(key: ValueKey(media.id), media: media);
          },
        ),
      );
}

class RadioBrowserTile extends StatelessWidget with WatchItMixin {
  const RadioBrowserTile({super.key, required this.media});

  final StationMedia media;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(media.title),
    selectedColor: context.theme.colorScheme.primary,
    selected:
        watchStream(
          (PlayerManager p) =>
              p.currentMediaStream.map((e) => e?.id == media.id).distinct(),
          target: playerManagerRef(),
          initialValue: playerManagerRef().currentMedia?.id == media.id,
          preserveState: false,
          allowStreamChange: true,
        ).data ??
        false,
    minLeadingWidth: kDefaultTileLeadingDimension,
    leading: RemoteMediaListTileImage(media: media),
    subtitle: Text(media.genres.take(5).toList().join(', ')),
    onTap: () => playerManagerRef().setPlaylist([media]),
    trailing: RadioBrowserStationStarButton(media: media),
  );
}
