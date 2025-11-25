import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';
import '../../common/view/theme.dart';
import '../../extensions/build_context_x.dart';
import '../../extensions/color_scheme_x.dart';
import '../../extensions/color_x.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/view/ui_constants.dart';
import '../../register_dependencies.dart';
import 'player_bottom_album_art.dart';
import 'player_control_mixin.dart';
import 'player_main_controls.dart';
import 'player_track.dart';
import 'player_track_info.dart';
import 'player_volume_popup.dart';

class PlayerView extends StatelessWidget with PlayerControlMixin {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = playerManagerRef();
    final media = controller.currentMedia.watch(context);

    final isFullMode = controller.fullMode.watch(context);

    final color = controller.color.watch(context);

    final colorScheme = context.colorScheme;

    const firstChild = SizedBox.shrink();

    final theme = context.theme;
    final iconColor = getPlayerIconColor(theme);

    final bgColor = getPlayerBg(
      theme,
      color,
      blendAmount: 0.4,
      saturation: colorScheme.isLight ? -0.7 : -0.5,
    );

    final secondChild = InkWell(
      hoverColor: colorScheme.primary.withAlpha(80),
      onTap: () => togglePlayerFullMode(context),
      child: SizedBox(
        height: kBottomPlayerHeight,
        child: Material(
          color: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          child: Column(
            children: [
              const PlayerTrack(),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: kMediumPadding,
                  children: [
                    if (isFullMode)
                      SizedBox.square(
                        dimension: kBottomPlayerHeight - kPlayerTrackHeight,
                        child: Center(
                          child: IconButton(
                            onPressed: () => togglePlayerFullMode(context),
                            icon: Icon(Icons.fullscreen_exit, color: iconColor),
                          ),
                        ),
                      )
                    else
                      PlayerBottomAlbumArt(media: media),
                    if (context.showSideBar)
                      SizedBox(
                        width: kPlayerInfoWidth,
                        child: PlayerTrackInfo(textColor: iconColor),
                      ),
                    Expanded(
                      flex: 5,
                      child: PlayerMainControls(
                        iconColor: iconColor,
                        selectedColor:
                            color?.scale(
                              saturation: 1,
                              lightness: colorScheme.isDark ? 0.3 : 0.1,
                            ) ??
                            colorScheme.primary,
                      ),
                    ),
                    PlayerVolumePopup(iconColor: iconColor),
                    IconButton(
                      style: playerButtonStyle,
                      icon: Icon(Icons.stop, color: iconColor),
                      onPressed: () {
                        playerManagerRef().setPlaylist([], play: false);
                        playerManagerRef().stop();
                        playerManagerRef().updateState(fullMode: false);
                        Navigator.of(context).maybePop();
                      },
                    ),
                    const SizedBox(width: kMediumPadding),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: AnimatedCrossFade(
        firstChild: firstChild,
        secondChild: secondChild,
        crossFadeState: media == null
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}
