import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../player/data/station_media.dart';
import '../../register_dependencies.dart';
import 'radio_browser_station_star_button.dart';
import 'radio_host_not_connected_content.dart';
import 'remote_media_list_tile_image.dart';

class RadioBrowser extends StatelessWidget with WatchItMixin {
  const RadioBrowser({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = radioControllerRef();

    return switch (controller.searchResults.watch(context)) {
      AsyncData(value: final results) => ListView.builder(
        itemCount: results.length,
        padding: const EdgeInsets.symmetric(horizontal: kBigPadding),
        itemBuilder: (context, index) {
          final media = results[index];
          return RadioBrowserTile(key: ValueKey(media.id), media: media);
        },
      ),
      AsyncError e => RadioHostNotConnectedContent(
        message: 'Error: $e',
        onRetry: controller.searchResults.reset,
      ),
      _ => const Center(child: CircularProgressIndicator.adaptive()),
    };
  }
}

class RadioBrowserTile extends StatelessWidget with WatchItMixin {
  const RadioBrowserTile({super.key, required this.media});

  final StationMedia media;

  @override
  Widget build(BuildContext context) {
    final playerController = playerManagerRef();
    final currentMedia = playerController.currentMedia.watch(context);

    final isCurrentMedia = currentMedia?.id == media.id;

    return ListTile(
      title: Text(media.title),
      selectedColor: context.theme.colorScheme.primary,
      selected: isCurrentMedia,
      minLeadingWidth: kDefaultTileLeadingDimension,
      leading: RemoteMediaListTileImage(media: media),
      subtitle: Text(media.genres.take(5).toList().join(', ')),
      onTap: () => playerController.setPlaylist([media]),
      trailing: RadioBrowserStationStarButton(media: media),
    );
  }
}
