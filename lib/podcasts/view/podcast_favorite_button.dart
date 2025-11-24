import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../register_dependencies.dart';
import '../data/podcast_metadata.dart';

class PodcastFavoriteButton extends StatelessWidget {
  const PodcastFavoriteButton({super.key, required this.podcastItem})
    : _floating = false;
  const PodcastFavoriteButton.floating({super.key, required this.podcastItem})
    : _floating = true;

  final Item podcastItem;
  final bool _floating;

  @override
  Widget build(BuildContext context) {
    final controller = podcastControllerRef();
    final isSubscribed = controller.subscriptions(podcastItem).watch(context);

    void onPressed() {
      isSubscribed
          ? controller.removePodcast(feedUrl: podcastItem.feedUrl!)
          : controller.addPodcast(
              PodcastMetadata(
                feedUrl: podcastItem.feedUrl!,
                name: podcastItem.collectionName!,
                artist: podcastItem.artistName!,
                imageUrl: podcastItem.bestArtworkUrl!,
                genreList:
                    podcastItem.genre?.map((e) => e.name).toList() ??
                    <String>[],
              ),
            );
    }

    final icon = Icon(isSubscribed ? Icons.favorite : Icons.favorite_border);

    if (_floating) {
      return FloatingActionButton.small(
        heroTag: 'favtag',
        onPressed: onPressed,
        child: icon,
      );
    }

    return IconButton(onPressed: onPressed, icon: icon);
  }
}
