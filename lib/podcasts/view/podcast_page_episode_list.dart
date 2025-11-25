import 'package:flutter/material.dart';
import 'package:podcast_search/podcast_search.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../register_dependencies.dart';
import 'episode_tile.dart';

class PodcastPageEpisodeList extends StatelessWidget {
  const PodcastPageEpisodeList({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  Widget build(BuildContext context) {
    final controller = podcastControllerRef();

    final episodeMedia = controller.episodeMedias(podcastItem);

    return switch (episodeMedia.watch(context)) {
      AsyncData(value: final episodes) => SliverList.builder(
        itemCount: episodes.length,
        itemBuilder: (context, index) => EpisodeTile(
          episode: episodes.elementAt(index),
          podcastImage: podcastItem.bestArtworkUrl,
          setPlaylist: () =>
              playerManagerRef().setPlaylist(episodes, index: index),
        ),
      ),
      AsyncError e => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Error loading episodes: $e')),
      ),
      _ => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
    };
  }
}
