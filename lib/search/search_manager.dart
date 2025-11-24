import 'package:flutter/foundation.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:state_beacon/state_beacon.dart';

import '../common/media_type.dart';

class SearchManager {
  SearchManager() {
    textChangedCommand = Command.createSync((s) => s, initialValue: '');
  }

  late Command<String, String> textChangedCommand;
  final searchTypeNotifier = ValueNotifier<MediaType>(MediaType.podcast);
}

class SearchTextController with BeaconController {
  late final searchText = TextEditingBeacon(text: '', group: B);

  late final searchTextDebounced = searchText.debounce(
    const Duration(milliseconds: 500),
  );

  late final searchType = B.writable(MediaType.podcast);
}
