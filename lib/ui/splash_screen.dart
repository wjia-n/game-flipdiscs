/// Launch splash, in two quiet beats:
///   1. WAJIHA company splash (official logo, untouched).
///   2. Game splash: logo + name + animated loading line + "Credits: WAJIHA".
///
/// Audio is prewarmed while the splash shows; menu music starts before
/// the menu appears so it never starts silently late.

library;
import 'package:flutter/material.dart';

import '../services/audio.dart';
import '../services/iap_service.dart';
import '../services/settings.dart';
import '../theme/gallery.dart';
import 'menu_screen.dart';
import 'tokens.dart';

class SplashScreen extends StatefulWidget {
  final AppSettings settings;
  final StoreService store;
  const SplashScreen(
      {super.key, required this.settings, required this.store});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyDone = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the company splash shows.
    await AudioService.I.prewarm();
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _companyDone = true);
    AudioService.I.menuMusic();
    _loader.forward();
    // Let the store initialize in the background; never block the splash.
    widget.store.init();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => MenuScreen(
          settings: widget.settings,
          store: widget.store,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.settings.gallery;
    return GalleryScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: _companyDone
              ? _GameSplash(
                  key: const ValueKey('game'),
                  theme: t,
                  loader: _loader,
                )
              : _CompanySplash(
                  key: const ValueKey('company'),
                  theme: t,
                ),
        ),
      ),
    );
  }
}

/// Beat 1: the official WAJIHA company splash.
class _CompanySplash extends StatelessWidget {
  final GalleryThemeDef theme;
  const _CompanySplash({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wajiha_logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            Text(
              'WAJIHA',
              style: theme.titleCaps.copyWith(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beat 2: game splash — logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final GalleryThemeDef theme;
  final AnimationController loader;
  const _GameSplash(
      {super.key, required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GalleryBackdrop(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: t.accent, width: 2),
                boxShadow: G.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/flipdiscs_logo.png',
                  fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('FLIP DISCS', style: t.display.copyWith(fontSize: 44)),
            const SizedBox(height: 6),
            Text(
              'THE GALLERY EDITION · REVERSI',
              style: t.labelCaps(size: 11),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: t.ink.withValues(alpha: 0.12),
                        border: Border.all(
                            color: t.accent.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: t.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1
                          ? 'Hanging the exhibition…'
                          : 'Ready!',
                      style: t.body.copyWith(
                          fontSize: 13,
                          color: t.sub.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: t.labelCaps(size: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
