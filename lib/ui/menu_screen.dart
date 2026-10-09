/// Main menu — "Flip Discs · Curated Edition".
///
/// Title top → photographic still-life hero → Play vs Bot / 2 Players
/// glass buttons → depth-level pills → micro-caption → bottom tab bar
/// (Play / Archive / Rules).

library;
import 'package:flutter/material.dart';

import '../game/ai.dart';
import '../game/controller.dart';
import '../services/audio.dart';
import '../services/settings.dart';
import 'disc.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'tokens.dart';
import 'widgets.dart';

class MenuScreen extends StatefulWidget {
  final AppSettings settings;
  const MenuScreen({super.key, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _tab = 0; // 0 play, 1 archive, 2 rules

  @override
  void initState() {
    super.initState();
    AudioService.I.menuMusic();
  }

  void _openGame(GameMode mode) {
    AudioService.I.click();
    AudioService.I.tapHaptic();
    Navigator.of(context)
        .push(_route(GameScreen(settings: widget.settings, mode: mode)))
        .then((_) => AudioService.I.menuMusic());
  }

  void _openSettings() {
    AudioService.I.click();
    Navigator.of(context).push(_route(SettingsScreen(settings: widget.settings)));
  }

  static PageRouteBuilder _route(Widget page) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      );

  @override
  Widget build(BuildContext context) {
    return GalleryBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: GalleryTopBar(
                  title: 'FLIP DISCS',
                  subtitle: 'CURATED EDITION · REVERSI',
                  onBack: null,
                  actions: [
                    CircleIconButton(
                      icon: Icons.settings_outlined,
                      onTap: _openSettings,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [
                    _playTab(),
                    _archiveTab(),
                    _rulesTab(),
                  ],
                ),
              ),
              _bottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- play tab
  Widget _playTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      children: [
        _heroStillLife(),
        const SizedBox(height: 18),
        GlassButton(
          label: 'Play vs Bot',
          sublabel: 'Algorithmic adversary',
          onTap: () => _openGame(GameMode.vsBot),
        ),
        const SizedBox(height: 12),
        GlassButton(
          label: '2 Players',
          sublabel: 'Shared local display',
          onTap: () => _openGame(GameMode.twoPlayer),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text('DEPTH LEVEL',
              style: G.labelCaps(size: 10, color: G.basalt)),
        ),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: widget.settings,
          builder: (_, _) => DifficultyPills(
            selected: widget.settings.difficulty.index,
            onChanged: (i) {
              AudioService.I.click();
              widget.settings
                  .setDifficulty(BotDifficulty.values[i]);
            },
          ),
        ),
        const SizedBox(height: 18),
        const MicroCaption('A game of outflanking · 8 × 8'),
      ],
    );
  }

