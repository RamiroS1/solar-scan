import 'package:flutter/material.dart';

import 'core.dart';
import 'painters.dart';
import 'screens/projects.dart';

void main() => runApp(const SolarScanApp());

class SolarScanApp extends StatefulWidget {
  const SolarScanApp({super.key});
  @override
  State<SolarScanApp> createState() => _SolarScanAppState();
}

class _SolarScanAppState extends State<SolarScanApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Store(
      state: _state,
      child: MaterialApp(
        title: 'SolarScan',
        debugShowCheckedModeBanner: false,
        theme: T.theme(),
        home: const SplashScreen(),
      ),
    );
  }
}
