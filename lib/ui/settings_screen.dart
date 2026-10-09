/// Settings — players, appearance, sound & gameplay.
///
/// Renameable player names (every slot, persisted), theme / disc-style /
/// board-accent pickers, custom theme creator, music/SFX controls,
/// difficulty, hints, haptics, Pro entry and reset.

library;
import 'package:flutter/material.dart';

import '../game/ai.dart';
import '../services/audio.dart';
import '../services/iap_service.dart';
import '../services/settings.dart';
import '../theme/gallery.dart';
import 'custom_theme_screen.dart';
import 'pro_screen.dart';
import 'tokens.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  final AppSettings settings;
  final StoreService store;
  const SettingsScreen(
      {super.key, required this.settings, required this.store});

  void _openPro(BuildContext context) {
    AudioService.I.click();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => ProScreen(
          settings: settings,
          store: store,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _openCustomTheme(BuildContext context) {
    AudioService.I.click();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => CustomThemeScreen(settings: settings),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = settings.gallery;
    return GalleryScope(
      theme: t,
      child: GalleryBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ListenableBuilder(
              listenable: settings,
              builder: (_, _) {
                final th = settings.gallery;
                return ListView(
                  padding:
                      const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  children: [
                    GalleryTopBar(
                      title: 'SETTINGS',
                      subtitle: settings.exhibitionLabel,
                      onBack: () {
                        AudioService.I.click();
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'Players, gallery & resonance',
                        style: th.italicCaption,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle(th, 'PLAYERS'),
                    const SizedBox(height: 8),
                    _playersCard(context, th),
                    const SizedBox(height: 18),
                    _sectionTitle(th, 'APPEARANCE'),
                    const SizedBox(height: 8),
                    _appearanceCard(context, th),
                    const SizedBox(height: 18),
                    _sectionTitle(th, 'SOUND'),
                    const SizedBox(height: 8),
                    _soundCard(th),
                    const SizedBox(height: 18),
                    _sectionTitle(th, 'GAMEPLAY'),
                    const SizedBox(height: 8),
                    _gameplayCard(context, th),
                    const SizedBox(height: 18),
                    _proCard(context, th),
                    const SizedBox(height: 18),
                    Center(
                      child: FrostedCard(
                        onTap: () {
                          AudioService.I.click();
                          settings.resetToDefaults();
                        },
                        radius: G.rPill,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 13),
                        child: Text('RESET TO DEFAULTS',
                            style: th.buttonLabel.copyWith(
                                fontSize: 12,
                                letterSpacing: 1.6)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const MicroCaption(
                        'Handcrafted digital mechanics for mindful competition'),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(GalleryThemeDef th, String s) => Center(
        child: Text(s, style: th.labelCaps(size: 10)),
      );

  // ------------------------------------------------------------ players
  Widget _playersCard(BuildContext context, GalleryThemeDef th) {
    return FrostedCard(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        children: [
          _nameRow(context, th, 0, 'Black discs', 'Moves first'),
          const Hairline(),
          _nameRow(context, th, 1, 'White discs', 'Moves second'),
        ],
      ),
    );
  }

  Widget _nameRow(BuildContext context, GalleryThemeDef th, int slot,
      String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: th.body.copyWith(
                        fontSize: 14,
                        color: th.ink,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: th.body
                        .copyWith(fontSize: 12, color: th.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _NameField(settings: settings, th: th, slot: slot),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- appearance
  Widget _appearanceCard(BuildContext context, GalleryThemeDef th) {
    return FrostedCard(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        children: [
          _pickerRow(
            th: th,
            title: 'Gallery theme',
            subtitle: settings.gallery.name,
            swatch: _themeSwatch(settings.gallery),
            locked: false,
            onTap: () => _openCatalog(
              context,
              title: 'GALLERY THEME',
              options: [
                for (final t in GalleryThemes.all)
                  _CatalogOption(
                    id: t.id,
                    name: t.name,
                    blurb:
                        '${t.bg.toARGB32().toRadixString(16).substring(2).toUpperCase()} gallery',
                    swatch: _themeSwatch(t),
                    locked:
                        !settings.isPro && GalleryThemes.isPro(t.id),
                    selected: settings.themeId == t.id,
                  ),
                _CatalogOption(
                  id: 'custom',
                  name: 'My Creation',
                  blurb: 'Your custom gallery',
                  swatch: _themeSwatch(settings.customTheme),
                  locked: !settings.isPro,
                  selected: settings.themeId == 'custom',
                ),
              ],
              onPick: (id) => settings.setTheme(id),
            ),
          ),
          const Hairline(),
          _pickerRow(
            th: th,
            title: 'Disc style',
            subtitle: settings.discStyle.name,
            swatch: _discSwatch(settings.discStyle),
            locked: false,
            onTap: () => _openCatalog(
              context,
              title: 'DISC STYLE',
              options: [
                for (final s in DiscStyles.all)
                  _CatalogOption(
                    id: s.id,
                    name: s.name,
                    blurb: s.blurb,
                    swatch: _discSwatch(s),
                    locked:
                        !settings.isPro && DiscStyles.isPro(s.id),
                    selected: settings.discStyleId == s.id,
                  ),
              ],
              onPick: (id) => settings.setDiscStyle(id),
            ),
          ),
          const Hairline(),
          _pickerRow(
            th: th,
            title: 'Board accent',
            subtitle: settings.boardAccent.name,
            swatch: _accentSwatch(settings.boardAccent),
            locked: false,
            onTap: () => _openCatalog(
              context,
              title: 'BOARD ACCENT',
              options: [
                for (final a in BoardAccents.all)
                  _CatalogOption(
                    id: a.id,
                    name: a.name,
                    blurb: a.blurb,
                    swatch: _accentSwatch(a),
                    locked:
                        !settings.isPro && BoardAccents.isPro(a.id),
                    selected: settings.accentId == a.id,
                  ),
              ],
              onPick: (id) => settings.setAccent(id),
            ),
          ),
          const Hairline(),
          _pickerRow(
            th: th,
            title: 'Custom theme',
            subtitle: settings.isPro
                ? 'Design your own gallery'
                : 'PRO — design your own gallery',
            swatch: _themeSwatch(settings.customTheme),
            locked: !settings.isPro,
            onTap: () {
              if (settings.isPro) {
                _openCustomTheme(context);
              } else {
                _openPro(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _pickerRow({
    required GalleryThemeDef th,
    required String title,
    required String subtitle,
    required Widget swatch,
    required bool locked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        AudioService.I.tapHaptic();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            swatch,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title,
                            style: th.body.copyWith(
                                fontSize: 14,
                                color: th.ink,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock_outline_rounded,
                            size: 13, color: th.muted),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: th.body
                          .copyWith(fontSize: 12, color: th.muted),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: th.muted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _themeSwatch(GalleryThemeDef t) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.line, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(child: Container(color: t.bg)),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Container(color: t.board)),
                  Expanded(child: Container(color: t.accent)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _discSwatch(DiscStyleDef s) => SizedBox(
        width: 44,
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [s.darkTop, s.darkBottom],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [s.lightTop, s.lightBottom],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _accentSwatch(BoardAccentDef a) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: a.frame.withValues(alpha: 0.25),
          border: Border.all(color: a.frame, width: 2),
        ),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: a.hint, width: 1.5),
            ),
          ),
        ),
      );

  void _openCatalog(
    BuildContext context, {
    required String title,
    required List<_CatalogOption> options,
    required ValueChanged<String> onPick,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => GalleryScope(
          theme: settings.gallery,
          child: _CatalogScreen(
            title: title,
            options: options,
            onPick: (id) {
              AudioService.I.click();
              onPick(id);
            },
            onLockedTap: () => _openPro(context),
          ),
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // --------------------------------------------------------------- sound
  Widget _soundCard(GalleryThemeDef th) {
    return FrostedCard(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        children: [
          _row(
            th: th,
            title: 'Music',
            subtitle: 'Ambient soundscape',
            trailing: PhysicalToggle(
              value: settings.musicOn,
              onChanged: (v) {
                AudioService.I.click();
                settings.setMusicOn(v);
              },
            ),
          ),
          const Hairline(),
          _row(
            th: th,
            title: 'Sound effects',
            subtitle: 'Stone clack & rotation',
            trailing: PhysicalToggle(
              value: settings.sfxOn,
              onChanged: (v) {
                settings.setSfxOn(v);
                if (v) AudioService.I.click();
              },
            ),
          ),
          const Hairline(),
          _sliderRow(
            th: th,
            title: 'Music volume',
            valueLabel:
                '${(settings.musicVolume * 100).round()}%',
            value: settings.musicVolume,
            onChanged: settings.setMusicVolume,
          ),
          const Hairline(),
          _sliderRow(
            th: th,
            title: 'SFX volume',
            valueLabel:
                '${(settings.sfxVolume * 100).round()}%',
            value: settings.sfxVolume,
            onChanged: settings.setSfxVolume,
            onChangeEnd: (_) => AudioService.I.place(),
          ),
          const Hairline(),
          _row(
            th: th,
            title: 'Haptics',
            subtitle: 'Inertial strike response',
            trailing: PhysicalToggle(
              value: settings.hapticsOn,
              onChanged: (v) {
                settings.setHapticsOn(v);
                if (v) AudioService.I.tapHaptic();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- gameplay
  Widget _gameplayCard(BuildContext context, GalleryThemeDef th) {
    return FrostedCard(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Bot difficulty',
                          style: th.body.copyWith(
                              fontSize: 14,
                              color: th.ink,
                              fontWeight: FontWeight.w500)),
                    ),
                    Text('HEURISTIC ENGINE',
                        style: th.labelCaps(size: 9)),
                  ],
                ),
                const SizedBox(height: 10),
                DifficultyPills(
                  selected: settings.difficulty.index,
                  hardLocked: !settings.isPro,
                  onChanged: (i) {
                    if (i == 2 && !settings.isPro) {
                      _openPro(context);
                      return;
                    }
                    AudioService.I.click();
                    settings.setDifficulty(
                        BotDifficulty.values[i]);
                  },
                ),
              ],
            ),
          ),
          const Hairline(),
          _row(
            th: th,
            title: 'Show valid moves',
            subtitle: 'Subtle micro-ring hints',
            trailing: PhysicalToggle(
              value: settings.showHints,
              onChanged: (v) {
                AudioService.I.click();
                settings.setShowHints(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ pro
  Widget _proCard(BuildContext context, GalleryThemeDef th) {
    return FrostedCard(
      onTap: () => _openPro(context),
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: th.accent.withValues(alpha: 0.18),
              border: Border.all(color: th.accent, width: 1.5),
            ),
            child: Icon(Icons.workspace_premium_outlined,
                color: th.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    settings.isPro
                        ? 'FLIP DISCS PRO — ACTIVE'
                        : 'FLIP DISCS PRO',
                    style: th.body.copyWith(
                        fontSize: 14,
                        color: th.ink,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                    settings.isPro
                        ? 'Every theme, style & hard mode unlocked'
                        : 'Hard mode · 14 themes · 10 disc styles',
                    style: th.body
                        .copyWith(fontSize: 12, color: th.muted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: th.muted, size: 22),
        ],
      ),
    );
  }

  Widget _row({
    required GalleryThemeDef th,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: th.body.copyWith(
                        fontSize: 14,
                        color: th.ink,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: th.body
                        .copyWith(fontSize: 12, color: th.muted)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _sliderRow({
    required GalleryThemeDef th,
    required String title,
    required String valueLabel,
    required double value,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: th.body.copyWith(
                        fontSize: 14,
                        color: th.ink,
                        fontWeight: FontWeight.w500)),
              ),
              Text(valueLabel, style: th.numerals(size: 12)),
            ],
          ),
          GallerySlider(
            value: value,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _CatalogOption {
  final String id;
  final String name;
  final String blurb;
  final Widget swatch;
  final bool locked;
  final bool selected;
  const _CatalogOption({
    required this.id,
    required this.name,
    required this.blurb,
    required this.swatch,
    required this.locked,
    required this.selected,
  });
}

/// Full-screen catalog picker: swatch + name + blurb rows, lock on PRO.
class _CatalogScreen extends StatelessWidget {
  final String title;
  final List<_CatalogOption> options;
  final ValueChanged<String> onPick;
  final VoidCallback onLockedTap;

  const _CatalogScreen({
    required this.title,
    required this.options,
    required this.onPick,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = GalleryScope.themeOf(context);
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
                  title: title,
                  subtitle: 'CHOOSE YOUR GALLERY',
                  onBack: () {
                    AudioService.I.click();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  itemCount: options.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final o = options[i];
                    return FrostedCard(
                      onTap: () {
                        if (o.locked) {
                          AudioService.I.click();
                          onLockedTap();
                          return;
                        }
                        onPick(o.id);
                        Navigator.of(context).pop();
                      },
                      radius: G.rPill,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          o.swatch,
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(o.name,
                                          style: t.body.copyWith(
                                              fontSize: 14,
                                              color: t.ink,
                                              fontWeight:
                                                  FontWeight.w500),
                                          overflow:
                                              TextOverflow.ellipsis),
                                    ),
                                    if (o.locked) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                          Icons
                                              .lock_outline_rounded,
                                          size: 13,
                                          color: t.muted),
                                    ],
                                  ],
                                ),
                                Text(o.blurb,
                                    style: t.body.copyWith(
                                        fontSize: 12,
                                        color: t.muted)),
                              ],
                            ),
                          ),
                          if (o.selected)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: t.accent,
                              ),
                              child: Icon(Icons.check_rounded,
                                  size: 14, color: t.bg),
                            ),
                        ],
                      ),
                    );
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

/// Rename field that saves on every keystroke AND commits when the field
/// loses focus, so a rename is never lost if the user taps away without
/// hitting keyboard-done. Stateful so its controller/focus node survive the
/// parent screen's rebuilds (typed text is not reset on notify).
class _NameField extends StatefulWidget {
  final AppSettings settings;
  final GalleryThemeDef th;
  final int slot;

  const _NameField(
      {required this.settings, required this.th, required this.slot});

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _lastCommitted = '';

  @override
  void initState() {
    super.initState();
    _lastCommitted = widget.settings.playerName(widget.slot);
    _controller = TextEditingController(text: _lastCommitted);
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commit(_controller.text);
  }

  void _commit(String v) {
    if (v == _lastCommitted) return;
    _lastCommitted = v;
    widget.settings.setPlayerName(widget.slot, v);
    AudioService.I.click();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final th = widget.th;
    return SizedBox(
      width: 150,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLength: 16,
        textAlign: TextAlign.right,
        style: th.body.copyWith(color: th.ink, fontSize: 14),
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: th.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: th.accent, width: 1.5),
          ),
        ),
        onChanged: _commit,
        onSubmitted: (v) {
          _commit(v);
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }
}
