import 'package:podcast_search/podcast_search.dart';
import 'package:state_beacon/state_beacon.dart';

import '../collection/collection_controller.dart';
import '../extensions/country_x.dart';
import '../search/search_controller.dart';
import 'data/podcast_metadata.dart';
import 'podcast_library_service.dart';
import 'podcast_service.dart';

/// Manages podcast search and episode fetching.
///
/// Note: This manager is registered as a singleton in get_it and lives for the
/// entire app lifetime. Commands and subscriptions don't need explicit disposal
/// as they're automatically cleaned up when the app process terminates.

class PodcastController with BeaconController {
  PodcastController({
    required PodcastService podcastService,
    required SearchTextController searchController,
    required CollectionController collectionController,
    required PodcastLibraryService podcastLibraryService,
  }) : _podcastService = podcastService,
       _podcastLibraryService = podcastLibraryService,
       _searchController = searchController,
       _collectionController = collectionController;

  final PodcastService _podcastService;
  final PodcastLibraryService _podcastLibraryService;
  final SearchTextController _searchController;
  final CollectionController _collectionController;

  late final results = B.future(() {
    final query = _searchController.searchTextDebounced.value;
    return _podcastService.search(
      searchQuery: query.text,
      limit: 20,
      country: CountryX.platformDefault,
    );
  }, shouldSleep: false);

  late final _libraryModified = B.writable(false);

  late final podcasts = B.derived(() {
    final filterText = _collectionController.searchText.value;
    _libraryModified.value; // allow manual refresh
    return _podcastLibraryService.getFilteredPodcastsWithMetadata(
      filterText.text,
    );
  });

  late final subscriptions = B.family((Item podcastItem) {
    return B.derived(() {
      return podcasts.value.any((p) => p.feedUrl == podcastItem.feedUrl);
    });
  });

  late final episodeMedias = B.family((Item podcastItem) {
    return B.future(() => _podcastService.findEpisodes(item: podcastItem));
  });

  Future<void> addPodcast(PodcastMetadata metadata) async {
    await _podcastLibraryService.addPodcast(metadata);
    _libraryModified.toggle();
  }

  Future<void> removePodcast({required String feedUrl}) async {
    await _podcastLibraryService.removePodcast(feedUrl);
    _libraryModified.toggle();
  }
}
