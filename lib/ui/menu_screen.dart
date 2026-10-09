/// Main menu — "Flip Discs · Gallery Edition".
///
/// Title top → logo hero → Play vs Bot / 2 Players / Watch demo glass
/// buttons → depth-level pills → micro-caption → bottom tab bar
/// (Play / Archive / Rules).

library;
import 'package:flutter/material.dart';

import '../game/ai.dart';
import '../game/controller.dart';
import '../services/audio.dart';
import '../services/iap_service.dart';
import '../services/settings.dart';
import '../theme/gallery.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'tokens.dart';
import 'widgets.dart';

class MenuScreen extends StatefulWidget {
  final AppSettings settings;
  final StoreService store;
  const MenuScreen(
      {super.key, required this.settings, required this.store});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _tab = 0; // 0 play, 1 archive, 2 rules

  GalleryThemeDef get _t => widget.settings.gallery;

  @override
  void initState() {
    super.initState();
    AudioService.I.menuMusic();
  }

  void _openGame(GameMode mode) {
    AudioService.I.click();
    AudioService.I.tapHaptic();
    Navigator.of(context)
        .push(_route(GameScreen(
            settings: widget.settings,
            mode: mode,
            store: widget.store)))
        .then((_) => AudioService.I.menuMusic());
  }

  void _openSettings() {
    AudioService.I.click();
    Navigator.of(context).push(_route(SettingsScreen(
        settings: widget.settings, store: widget.store)));
  }

  void _openPro() {
    AudioService.I.click();
    Navigator.of(context).push(_route(ProScreen(
      settings: widget.settings,
      store: widget.store,
    )));
  }

  static PageRouteBuilder _route(Widget page) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      );

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return GalleryScope(
      theme: t,
      child: GalleryBackdrop(
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
                    subtitle: 'GALLERY EDITION · REVERSI',
                    onBack: null,
                    actions: [
                      if (!widget.settings.isPro)
                        CircleIconButton(
                          icon: Icons.workspace_premium_outlined,
                          onTap: _openPro,
                        ),
                      if (!widget.settings.isPro)
                        const SizedBox(width: 8),
                      CircleIconButton(
                        icon: Icons.settings_outlined,
                        onTap: _openSettings,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: widget.settings,
                    builder: (_, _) => IndexedStack(
                      index: _tab,
                      children: [
                        _playTab(),
                        _archiveTab(),
                        _rulesTab(),
                      ],
                    ),
                  ),
                ),
                _bottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- play tab
  Widget _playTab() {
    final t = _t;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      children: [
        _logoHero(),
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
        const SizedBox(height: 12),
        GlassButton(
          label: 'Watch demo',
          sublabel: 'Two bots, zero pressure',
          icon: Icons.play_circle_outline_rounded,
          onTap: () => _openGame(GameMode.demo),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text('DEPTH LEVEL',
              style: t.labelCaps(size: 10)),
        ),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: widget.settings,
          builder: (_, _) => DifficultyPills(
            selected: widget.settings.difficulty.index,
            hardLocked: !widget.settings.isPro,
            onChanged: (i) {
              if (i == 2 && !widget.settings.isPro) {
                AudioService.I.click();
                _openPro();
                return;
              }
              AudioService.I.click();
              widget.settings
                  .setDifficulty(BotDifficulty.values[i]);
            },
          ),
        ),
        if (!widget.settings.isPro) ...[
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: _openPro,
              child: Text(
                'HARD MODE IS A PRO FEATURE',
                style: t.labelCaps(
                    size: 10, color: t.accent),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        const MicroCaption('A game of outflanking · 8 × 8'),
      ],
    );
  }

  /// Logo hero: the game logo in a brass-ringed frame.
  Widget _logoHero() {
    final t = _t;
    return FrostedCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: t.accent, width: 2),
              boxShadow: G.cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/flipdiscs_logo.png',
                fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: t.cardFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.line, width: 1),
                ),
                child: Text('PLATE NO. 01',
                    style: t.labelCaps(size: 9)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- archive tab
  Widget _archiveTab() {
    final t = _t;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      children: [
        Center(
          child: Text('PERSONAL ANTHOLOGY',
              style: t.labelCaps(size: 10)),
        ),
        const SizedBox(height: 4),
        Center(
            child: Text('Every exhibition, remembered.',
                style: t.italicCaption)),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: widget.settings,
          builder: (_, _) {
            final s = widget.settings;
            return FrostedCard(
              child: Column(
                children: [
                  _statRow('EXHIBITIONS PLAYED', '${s.gamesPlayed}'),
                  const Hairline(),
                  _statRow('VS BOT — WON', '${s.botWins}'),
                  const Hairline(),
                  _statRow('VS BOT — LOST', '${s.botLosses}'),
                  const Hairline(),
                  _statRow('VS BOT — DRAWN', '${s.botDraws}'),
                  const Hairline(),
                  _statRow('2 PLAYERS — BLACK', '${s.p2BlackWins}'),
                  const Hairline(),
                  _statRow('2 PLAYERS — WHITE', '${s.p2WhiteWins}'),
                  const Hairline(),
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

  Widget _statRow(String label, String value) {
    final t = _t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: t.labelCaps(size: 11))),
          Text(value, style: t.numerals(size: 17)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ rules tab
  Widget _rulesTab() {
    final t = _t;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      children: [
        Center(
          child: Text('RULES', style: t.labelCaps(size: 10)),
        ),
        const SizedBox(height: 4),
        Center(
            child: Text('The art of the outflank.',
                style: t.italicCaption)),
        const SizedBox(height: 16),
        FrostedCard(
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
    final t = _t;
    final items = [
      (Icons.sports_esports_outlined, 'Play'),
      (Icons.grid_view_rounded, 'Archive'),
      (Icons.menu_book_outlined, 'Rules'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 4, 24, 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: t.glassFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.line, width: 1),
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
                      color: active ? t.ink : t.muted),
                  const SizedBox(height: 2),
                  Text(items[i].$2,
                      style: t.labelCaps(
                          size: 9,
                          color: active ? t.ink : t.muted)),
                  const SizedBox(height: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? t.accent : Colors.transparent,
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

class _RuleBlock extends StatelessWidget {
  final String title;
  final String body;
  const _RuleBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final t = GalleryScope.themeOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.labelCaps(size: 11, color: t.ink)),
          const SizedBox(height: 6),
          Text(body, style: t.body),
        ],
      ),
    );
  }
}
