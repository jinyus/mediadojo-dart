import 'package:state_beacon/state_beacon.dart';

import '../collection/collection_controller.dart';
import '../player/data/station_media.dart';
import '../search/search_manager.dart';
import 'radio_library_service.dart';
import 'radio_service.dart';

class RadioController with BeaconController {
  RadioController({
    required RadioLibraryService radioLibraryService,
    required RadioService radioService,
    required SearchTextController searchController,
    required CollectionController collectionController,
  }) : _radioLibraryService = radioLibraryService,
       _radioService = radioService,
       _searchController = searchController,
       _collectionController = collectionController;

  final RadioLibraryService _radioLibraryService;
  final CollectionController _collectionController;
  final SearchTextController _searchController;
  final RadioService _radioService;

  late final searchResults = B.future(() async {
    final filterText = _searchController.searchTextDebounced.value.text;
    const emptyResults = <StationMedia>[];
    if (filterText.isEmpty) {
      return emptyResults;
    }
    final result = await _radioService.search(name: filterText);

    if (result == null) return emptyResults;

    return result.map((e) => StationMedia.fromStation(e)).toList();
  });

  late final _favoritesUpdated = B.writable(false);

  late final favoriteStations = B.future(() async {
    _favoritesUpdated.value;
    final filterText = _collectionController.searchText.value.text;
    final favoriteStations = _radioLibraryService.favoriteStations;
    final stations = <StationMedia>[];
    for (final stationId in favoriteStations) {
      StationMedia? media = StationMedia.getCachedStationMedia(stationId);
      if (media == null) {
        final station = await _radioService.getStationByUUID(stationId);
        if (station != null) {
          media = StationMedia.fromStation(station);
        }
      }
      if (media != null) {
        stations.add(media);
      }
    }

    return stations
        .where((e) => e.title.toLowerCase().contains(filterText.toLowerCase()))
        .toList();
  });

  late final isFavorite = B.family((String mediaID) {
    return B.derived(() {
      final stations = favoriteStations.value.lastData ?? [];
      return stations.any((m) => m.id == mediaID);
    });
  });

  Future<void> addFavoriteStation(String stationUuid) async {
    await _radioLibraryService.addFavoriteStation(stationUuid);
    _favoritesUpdated.toggle();
  }

  Future<void> removeFavoriteStation(String stationUuid) async {
    await _radioLibraryService.removeFavoriteStation(stationUuid);
    _favoritesUpdated.toggle();
  }
}
