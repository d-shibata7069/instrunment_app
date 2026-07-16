import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'theme/instrument_palette.dart';
import 'view/map_view.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WASA FEE Instrument Display',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: InstrumentPalette.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: InstrumentPalette.accent,
          brightness: Brightness.dark,
          surface: InstrumentPalette.surfaceRaised,
          error: InstrumentPalette.danger,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WASA FEE Instrument Display'),
    );
  }
}
