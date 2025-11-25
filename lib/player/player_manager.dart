import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:state_beacon/state_beacon.dart';

import '../common/logging.dart';
import '../extensions/color_x.dart';
import 'data/unique_media.dart';
import 'view/player_view_state.dart';

class PlayerManager extends BaseAudioHandler
    with SeekHandler, BeaconController {
  PlayerManager({required VideoController controller})
    : _controller = controller {
    playbackState.add(
      PlaybackState(
        playing: false,
        systemActions: {
          MediaAction.seek,
          MediaAction.seekBackward,
          MediaAction.seekForward,
        },
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.rewind,
          MediaControl.play,
          MediaControl.fastForward,
          MediaControl.skipToNext,
        ],
      ),
    );
  }

  final VideoController _controller;
  VideoController get videoController => _controller;

  final playerViewState = ValueNotifier<PlayerViewState>(
    const PlayerViewState(fullMode: false, showPlayerExplorer: true),
  );

  void updateState({
    bool? fullMode,
    bool? showPlayerExplorer,
    int? explorerIndex,
    Color? color,
    String? remoteSourceArtUrl,
    String? remoteSourceTitle,
    bool resetRemoteSource = false,
  }) {
    final previousArtUri = mediaItem.value?.artUri;
    final artUri =
        (remoteSourceArtUrl == null
            ? previousArtUri
            : Uri.tryParse(remoteSourceArtUrl)) ??
        previousArtUri;

    if (resetRemoteSource) {
      playerViewState.value = PlayerViewState(
        fullMode: fullMode ?? playerViewState.value.fullMode,
        showPlayerExplorer:
            showPlayerExplorer ?? playerViewState.value.showPlayerExplorer,
        explorerIndex: explorerIndex ?? playerViewState.value.explorerIndex,
        color: color,
        remoteSourceArtUrl: null,
        remoteSourceTitle: null,
      );
    } else {
      playerViewState.value = playerViewState.value.copyWith(
        fullMode: fullMode,
        showPlayerExplorer: showPlayerExplorer,
        explorerIndex: explorerIndex,
        color: color,
        remoteSourceArtUrl: remoteSourceArtUrl,
        remoteSourceTitle: remoteSourceTitle,
      );
    }

    if (remoteSourceTitle != null && mediaItem.value != null) {
      mediaItem.add(
        mediaItem.value?.copyWith(
          title: remoteSourceTitle,
          artist: currentMedia.value?.artist,
          artUri: artUri,
        ),
      );
    }
  }

  Player get player => _controller.player;

  late final position =
      B.streamRaw(
        () => _controller.player.stream.position,
        initialValue: Duration.zero,
        shouldSleep: false,
      )..subscribe((pos) {
        playbackState.add(playbackState.value.copyWith(updatePosition: pos));
      }, startNow: false);

  late final buffer = B.streamRaw(
    () => _controller.player.stream.buffer,
    initialValue: Duration.zero,
    shouldSleep: false,
  );

  late final slider = B.derived(() {
    final durationSeconds = duration.value.inSeconds.toDouble();
    final positionSeconds = position.value.inSeconds.toDouble();
    final bufferSeconds = buffer.value.inSeconds.toDouble();

    final sliderActive = durationSeconds > positionSeconds;

    final bufferActive =
        bufferSeconds >= 0 &&
        bufferSeconds <= (sliderActive ? durationSeconds : 1.0);

    return (
      max: sliderActive ? durationSeconds : 1.0,
      value: sliderActive ? positionSeconds : 0.0,
      secondaryTrackValue: bufferActive ? bufferSeconds : null,
    );
  });

  late final duration =
      B.streamRaw(
        () => _controller.player.stream.duration,
        initialValue: Duration.zero,
        shouldSleep: false,
      )..subscribe((dur) {
        if (mediaItem.value != null) {
          mediaItem.add(mediaItem.value!.copyWith(duration: dur));
        }
      }, startNow: false);

  late final isPlaying =
      player.stream.playing.toRawBeacon(shouldSleep: false, initialValue: false)
        ..subscribe((val) {
          playbackState.add(
            playbackState.value.copyWith(
              playing: val,
              controls: [
                MediaControl.skipToPrevious,
                val ? MediaControl.pause : MediaControl.play,

                MediaControl.skipToNext,
              ],
              processingState: AudioProcessingState.ready,
            ),
          );
        });

  Stream<Playlist> get _playlistStream => player.stream.playlist;

  late final playlistIndexStream = _playlistStream
      .map((e) => e.index)
      .toRawBeacon(shouldSleep: false, initialValue: playlistIndex);

  Stream<List<UniqueMedia>> get mediasStream =>
      _playlistStream.map((e) => e.medias.whereType<UniqueMedia>().toList());

  late final medias = _playlistStream
      .map((e) => e.medias.whereType<UniqueMedia>().toList())
      .toRawBeacon(shouldSleep: false, initialValue: []);

  int get playlistIndex => player.state.playlist.index;

  Playlist get playlist => player.state.playlist;

  late final currentMedia =
      player.stream.playlist.map((playlist) {
        return playlist.medias
            .whereType<UniqueMedia>()
            .toList()
            .elementAtOrNull(playlist.index);
      }).toRawBeacon()..subscribe((media) async {
        if (media == null) return;
        final Uri? artUri;
        if (playerViewState.value.remoteSourceArtUrl != null) {
          artUri = Uri.tryParse(playerViewState.value.remoteSourceArtUrl!);
        } else {
          artUri = await media.artUri;
        }

        mediaItem.add(
          MediaItem(
            id: media.id,
            title: media.title ?? media.id.toString(),
            artist: media.artist,
            album: media.collectionName,
            duration: media.duration ?? duration.value,
            artUri: artUri,
          ),
        );

        await _setLocalColor(media);
      });

  late final currentArtUrl = B.derived(() {
    final media = currentMedia.value;

    return media?.artUrl ?? media?.collectionArtUrl;
  });

  PlaylistMode get playlistMode => player.state.playlistMode;

  Stream<PlaylistMode> get playlistModeStream => player.stream.playlistMode;

  late final shuffle = B.writable(false);

  var _oldPlaylistMedias = <UniqueMedia>[];
  void toggleShuffle() {
    shuffle.value = !shuffle.value;
    final currentPlaylist = playlist;

    final medias = currentPlaylist.medias.whereType<UniqueMedia>().toList();
    if (shuffle.value) {
      _oldPlaylistMedias = List<UniqueMedia>.from(medias);
      medias.shuffle();
    } else {
      medias
        ..clear()
        ..addAll(_oldPlaylistMedias);
    }
    setPlaylist(medias);
  }

  late final isVideo = player.stream.tracks
      .map(
        (tracks) =>
            tracks.video.isNotEmpty &&
            tracks.video.any((e) => e.fps != null && e.fps! > 1),
      )
      .toRawBeacon(shouldSleep: false, initialValue: false);

  Future<void> setPlaylist(
    List<UniqueMedia> mediaList, {
    int index = 0,
    bool play = true,
  }) async {
    if (mediaList.isEmpty) return;
    updateState(resetRemoteSource: true);
    await player.open(Playlist(mediaList, index: index), play: play);
  }

  Future<void> addToPlaylist(UniqueMedia media) async => player.add(media);

  Future<void> removeFromPlaylist(int index) async {
    if (playlist.medias.length < 2) return;
    await player.remove(index);
  }

  Future<void> jump(int index) => player.jump(index);

  Future<void> move(int from, int to) => player.move(from, to);

  @override
  Future<void> play() async => player.play();

  @override
  Future<void> pause() async => player.pause();

  Future<void> playOrPause() => player.playOrPause();

  @override
  Future<void> stop() async => player.stop();

  @override
  Future<void> seek(Duration position) async => player.seek(position);

  Future<void> setVolume(double volume) async => player.setVolume(volume);

  Stream<double> get volumeStream => player.stream.volume;

  double get volume => player.state.volume;

  @override
  Future<void> skipToNext() async => player.next();

  bool _firstClick = true;

  @override
  Future<void> skipToPrevious() async {
    if (position.value.inSeconds < 10 && _firstClick) {
      await seek(Duration.zero);
      _firstClick = false;
      return;
    }
    _firstClick = true;
    return player.previous();
  }

  Future<void> changePlaylistMode() async {
    final currentMode = player.state.playlistMode;
    PlaylistMode nextMode;
    switch (currentMode) {
      case PlaylistMode.none:
        nextMode = PlaylistMode.loop;
      case PlaylistMode.single:
        nextMode = PlaylistMode.none;
      case PlaylistMode.loop:
        nextMode = PlaylistMode.single;
    }
    await setPlaylistMode(nextMode);
  }

  Future<void> setPlaylistMode(PlaylistMode mode) async =>
      player.setPlaylistMode(mode);

  @override
  Future<void> dispose() async {
    await player.dispose();
  }

  Future<void> _setLocalColor(UniqueMedia media) async {
    try {
      final art = media.artData;

      if (art != null) {
        final colorScheme = await ColorScheme.fromImageProvider(
          provider: MemoryImage(art),
        );
        updateState(color: colorScheme.primary);
      }
    } on Exception catch (e) {
      printMessageInDebugMode(e);
    }
  }

  Future<void> setRemoteColorFromImageProvider(ImageProvider provider) async {
    try {
      final colorScheme = await ColorScheme.fromImageProvider(
        provider: provider,
      );
      updateState(color: colorScheme.primary.scale(saturation: 1));
    } on Exception catch (e) {
      printMessageInDebugMode(e);
    }
  }
}
