/// Victory exhibition — the game-over screen.
///
/// Quiet "GAME OVER" caps → large serif result headline → frosted glass
/// final-count card with physical discs and tabular numerals → Play again
/// (matte charcoal) / Main menu (frosted glass).

library;
import 'package:flutter/material.dart';

import '../game/controller.dart';
import '../game/engine.dart';
import '../services/audio.dart';
import '../services/iap_service.dart';
import '../services/settings.dart';
import 'disc.dart';
import 'game_screen.dart';
import 'tokens.dart';
import 'widgets.dart';

class GameOverScreen extends StatelessWidget {
  final AppSettings settings;
  final GameMode mode;
  final GameController controller;
  final StoreService store;

  const GameOverScreen({
    super.key,
    required this.settings,
    required this.mode,
    required this.controller,
    required this.store,
  });

  bool get _vsBot => mode == GameMode.vsBot;
  bool get _demo => mode == GameMode.demo;
  int get _winner => controller.winner ?? 0;
  int get _black => controller.blackCount;
  int get _white => controller.whiteCount;

  String get _headline {
    if (_winner == 0) return 'Draw';
    final name = _winner == black
        ? settings.playerName(0)
        : settings.playerName(1);
    if (_demo) return '$name wins';
    if (!_vsBot) return '$name wins';
    return _winner == black ? 'You win' : '${settings.playerName(1)} wins';
  }

  String _leftName() {
    if (_demo || !_vsBot) return settings.playerName(0).toUpperCase();
    return 'YOU';
  }

  String _rightName() {
    if (_demo || !_vsBot) return settings.playerName(1).toUpperCase();
    return settings.playerName(1).toUpperCase();
  }

  String _turnsInWords(int n) {
    const ones = [
      '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
      'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
      'sixteen', 'seventeen', 'eighteen', 'nineteen'
    ];
    const tens = [
      '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy',
      'eighty', 'ninety'
    ];
    String word(int v) {
      if (v < 20) return ones[v];
      final t = v ~/ 10, o = v % 10;
      return o == 0 ? tens[t] : '${tens[t]}-$o';
    }

    if (n <= 99) return word(n);
    return '$n';
  }

  String get _endReason => controller.engine.emptyCount == 0
      ? 'Board full · no moves remained'
      : 'Neither side holds a legal move';

  String get _duration {
    final d = controller.duration;
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _playAgain(BuildContext context) {
    AudioService.I.click();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => GameScreen(
            settings: settings, mode: mode, store: store),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = settings.gallery;
    final total = _black + _white;
    final leftPct = total == 0 ? 0.0 : _black / total * 100;
    final rightPct = total == 0 ? 0.0 : _white / total * 100;

    return GalleryScope(
      theme: t,
      child: GalleryBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              children: [
                GalleryTopBar(
                  title: 'FLIP DISCS',
                  subtitle: settings.exhibitionLabel,
                  onBack: () {
                    AudioService.I.click();
                    Navigator.of(context).pop();
                  },
                  actions: const [],
                ),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: t.glassFill,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: t.line, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('GAME OVER',
                            style: t.labelCaps(size: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                    child: Text(_headline,
                        style: t.display,
                        textAlign: TextAlign.center)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Match concluded in ${_turnsInWords(controller.engine.moveNumber)} turns',
                    style: t.italicCaption,
                  ),
                ),
                const SizedBox(height: 20),
                FrostedCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                              'SESSION ${settings.gamesPlayed.toString().padLeft(2, '0')}',
                              style: t.labelCaps(size: 10)),
                          const SizedBox(width: 6),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: t.accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('FINAL RATIO',
                              style: t.labelCaps(size: 10)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: t.ink.withValues(alpha: 0.06),
                              borderRadius:
                                  BorderRadius.circular(999),
                            ),
                            child: Text('$total / 64',
                                style: t.numerals(
                                    size: 11, color: t.sub)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Disc(
                                    side: black,
                                    style: settings.discStyle,
                                    size: 64),
                                const SizedBox(height: 10),
                                Text('$_black',
                                    style: t.numerals(
                                        size: 34,
                                        weight: FontWeight.w400)),
                                const SizedBox(height: 2),
                                Text(_leftName(),
                                    style: t.labelCaps(size: 10)),
                                Text(
                                    '${leftPct.toStringAsFixed(1)}% control',
                                    style: t.body.copyWith(
                                        fontSize: 11,
                                        color: t.muted)),
                              ],
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 120,
                              color:
                                  t.line.withValues(alpha: 0.6)),
                          Expanded(
                            child: Column(
                              children: [
                                Disc(
                                    side: white,
                                    style: settings.discStyle,
                                    size: 64),
                                const SizedBox(height: 10),
                                Text('$_white',
                                    style: t.numerals(
                                        size: 34,
                                        weight: FontWeight.w400)),
                                const SizedBox(height: 2),
                                Text(_rightName(),
                                    style: t.labelCaps(size: 10)),
                                Text(
                                    '${rightPct.toStringAsFixed(1)}% control',
                                    style: t.body.copyWith(
                                        fontSize: 11,
                                        color: t.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                          height: 1,
                          color: t.line.withValues(alpha: 0.6)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: t.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_endReason,
                              style: t.italicCaption),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Mastery recorded to personal anthology',
                          style: t.body.copyWith(
                              fontSize: 12, color: t.muted)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FrostedCard(
                  radius: G.rPill,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 13),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('ARCHITECTURAL ARCHIVE',
                                style: t.labelCaps(
                                    size: 10, color: t.ink)),
                            const SizedBox(height: 2),
                            Text(
                                'Layout preserved to exhibition memory',
                                style: t.body.copyWith(
                                    fontSize: 12,
                                    color: t.muted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: t.ink.withValues(alpha: 0.06),
                          borderRadius:
                              BorderRadius.circular(999),
                        ),
                        child: Text(_duration,
                            style: t.numerals(
                                size: 11, color: t.sub)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: DarkButton(
                    label: 'Play again',
                    icon: Icons.refresh_rounded,
                    onTap: () => _playAgain(context),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GhostButton(
                    label: 'Main menu',
                    onTap: () {
                      AudioService.I.click();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const MicroCaption(
                    'Flip Discs · Curated edition no. 04'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
