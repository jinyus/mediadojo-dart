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

class RadioFavoritesList extends StatelessWidget {
  const RadioFavoritesList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = radioControllerRef();

    return switch (controller.favoriteStations.watch(context)) {
      AsyncData(value: final favorites) => ListView.builder(
        padding: const EdgeInsets.only(
          top: kSmallPadding,
          left: kBigPadding,
          right: kBigPadding,
        ),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final media = favorites[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: kSmallPadding),
            child: _RadioFavoriteListTile(
              key: ValueKey(media.id),
              media: media,
            ),
          );
        },
      ),
      AsyncError e => RadioHostNotConnectedContent(
        message: 'Error: $e',
        onRetry: controller.favoriteStations.reset,
      ),
      _ => const Center(child: CircularProgressIndicator.adaptive()),
    };
  }
}

class _RadioFavoriteListTile extends StatelessWidget {
  const _RadioFavoriteListTile({super.key, required this.media});

  final StationMedia media;

  @override
  Widget build(BuildContext context) {
    final playerController = playerManagerRef();
    final currentMedia = playerController.currentMedia.watch(context);

    final isCurrentMedia = currentMedia?.id == media.id;

    return ListTile(
      title: Text(media.title),
      subtitle: Text(media.genres.take(5).join(', ')),
      minLeadingWidth: kDefaultTileLeadingDimension,
      leading: RemoteMediaListTileImage(media: media),
      trailing: RadioBrowserStationStarButton(media: media),
      selected: isCurrentMedia,
      selectedColor: context.colorScheme.primary,
      onTap: () => playerManagerRef().setPlaylist([media]),
    );
  }
}
