import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:yaru/yaru.dart';

import '../../player/data/unique_media.dart';
import '../../player/player_manager.dart';
import '../../register_dependencies.dart';

class RadioBrowserStationStarButton extends StatelessWidget with WatchItMixin {
  const RadioBrowserStationStarButton({super.key, required this.media});

  final UniqueMedia media;

  @override
  Widget build(BuildContext context) {
    final isFavorite = watch(
      radioManagerRef().favoriteStationsCommand.select(
        (favorites) => favorites.any((m) => m.id == media.id),
      ),
    ).value;
    return IconButton(
      onPressed: () => isFavorite
          ? radioManagerRef().removeFavoriteStation(media.id)
          : radioManagerRef().addFavoriteStation(media.id),
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
    final isFavorite = watch(
      radioManagerRef().favoriteStationsCommand.select(
        (favorites) => favorites.any((m) => m.id == currentMedia?.id),
      ),
    ).value;
    return IconButton(
      onPressed: currentMedia == null
          ? null
          : () => isFavorite
                ? radioManagerRef().removeFavoriteStation(currentMedia.id)
                : radioManagerRef().addFavoriteStation(currentMedia.id),
      icon: Icon(isFavorite ? YaruIcons.star_filled : YaruIcons.star),
    );
  }
}
