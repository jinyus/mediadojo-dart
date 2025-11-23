import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../app/app_config.dart';
import '../../common/view/confirm.dart';
import '../../extensions/build_context_x.dart';
import '../../register_dependencies.dart';
import '../settings_manager.dart';

class SettingsDialog extends StatelessWidget with WatchItMixin {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = settingsControllerRef();
    return SimpleDialog(
      children: [
        ListTile(
          trailing: ElevatedButton(
            onPressed: controller.changeDownloadDir,
            child: Text(context.l10n.open),
          ),
          title: Text(context.l10n.downloadsDirectory),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  context.l10n.downloadsDirectoryDescription(AppConfig.appName),
                ),
              ),

              switch (controller.currentDir.watch(context)) {
                AsyncError(error: final e) => Text(e.toString()),
                AsyncData(value: final dir) => Text(dir),
                AsyncIdle() => Text(controller.currentDir.lastData ?? ''),
                AsyncLoading() => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              },
            ],
          ),
        ),
        ListTile(
          title: Text(context.l10n.resetAllSettings),
          trailing: ElevatedButton(
            onPressed: () => ConfirmationDialog.show(
              context: context,
              title: Text(context.l10n.resetAllSettingsConfirm),
              onConfirm: sharedPrefRef().clear,
            ),
            child: Text(context.l10n.resetAllSettings),
          ),
        ),
      ],
    );
  }
}
