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
          artist: currentMedia?.artist,
          artUri: artUri,
        ),
      );
    }
  }

  Player get _player => _controller.player;
  Player get player => _player;

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
      _player.stream.playing.toRawBeacon(
        shouldSleep: false,
        initialValue: false,
      )..subscribe((val) {
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

  Stream<Playlist> get _playlistStream => _player.stream.playlist;

  Stream<int> get playlistIndexStream => _playlistStream.map((e) => e.index);

  Stream<List<UniqueMedia>> get mediasStream =>
      _playlistStream.map((e) => e.medias.whereType<UniqueMedia>().toList());

  List<UniqueMedia> get medias =>
      playlist.medias.whereType<UniqueMedia>().toList();

  int get playlistIndex => _player.state.playlist.index;

  Playlist get playlist => _player.state.playlist;

  Stream<UniqueMedia?> get currentMediaStream =>
      _player.stream.playlist.asyncMap((playlist) async {
        if (playlist.medias.whereType<UniqueMedia>().isEmpty) return null;
        final media = playlist.medias
            .whereType<UniqueMedia>()
            .toList()[playlist.index];

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

        return media;
      });

  UniqueMedia? get currentMedia =>
      _player.state.playlist.medias.whereType<UniqueMedia>().isEmpty
      ? null
      : _player.state.playlist.medias
                .whereType<UniqueMedia>()
                .toList()[_player.state.playlist.index]
            as UniqueMedia?;

  PlaylistMode get playlistMode => _player.state.playlistMode;

  Stream<PlaylistMode> get playlistModeStream => _player.stream.playlistMode;

  final shuffle = ValueNotifier<bool>(false);
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

  Stream<bool> get isVideoStream => _player.stream.tracks.map(
    (tracks) =>
        tracks.video.isNotEmpty &&
        tracks.video.any((e) => e.fps != null && e.fps! > 1),
  );

  bool get isVideo =>
      _player.state.tracks.video.isNotEmpty &&
      _player.state.tracks.video.any((e) => e.fps != null && e.fps! > 1);

  Future<void> setPlaylist(
    List<UniqueMedia> mediaList, {
    int index = 0,
    bool play = true,
  }) async {
    if (mediaList.isEmpty) return;
    updateState(resetRemoteSource: true);
    await _player.open(Playlist(mediaList, index: index), play: play);
  }

  Future<void> addToPlaylist(UniqueMedia media) async => _player.add(media);

  Future<void> removeFromPlaylist(int index) async {
    if (playlist.medias.length < 2) return;
    await _player.remove(index);
  }

  Future<void> jump(int index) => _player.jump(index);

  Future<void> move(int from, int to) => _player.move(from, to);

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> pause() async => _player.pause();

  Future<void> playOrPause() => _player.playOrPause();

  @override
  Future<void> stop() async => _player.stop();

  @override
  Future<void> seek(Duration position) async => _player.seek(position);

  Future<void> setVolume(double volume) async => _player.setVolume(volume);

  Stream<double> get volumeStream => _player.stream.volume;

  double get volume => _player.state.volume;

  @override
  Future<void> skipToNext() async => _player.next();

  bool _firstClick = true;

  @override
  Future<void> skipToPrevious() async {
    if (position.value.inSeconds < 10 && _firstClick) {
      await seek(Duration.zero);
      _firstClick = false;
      return;
    }
    _firstClick = true;
    return _player.previous();
  }

  Future<void> changePlaylistMode() async {
    final currentMode = _player.state.playlistMode;
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
      _player.setPlaylistMode(mode);

  @override
  Future<void> dispose() async {
    await _player.dispose();
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
