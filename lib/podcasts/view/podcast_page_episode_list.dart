import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../player/player_manager.dart';
import '../../register_dependencies.dart';
import '../podcast_manager.dart';
import 'episode_tile.dart';

class PodcastPageEpisodeList extends StatelessWidget with WatchItMixin {
  const PodcastPageEpisodeList({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  Widget build(BuildContext context) {
    callOnce(
      (context) => podcastManagerRef().fetchEpisodeMediaCommand(podcastItem),
    );

    return watchValue(
      (PodcastManager m) => m.fetchEpisodeMediaCommand.results,
    ).toWidget(
      onData: (episodes, param) => SliverList.builder(
        itemCount: episodes.length,
        itemBuilder: (context, index) => EpisodeTile(
          episode: episodes.elementAt(index),
          podcastImage: podcastItem.bestArtworkUrl,
          setPlaylist: () =>
              playerManagerRef().setPlaylist(episodes, index: index),
        ),
      ),
      onError: (error, lastResult, param) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Error loading episodes: $error')),
      ),
      whileRunning: (res, query) => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }
}
