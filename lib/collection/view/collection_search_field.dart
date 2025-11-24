import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../common/media_type.dart';
import '../../common/view/theme.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../register_dependencies.dart';

class CollectionSearchField extends StatelessWidget {
  const CollectionSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    final colController = collectionControllerRef();
    final searchType = colController.mediaType.watch(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kBigPadding,
      ).copyWith(top: kBigPadding, bottom: kSmallPadding),
      child: TextField(
        controller: colController.searchText.controller,
        decoration: InputDecoration(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colorScheme.primary),
            borderRadius: BorderRadius.circular(6),
          ),
          label: Text(searchType.localize(context)),
          hint: Text(searchType.localize(context)),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: MediaType.values
                .map(
                  (e) => IconButton(
                    style: getTextFieldSuffixStyle(context),
                    isSelected: e == searchType,
                    icon: Icon(e.iconData()),
                    tooltip: e.localize(context),
                    onPressed: () {
                      colController.mediaType.value = e;
                    },
                  ),
                )
                .toList(),
          ),
          suffixIcon: IconButton(
            style: getTextFieldSuffixStyle(context),
            icon: const Icon(Icons.clear),
            onPressed: () {
              colController.searchText.text = '';
            },
          ),
        ),
      ),
    );
  }
}
