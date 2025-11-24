import 'package:state_beacon/state_beacon.dart';

import '../../register_dependencies.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../common/view/ui_constants.dart';
import 'podcast_card.dart';

class PodcastCollectionView extends StatelessWidget {
  const PodcastCollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = podcastControllerRef();

    final podcasts = controller.podcasts.watch(context);

    return GridView.builder(
      padding: kGridViewPadding.copyWith(top: kBigPadding),
      gridDelegate: kGridViewDelegate,
      itemCount: podcasts.length,
      itemBuilder: (context, index) {
        final item = podcasts.elementAt(index);
        return PodcastCard(
          key: ValueKey(item),
          podcastItem: Item(
            feedUrl: item.feedUrl,
            artistName: item.artist,
            collectionName: item.name,
            artworkUrl: item.imageUrl,
            genre:
                item.genreList?.mapIndexed((i, e) => Genre(i, e)).toList() ??
                <Genre>[],
          ),
        );
      },
    );
  }
}
