import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../common/view/ui_constants.dart';
import '../../register_dependencies.dart';

class PlayerMainControls extends StatelessWidget {
  const PlayerMainControls({
    super.key,
    required this.iconColor,
    required this.selectedColor,
  });

  final Color iconColor;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: kMediumPadding,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlayerShuffleButton(iconColor: iconColor, selectedColor: selectedColor),
        IconButton(
          style: playerButtonStyle,
          icon: Icon(Icons.skip_previous, color: iconColor),
          onPressed: playerManagerRef().skipToPrevious,
        ),
        PlayerIsPlayingButton(iconColor: iconColor),
        IconButton(
          style: playerButtonStyle,
          icon: Icon(Icons.skip_next, color: iconColor),
          onPressed: playerManagerRef().skipToNext,
        ),
        PlayerPlaylistModeButton(
          iconColor: iconColor,
          selectedColor: selectedColor,
        ),
      ],
    );
  }
}

class PlayerShuffleButton extends StatelessWidget {
  const PlayerShuffleButton({
    super.key,
    required this.iconColor,
    required this.selectedColor,
  });

  final Color iconColor;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final controller = playerManagerRef();
    final shuffle = controller.shuffle.watch(context);
    return IconButton(
      style: playerButtonStyle,
      icon: Icon(Icons.shuffle, color: shuffle ? selectedColor : iconColor),
      onPressed: () => playerManagerRef().toggleShuffle(),
    );
  }
}

class PlayerPlaylistModeButton extends StatelessWidget {
  const PlayerPlaylistModeButton({
    super.key,
    required this.iconColor,
    required this.selectedColor,
  });

  final Color iconColor;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final controller = playerManagerRef();

    final playlistMode = controller.playlistMode.watch(context);

    return IconButton(
      style: playerButtonStyle,
      icon: Icon(
        switch (playlistMode) {
          PlaylistMode.single => Icons.repeat_one,
          _ => Icons.repeat,
        },
        color: switch (playlistMode) {
          PlaylistMode.single || PlaylistMode.loop => selectedColor,
          _ => iconColor,
        },
      ),
      onPressed: () => playerManagerRef().changePlaylistMode(),
    );
  }
}

class PlayerIsPlayingButton extends StatelessWidget {
  const PlayerIsPlayingButton({super.key, required this.iconColor});

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final controller = playerManagerRef();

    final isPlaying = controller.isPlaying.watch(context);

    return IconButton(
      style: playerButtonStyle,
      icon: Icon(
        isPlaying == true ? Icons.pause : Icons.play_arrow,
        color: iconColor,
      ),
      onPressed: controller.playOrPause,
    );
  }
}
