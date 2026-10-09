/// Flip Discs — a gallery-minimalist Reversi game.
///
/// Clean architecture:
///   game/engine.dart      — deterministic Reversi rules (pure Dart)
///   game/ai.dart          — Easy / Medium / Hard bot (RULES.md §11)
///   game/controller.dart  — engine-owned turn state machine + watchdog
///   theme/gallery.dart    — theme / disc-style / board-accent catalogs
///   services/settings.dart — local persistence (shared_preferences)
///   services/audio.dart    — cached procedural audio via audioplayers
///   services/iap_service.dart — Play Billing (Pro + tip jar)
///   ui/*                   — gallery visual layer (Stitch design system)

library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/audio.dart';
import 'services/iap_service.dart';
import 'services/settings.dart';
import 'ui/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final settings = AppSettings();
  await settings.load();
  final store = StoreService();
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
  runApp(FlipDiscsApp(settings: settings, store: store));
}

class FlipDiscsApp extends StatefulWidget {
  final AppSettings settings;
  final StoreService store;
  const FlipDiscsApp(
      {super.key, required this.settings, required this.store});

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
    widget.store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their turn machines.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      AudioService.I.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      AudioService.I.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Flip Discs',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Manrope',
          scaffoldBackgroundColor: widget.settings.gallery.bg,
          colorScheme: ColorScheme.light(
            primary: widget.settings.gallery.ink,
            surface: widget.settings.gallery.surface,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: widget.settings.gallery.ink,
          ),
        ),
        home: SplashScreen(
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }
}
