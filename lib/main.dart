/// Flip Discs — a gallery-minimalist Reversi game.
///
/// Clean architecture:
///   game/engine.dart      — deterministic Reversi rules (pure Dart)
///   game/ai.dart          — Easy / Medium / Hard bot (RULES.md §11)
///   game/controller.dart  — state management (ChangeNotifier)
///   services/settings.dart — local persistence (shared_preferences)
///   services/audio.dart    — procedural audio via audioplayers
///   ui/*                   — gallery visual layer (Stitch design system)

library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/audio.dart';
import 'services/settings.dart';
import 'ui/menu_screen.dart';
import 'ui/tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);
  final settings = AppSettings();
  await settings.load();
  await AudioService.I.init();
  AudioService.I.syncSettings(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    hapticsOn: settings.hapticsOn,
    musicVolume: settings.musicVolume,
    sfxVolume: settings.sfxVolume,
  );
  settings.addListener(() {
    AudioService.I.syncSettings(
      musicOn: settings.musicOn,
      sfxOn: settings.sfxOn,
      hapticsOn: settings.hapticsOn,
      musicVolume: settings.musicVolume,
      sfxVolume: settings.sfxVolume,
    );
  });
  runApp(FlipDiscsApp(settings: settings));
}

class FlipDiscsApp extends StatefulWidget {
  final AppSettings settings;
  const FlipDiscsApp({super.key, required this.settings});

  @override
  State<FlipDiscsApp> createState() => _FlipDiscsAppState();
}

class _FlipDiscsAppState extends State<FlipDiscsApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle correctly: silence music off-screen.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      AudioService.I.pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      AudioService.I.resumeMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flip Discs',
      debugShowCheckedModeBanner: false,
      theme: G.theme,
      home: MenuScreen(settings: widget.settings),
    );
  }
}
