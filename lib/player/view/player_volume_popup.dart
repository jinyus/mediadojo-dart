import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';
import '../../extensions/build_context_x.dart';
import '../../register_dependencies.dart';
import 'player_track.dart';

class PlayerVolumePopup extends StatelessWidget {
  const PlayerVolumePopup({super.key, required this.iconColor});

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final controller = playerManagerRef();
    final volume = controller.volume.watch(context);

    return PopupMenuButton(
      padding: EdgeInsets.zero,
      itemBuilder: (context) {
        return [
          const PopupMenuItem(enabled: false, child: PlayerVolumeSlider()),
        ];
      },
      icon: Icon(switch (volume.round()) {
        0 => Icons.volume_off,
        final v when v >= 1 && v <= 50 => Icons.volume_down,
        _ => Icons.volume_up,
      }, color: iconColor),
    );
  }
}

class PlayerVolumeSlider extends StatelessWidget {
  const PlayerVolumeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = playerManagerRef();
    final volume = controller.volume.watch(context);
    return RotatedBox(
      quarterTurns: 3,
      child: SliderTheme(
        data: context.theme.sliderTheme.copyWith(
          trackShape: CustomTrackShape(),
        ),
        child: Slider(
          value: volume.clamp(0, 100),
          max: 100,
          onChanged: (v) => playerManagerRef().setVolume(v),
        ),
      ),
    );
  }
}
