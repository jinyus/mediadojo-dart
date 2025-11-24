import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:yaru/yaru.dart';

import '../../player/data/unique_media.dart';
import '../../player/player_manager.dart';
import '../../register_dependencies.dart';

class RadioBrowserStationStarButton extends StatelessWidget {
  const RadioBrowserStationStarButton({super.key, required this.media});

  final UniqueMedia media;

  @override
  Widget build(BuildContext context) {
    final controller = radioControllerRef();

    final isFavorite = controller.isFavorite(media.id).watch(context);

    return IconButton(
      onPressed: () => isFavorite
          ? controller.removeFavoriteStation(media.id)
          : controller.addFavoriteStation(media.id),
      icon: Icon(isFavorite ? YaruIcons.star_filled : YaruIcons.star),
    );
  }
}

class RadioStationStarButton extends StatelessWidget with WatchItMixin {
  const RadioStationStarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final currentMedia = watchStream(
      (PlayerManager p) => p.currentMediaStream,
      target: playerManagerRef(),
      initialValue: playerManagerRef().currentMedia,
      preserveState: false,
    ).data;

    final controller = radioControllerRef();

    final mediaID = currentMedia?.id;

    final isFavorite = mediaID == null
        ? false
        : controller.isFavorite(mediaID).watch(context);

    return IconButton(
      onPressed: currentMedia == null
          ? null
          : () => isFavorite
                ? controller.removeFavoriteStation(currentMedia.id)
                : controller.addFavoriteStation(currentMedia.id),
      icon: Icon(isFavorite ? YaruIcons.star_filled : YaruIcons.star),
    );
  }
}
