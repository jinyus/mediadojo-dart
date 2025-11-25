import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../common/media_type.dart';
import '../../podcasts/view/podcast_collection_view.dart';
import '../../radio/view/radio_favorites_list.dart';
import '../../register_dependencies.dart';
import 'collection_search_field.dart';

class CollectionView extends StatelessWidget {
  const CollectionView({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const CollectionSearchField(),
      Expanded(
        child: switch (collectionControllerRef().mediaType.watch(context)) {
          MediaType.podcast => const PodcastCollectionView(),
          MediaType.radioStation => const RadioFavoritesList(),
        },
      ),
    ],
  );
}
