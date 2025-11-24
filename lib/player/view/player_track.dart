import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../common/view/theme.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../extensions/color_x.dart';
import '../../register_dependencies.dart';
import '../player_manager.dart';

class PlayerTrack extends StatelessWidget with WatchItMixin {
  const PlayerTrack({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = playerManagerRef();

    final duration = controller.duration.watch(context);

    final slider = controller.slider.watch(context);

    const thumbShape = RoundSliderThumbShape(
      elevation: 0,
      enabledThumbRadius: 0,
      disabledThumbRadius: 0,
    );

    final trackColor = getPlayerIconColor(context.theme);

    final isPlaying =
        watchStream(
          (PlayerManager p) => p.isPlayingStream,
          target: playerManagerRef(),
          initialValue: playerManagerRef().isPlaying,
        ).data ??
        false;

    return RepaintBoundary(
      child: (duration.inSeconds < 10) && isPlaying
          ? LinearProgressIndicator(
              value: null,
              minHeight: kPlayerTrackHeight,
              color: trackColor.withValues(alpha: 0.8),
              backgroundColor: trackColor.withValues(alpha: 0.4),
            )
          : SliderTheme(
              data: context.theme.sliderTheme.copyWith(
                thumbColor: Colors.white,
                minThumbSeparation: 0,
                thumbShape: thumbShape,
                overlayShape: thumbShape,
                trackShape:
                    const RectangularSliderTrackShape() as SliderTrackShape,
                trackHeight: kPlayerTrackHeight,
                activeTrackColor: trackColor.scale(saturation: 0.2),
                inactiveTrackColor: trackColor.withAlpha(50),
                secondaryActiveTrackColor: trackColor.withAlpha(80),
              ),
              child: Slider(
                min: 0,
                max: slider.max,
                value: slider.value,
                secondaryTrackValue: slider.secondaryTrackValue,
                onChanged: (value) {
                  controller.seek(Duration(seconds: value.toInt()));
                },
              ),
            ),
    );
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: 0,
    );
  }
}
