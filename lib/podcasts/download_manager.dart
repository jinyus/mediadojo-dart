import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:state_beacon/state_beacon.dart';

import '../extensions/date_time_x.dart';
import '../player/data/episode_media.dart';
import '../settings/settings_service.dart';
import 'podcast_library_service.dart';

class DownloadManager with BeaconController {
  DownloadManager({
    required PodcastLibraryService libraryService,
    required SettingsService settingsService,
    required Dio dio,
  }) : _libraryService = libraryService,
       _settingsService = settingsService,
       _dio = dio;

  final PodcastLibraryService _libraryService;
  final SettingsService _settingsService;
  final Dio _dio;

  late final values = B.family(
    (String? url) => B.derived(() => _values.value[url]),
  );

  late final _values = B.hashMap<String, double?>({});
  final _cancelTokens = <String, CancelToken?>{};

  late final messageBeacon = B.writable('');

  void setValue({
    required int received,
    required int total,
    required String url,
  }) {
    if (total <= 0) return;
    final v = received / total;
    _values.value.containsKey(url)
        ? _values.update(url, (value) => v)
        : _values.putIfAbsent(url, () => v);
  }

  Future<void> deleteDownload({required EpisodeMedia? media}) async {
    if (media?.url != null &&
        _settingsService.downloadsDir != null &&
        media?.feedUrl != null) {
      await _libraryService.removeDownload(
        episodeID: media!.url!,
        feedUrl: media.feedUrl,
      );
      if (_values.value.containsKey(media.url)) {
        _values.update(media.url!, (value) => null);
      }
    }
  }

  Future<void> deleteAllDownloads() async {
    if (_settingsService.downloadsDir != null) {
      await _libraryService.removeAllDownloads();
      _values.clear();
    }
  }

  Future<void> startDownload({
    required EpisodeMedia? media,
    required String canceledMessage,
    required String finishedMessage,
  }) async {
    final downloadsDir = _settingsService.downloadsDir;
    if (media?.url == null || downloadsDir == null) return;
    final url = media!.url!;

    if (_cancelTokens[url] != null) {
      _cancelTokens[url]?.cancel();
      _values.value.containsKey(url)
          ? _values.update(url, (value) => null)
          : _values.putIfAbsent(url, () => null);
      _cancelTokens.update(url, (value) => null);

      return;
    }

    _dio.interceptors.add(LogInterceptor());
    _dio.options.headers = {HttpHeaders.acceptEncodingHeader: '*'};

    if (!Directory(downloadsDir).existsSync()) {
      Directory(downloadsDir).createSync();
    }

    final path = p.join(downloadsDir, _createAudioDownloadId(media));
    await _download(
      canceledMessage: canceledMessage,
      url: url,
      path: path,
      name: media.title ?? '',
    ).then((response) async {
      if (response?.statusCode == 200) {
        await _libraryService.addDownload(
          episodeID: url,
          path: path,
          feedUrl: media.feedUrl,
        );
        messageBeacon.value = finishedMessage;

        _cancelTokens.containsKey(url)
            ? _cancelTokens.update(url, (value) => null)
            : _cancelTokens.putIfAbsent(url, () => null);
      }
    });
  }

  String _createAudioDownloadId(EpisodeMedia media) {
    final now = DateTime.now().toUtc().toString();
    return '${media.artist ?? ''}${media.title ?? ''}${media.duration?.inMilliseconds ?? ''}${media.creationDateTime?.podcastTimeStamp ?? ''})$now'
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  Future<Response<dynamic>?> _download({
    required String url,
    required String path,
    required String name,
    required String canceledMessage,
  }) async {
    _cancelTokens.containsKey(url)
        ? _cancelTokens.update(url, (value) => CancelToken())
        : _cancelTokens.putIfAbsent(url, () => CancelToken());
    try {
      return await _dio.download(
        url,
        path,
        onReceiveProgress: (count, total) =>
            setValue(received: count, total: total, url: url),
        cancelToken: _cancelTokens[url],
      );
    } catch (e) {
      _cancelTokens[url]?.cancel();

      String? message;
      if (e.toString().contains('[request cancelled]')) {
        message = canceledMessage;
      }

      messageBeacon.value = message ?? e.toString();
      return null;
    }
  }
}
