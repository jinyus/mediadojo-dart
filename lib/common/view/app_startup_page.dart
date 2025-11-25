import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../app/app.dart';
import '../../app/home.dart';
import '../../register_dependencies.dart';
import 'error_page.dart';
import 'splash_page.dart';

class AppStartUpPage extends StatefulWidget {
  const AppStartUpPage({
    super.key,
    this.lightTheme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
  });

  final ThemeData? lightTheme,
      darkTheme,
      highContrastTheme,
      highContrastDarkTheme;

  @override
  State<AppStartUpPage> createState() => _AppStartUpPageState();
}

class _AppStartUpPageState extends State<AppStartUpPage>
    with BeaconControllerMixin {
  late final FutureBeacon<void> appStart;

  @override
  void initState() {
    appStart = B.future(startUp);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return switch (appStart.watch(context)) {
      AsyncData() => App(
        lightTheme: widget.lightTheme,
        darkTheme: widget.darkTheme,
        highContrastDarkTheme: widget.highContrastDarkTheme,
        highContrastTheme: widget.highContrastTheme,
        child: const Home(),
      ),
      AsyncError e => StaticApp(
        themeMode: ThemeMode.system,
        lightTheme: widget.lightTheme,
        darkTheme: widget.darkTheme,
        highContrastDarkTheme: widget.highContrastDarkTheme,
        highContrastTheme: widget.highContrastTheme,
        child: ErrorPage(error: e.toString()),
      ),
      _ => StaticApp(
        themeMode: ThemeMode.system,
        lightTheme: widget.lightTheme,
        darkTheme: widget.darkTheme,
        highContrastDarkTheme: widget.highContrastDarkTheme,
        highContrastTheme: widget.highContrastTheme,
        child: const SplashPage(),
      ),
    };
  }
}