  /// Frosted glass card holding a small physical still life: a matte
  /// board corner with frosted discs, "PLATE NO. 01".
  Widget _heroStillLife() {
    return FrostedCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF201F1D),
                    Color(0xFF141312),
                    Color(0xFF0F0E0D)
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x30000000),
                      blurRadius: 16,
                      offset: Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: _StillLifePainter(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: G.outlineVariant, width: 1),
                ),
                child: Text('PLATE NO. 01',
                    style: G.labelCaps(size: 9, color: G.onSurfaceVariant)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- archive tab
  Widget _archiveTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      children: [
        Center(
          child: Text('PERSONAL ANTHOLOGY',
              style: G.labelCaps(size: 10, color: G.basalt)),
        ),
        const SizedBox(height: 4),
        Center(child: Text('Every exhibition, remembered.', style: G.italicCaption)),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: widget.settings,
          builder: (_, _) {
            final s = widget.settings;
            return FrostedCard(
              child: Column(
                children: [
                  _statRow('EXHIBITIONS PLAYED', '${s.gamesPlayed}'),
                  const _Hairline(),
                  _statRow('VS BOT — WON', '${s.botWins}'),
                  const _Hairline(),
                  _statRow('VS BOT — LOST', '${s.botLosses}'),
                  const _Hairline(),
                  _statRow('VS BOT — DRAWN', '${s.botDraws}'),
                  const _Hairline(),
                  _statRow('2 PLAYERS — BLACK', '${s.p2BlackWins}'),
                  const _Hairline(),
                  _statRow('2 PLAYERS — WHITE', '${s.p2WhiteWins}'),
                  const _Hairline(),
                  _statRow('2 PLAYERS — DRAWN', '${s.p2Draws}'),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        const MicroCaption('Mastery recorded to personal anthology'),
      ],
    );
  }

  Widget _statRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: G.labelCaps(
                        size: 11, color: G.onSurfaceVariant))),
            Text(value, style: G.numerals(size: 17)),
          ],
        ),
      );

  // ------------------------------------------------------------ rules tab
  Widget _rulesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      children: [
        Center(
          child:
              Text('RULES', style: G.labelCaps(size: 10, color: G.basalt)),
        ),
        const SizedBox(height: 4),
        Center(
            child:
                Text('The art of the outflank.', style: G.italicCaption)),
        const SizedBox(height: 16),
        const FrostedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleBlock(
                title: 'OBJECTIVE',
                body:
                    'Finish with more of your discs on the board than your opponent. Every disc you place must trap rival discs — all trapped discs flip to your colour.',
              ),
              _RuleBlock(
                title: 'SETUP',
                body:
                    'Black moves first. The four centre squares begin with two black and two white discs on the diagonal.',
              ),
              _RuleBlock(
                title: 'LEGAL MOVES',
                body:
                    'Place one disc on an empty square so that, in at least one straight line, a run of rival discs is bracketed between your new disc and another of yours. Every bracketed disc flips.',
              ),
              _RuleBlock(
                title: 'PASSES',
                body:
                    'If you have no legal move you pass automatically — and only then. If neither side can move, the exhibition ends at once.',
              ),
              _RuleBlock(
                title: 'WINNING',
                body:
                    'Most discs when the board is full or nobody can move wins. Equal discs is a draw. Corners can never be flipped once taken — they are forever.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const MicroCaption('Corners are forever — grab them early'),
      ],
    );
  }

  // ---------------------------------------------------------- bottom nav
  Widget _bottomNav() {
    final items = [
      (Icons.sports_esports_outlined, 'Play'),
      (Icons.grid_view_rounded, 'Archive'),
      (Icons.menu_book_outlined, 'Rules'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 4, 24, 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: G.glassWhite,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: G.outlineVariant, width: 1),
        boxShadow: G.cardShadow,
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == _tab;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                AudioService.I.tapHaptic();
                setState(() => _tab = i);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(items[i].$1,
                      size: 20,
                      color: active ? G.ink : G.basalt),
                  const SizedBox(height: 2),
                  Text(items[i].$2,
                      style: G.labelCaps(
                          size: 9,
                          color: active ? G.ink : G.basalt)),
                  const SizedBox(height: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? G.brass : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: G.outlineVariant.withValues(alpha: 0.6),
      );
}

class _RuleBlock extends StatelessWidget {
  final String title;
  final String body;
  const _RuleBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: G.labelCaps(size: 11, color: G.ink)),
          const SizedBox(height: 6),
          Text(body, style: G.body),
        ],
      ),
    );
  }
}

/// Small painted still life: matte board corner with resting discs,
/// soft key light from the upper-left.
class _StillLifePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Etched grid suggestion.
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = G.boardGrid;
    _grid(canvas, size, grid);

    // A few resting discs, arranged like a gallery still life.
    const specs = [
      (0.30, 0.62, 0.16, 2),
      (0.52, 0.44, 0.19, 1),
      (0.74, 0.60, 0.15, 2),
      (0.44, 0.78, 0.13, 1),
      (0.68, 0.26, 0.12, 2),
    ];
    for (final s in specs) {
      final r = size.width * s.$3;
      final c = Offset(size.width * s.$1, size.height * s.$2);
      final p = DiscPainter(side: s.$4);
      canvas.save();
      canvas.translate(c.dx - r, c.dy - r);
      p.paint(canvas, Size(r * 2, r * 2));
      canvas.restore();
    }

    // Soft key-light wash from upper-left.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.6, -0.7),
          radius: 1.1,
          colors: [
            Color(0x14FFFFFF),
            Color(0x00000000),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _grid(Canvas canvas, Size size, Paint grid) {
    const n = 5;
    for (var i = 0; i <= n; i++) {
      final x = size.width * i / n;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      final y = size.height * i / n;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
