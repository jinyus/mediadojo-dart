import 'package:state_beacon/state_beacon.dart';

import '../common/media_type.dart';

class SearchTextController with BeaconController {
  late final searchText = TextEditingBeacon(text: '', group: B);

  late final searchTextDebounced = searchText.debounce(
    const Duration(milliseconds: 500),
  );

  late final searchType = B.writable(MediaType.podcast);
}
