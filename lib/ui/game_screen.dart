/// Game board screen — "Flip Discs · Exhibition".
///
/// Minimal top bar (back / title / pause + sound) → live score strip with
/// frosted disc icons and turn pill → large 8×8 board → Undo + Menu pills
/// → micro-caption. Pause opens a quiet frosted overlay; game end pushes
/// the victory exhibition screen.

library;
import 'package:flutter/material.dart';

import '../game/ai.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import '../services/audio.dart';
import '../services/settings.dart';
import 'board.dart';
import 'disc.dart';
import 'game_over.dart';
import 'settings_screen.dart';
import 'tokens.dart';
import 'widgets.dart';

class GameScreen extends StatefulWidget {
  final AppSettings settings;
  final GameMode mode;
  const GameScreen({super.key, required this.settings, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _c =
      GameController(settings: widget.settings, mode: widget.mode);
  bool _navigatedToGameOver = false;

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
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, _, _) => GameOverScreen(
              settings: widget.settings,
              mode: widget.mode,
              controller: _c,
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
      pageBuilder: (_, _, _) => _PauseOverlay(controller: _c),
    ).then((_) {
      if (mounted && !_c.over) _c.setPaused(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GalleryBackdrop(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _scoreStrip(),
                ),
                if (_c.passMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_c.passMessage!,
                      style: G.italicCaption.copyWith(fontSize: 13)),
                ],
                const SizedBox(height: 10),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: BoardView(controller: _c),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MiniPill(
                      label: 'Undo',
                      icon: Icons.undo_rounded,
                      onTap: _c.engine.canUndo &&
                              !_c.botThinking &&
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
                const SizedBox(height: 12),
                MicroCaption(
                  'Outflank to flip · Round ${_c.round}'
                  '${_c.vsBot ? ' · Difficulty: ${_difficultyName(_c.difficulty)}' : ' · Two players'}',
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreStrip() {
    final leftIsYou = _c.vsBot;
    final leftLabel = leftIsYou ? 'YOU' : 'BLACK';
    final rightLabel = leftIsYou ? 'BOT' : 'WHITE';
    final leftSide = black;
    final rightSide = white;
    final leftCount = _c.blackCount;
    final rightCount = _c.whiteCount;
    final leftActive = _c.turn == leftSide && !_c.over;
    final rightActive = _c.turn == rightSide && !_c.over;

    return FrostedCard(
      radius: G.rPill,
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Disc(side: leftSide, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leftLabel,
                  style: G.labelCaps(
                      size: 9,
                      color: leftActive ? G.ink : G.basalt)),
              Text('$leftCount', style: G.numerals(size: 17)),
            ],
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: G.ink.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: G.brass,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(_c.turnLabel.toUpperCase(),
                        style: G.labelCaps(
                            size: 9, color: G.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rightLabel,
                  style: G.labelCaps(
                      size: 9,
                      color: rightActive ? G.ink : G.basalt)),
              Text('$rightCount', style: G.numerals(size: 17)),
            ],
          ),
          const SizedBox(width: 10),
          Disc(side: rightSide, size: 26),
        ],
      ),
    );
  }

  String _difficultyName(BotDifficulty d) => switch (d) {
        BotDifficulty.easy => 'Easy',
        BotDifficulty.medium => 'Medium',
        BotDifficulty.hard => 'Hard',
      };
}

/// Quiet pause overlay: Resume / Restart / Settings / Main menu.
class _PauseOverlay extends StatelessWidget {
  final GameController controller;
  const _PauseOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: FrostedCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PAUSED',
                  style: G.labelCaps(size: 11, color: G.basalt)),
              const SizedBox(height: 8),
              Text('Take a breath.',
                  style: G.headline.copyWith(fontSize: 26)),
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
                        pageBuilder: (_, _, _) => SettingsScreen(
                            settings: controller.settings),
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
