/// Game board screen — "Flip Discs · Exhibition".
///
/// Opponent tray (top) → live board → player tray (bottom). Every side has
/// its own tray: disc icon, renameable player name, live score, and a
/// narration line ("Mira is thinking…", "Bot plays e6", "Flipping 3
/// discs…"). The active side's tray is highlighted; nothing ever
/// auto-plays silently.

library;
import 'package:flutter/material.dart';

import '../game/ai.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import '../services/audio.dart';
import '../services/iap_service.dart';
import '../services/settings.dart';
import '../theme/gallery.dart';
import 'board.dart';
import 'disc.dart';
import 'game_over.dart';
import 'settings_screen.dart';
import 'tokens.dart';
import 'widgets.dart';

class GameScreen extends StatefulWidget {
  final AppSettings settings;
  final GameMode mode;
  final StoreService store;
  const GameScreen(
      {super.key,
      required this.settings,
      required this.mode,
      required this.store});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _c =
      GameController(settings: widget.settings, mode: widget.mode);
  bool _navigatedToGameOver = false;

  GalleryThemeDef get _t => widget.settings.gallery;

  @override
  void initState() {
    super.initState();
    AudioService.I.gameMusic();
    _c.addListener(_onGameChanged);
    _c.start();
  }

  void _onGameChanged() {
    if (_c.over && !_navigatedToGameOver) {
      _navigatedToGameOver = true;
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, _, _) => GameOverScreen(
              settings: widget.settings,
              mode: widget.mode,
              controller: _c,
              store: widget.store,
            ),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onGameChanged);
    _c.dispose();
    super.dispose();
  }

  void _toggleSound() {
    final s = widget.settings;
    AudioService.I.click();
    s.setMusicOn(!s.musicOn);
  }

  void _showPause() {
    AudioService.I.tapHaptic();
    _c.setPaused(true);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Pause',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => GalleryScope(
        theme: _t,
        child: _PauseOverlay(controller: _c, store: widget.store),
      ),
    ).then((_) {
      if (mounted && !_c.over) _c.setPaused(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return GalleryScope(
      theme: t,
      child: GalleryBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ListenableBuilder(
              listenable: _c,
              builder: (_, _) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: GalleryTopBar(
                      title: 'FLIP DISCS',
                      subtitle: widget.settings.exhibitionLabel,
                      onBack: () {
                        AudioService.I.click();
                        Navigator.of(context).pop();
                      },
                      actions: [
                        ListenableBuilder(
                          listenable: widget.settings,
                          builder: (_, _) => CircleIconButton(
                            icon: widget.settings.musicOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            active: widget.settings.musicOn,
                            onTap: _toggleSound,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleIconButton(
                          icon: Icons.pause_rounded,
                          onTap: _showPause,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Opponent tray (White side).
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _SideTray(
                      controller: _c,
                      side: white,
                      theme: t,
                    ),
                  ),
                  if (_c.passMessage != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(_c.passMessage!,
                          style: t.italicCaption
                              .copyWith(fontSize: 13),
                          textAlign: TextAlign.center),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: BoardView(
                            controller: _c,
                            theme: t,
                            accent: widget.settings.boardAccent,
                            discStyle: widget.settings.discStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Player tray (Black side).
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _SideTray(
                      controller: _c,
                      side: black,
                      theme: t,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MiniPill(
                        label: 'Undo',
                        icon: Icons.undo_rounded,
                        onTap: _c.engine.canUndo &&
                                _c.phase == TurnPhase.idle &&
                                !_c.over
                            ? _c.undo
                            : null,
                      ),
                      const SizedBox(width: 12),
                      MiniPill(
                        label: 'Menu',
                        icon: Icons.pause_rounded,
                        onTap: _showPause,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  MicroCaption(
                    'Outflank to flip · Round ${_c.round}'
                    '${_c.demoMode ? ' · Demo' : _c.vsBot ? ' · ${_difficultyName(_c.difficulty)}' : ' · Two players'}',
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _difficultyName(BotDifficulty d) => switch (d) {
        BotDifficulty.easy => 'Easy',
        BotDifficulty.medium => 'Medium',
        BotDifficulty.hard => 'Hard',
      };
}

/// One side's tray: its own disc, name, live score and narration line.
/// The active side is highlighted with the board accent; a bot that is
/// thinking shows a live "thinking" narration — never silent.
class _SideTray extends StatelessWidget {
  final GameController controller;
  final int side;
  final GalleryThemeDef theme;

  const _SideTray({
    required this.controller,
    required this.side,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final active = controller.displayTurn == side && !controller.over;
    final narration = controller.sideNarration(side);
    final thinking = controller.phase == TurnPhase.thinking && active;
    final count =
        side == black ? controller.blackCount : controller.whiteCount;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(G.rPill),
        border: Border.all(
          color: active
              ? controller.settings.boardAccent.frame
                  .withValues(alpha: 0.85)
              : t.line.withValues(alpha: 0.5),
          width: active ? 1.6 : 1,
        ),
        boxShadow: active ? G.cardShadow : null,
      ),
      child: FrostedCard(
        radius: G.rPill,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            Disc(
                side: side,
                style: controller.settings.discStyle,
                size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          controller
                              .nameOf(side)
                              .toUpperCase(),
                          style: t.labelCaps(
                              size: 10,
                              color: active ? t.ink : t.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (thinking) ...[
                        const SizedBox(width: 8),
                        const _ThinkingDots(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    narration.isEmpty
                        ? (active ? 'To move' : 'Waiting')
                        : narration,
                    style: t.body.copyWith(
                        fontSize: 12,
                        color: active ? t.sub : t.muted,
                        height: 1.25),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('$count', style: t.numerals(size: 20)),
          ],
        ),
      ),
    );
  }
}

/// Three softly pulsing dots for the "thinking" narration.
class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GalleryScope.themeOf(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_c.value * 3 - i * 0.5).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.only(right: 3),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.accent.withValues(alpha: 0.35 + 0.65 * phase),
            ),
          );
        }),
      ),
    );
  }
}

/// Quiet pause overlay: Resume / Restart / Settings / Main menu.
class _PauseOverlay extends StatelessWidget {
  final GameController controller;
  final StoreService store;
  const _PauseOverlay({required this.controller, required this.store});

  @override
  Widget build(BuildContext context) {
    final t = GalleryScope.themeOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: FrostedCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PAUSED',
                  style: t.labelCaps(size: 11)),
              const SizedBox(height: 8),
              Text('Take a breath.',
                  style: t.headline.copyWith(fontSize: 26)),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: DarkButton(
                  label: 'Resume',
                  icon: Icons.play_arrow_rounded,
                  onTap: () {
                    AudioService.I.click();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: GhostButton(
                  label: 'Restart',
                  onTap: () {
                    AudioService.I.click();
                    Navigator.of(context).pop();
                    controller.start();
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: GhostButton(
                  label: 'Settings',
                  onTap: () {
                    AudioService.I.click();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        transitionDuration:
                            const Duration(milliseconds: 280),
                        pageBuilder: (_, _, _) =>
                            GalleryScope(
                          theme: t,
                          child: SettingsScreen(
                              settings:
                                  controller.settings,
                              store: store),
                        ),
                        transitionsBuilder: (_, anim, _, child) =>
                            FadeTransition(
                                opacity: anim, child: child),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: GhostButton(
                  label: 'Main menu',
                  onTap: () {
                    AudioService.I.click();
                    Navigator.of(context).pop(); // close overlay
                    Navigator.of(context).pop(); // back to menu
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
