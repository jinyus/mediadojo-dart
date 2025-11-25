import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../common/view/safe_network_image.dart';
import '../../common/view/theme.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../register_dependencies.dart';
import '../data/local_media.dart';
import '../data/unique_media.dart';
import '../player_manager.dart';

class PlayerAlbumArt extends StatelessWidget {
  const PlayerAlbumArt({
    super.key,
    this.media,
    this.dimension,
    this.fit = BoxFit.cover,
  });

  final UniqueMedia? media;
  final double? dimension;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final dim = dimension ?? kBottomPlayerHeight - kPlayerTrackHeight;

    if (media != null) {
      if ((media! is LocalMedia) && media?.artData != null) {
        return SizedBox(
          width: dim,
          height: dim,
          child: Image.memory(
            media!.artData!,
            width: dim,
            height: dim,
            fit: fit,
          ),
        );
      }

      return SizedBox(
        width: dim,
        height: dim,
        child: PlayerRemoteSourceImage(height: dim, width: dim, fit: fit),
      );
    }

    return Icon(
      Icons.music_note,
      color: getPlayerIconColor(context.theme),
      size: dim * 0.8,
    );
  }
}

class PlayerRemoteSourceImage extends StatelessWidget with WatchItMixin {
  const PlayerRemoteSourceImage({
    super.key,
    required this.height,
    required this.width,
    required this.fit,
  });

  final double height;
  final double width;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final controller = playerManagerRef();

    final remoteSourceArtUrl = controller.remoteSourceArtUrl.watch(context);

    final artUrl = controller.currentArtUrl.watch(context);

    final color = controller.color.watch(context);

    final playerIconColor = color ?? getPlayerIconColor(context.theme);

    return SafeNetworkImage(
      placeholder: (context, url) {
        return Center(
          child: SizedBox(
            width: width * 0.3,
            height: width * 0.3,
            child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(playerIconColor),
            ),
          ),
        );
      },
      onImageLoaded: playerManagerRef().setRemoteColorFromImageProvider,
      url: remoteSourceArtUrl ?? artUrl,
      filterQuality: FilterQuality.medium,
      fit: fit ?? BoxFit.scaleDown,
      fallBackIcon: Icon(
        Icons.music_note,
        size: width * 0.8,
        color: playerIconColor,
      ),
      errorIcon: Icon(
        Icons.music_note,
        size: width * 0.8,
        color: playerIconColor,
      ),
      height: height,
      width: width,
    );
  }
}
