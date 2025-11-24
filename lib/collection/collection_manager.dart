import 'package:flutter/foundation.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:state_beacon/state_beacon.dart';

import '../common/media_type.dart';

class CollectionManager {
  CollectionManager() {
    textChangedCommand = Command.createSync((s) => s, initialValue: '');
  }
  final mediaTypeNotifier = ValueNotifier<MediaType>(MediaType.podcast);

  late Command<String, String> textChangedCommand;
}

class CollectionController with BeaconController {
  late final searchText = TextEditingBeacon(text: '', group: B);

  late final searchTextDebounced = searchText.debounce(
    const Duration(milliseconds: 500),
  );

  late final mediaType = B.writable(MediaType.podcast);
}
