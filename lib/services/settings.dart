/// Local persistence for Flip Discs: settings, player names, appearance,
/// Pro unlock state and lightweight stats.
///
/// Backed by shared_preferences. No backend, everything on-device.

library;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/ai.dart';
import '../theme/gallery.dart';

class AppSettings extends ChangeNotifier {
  static const _kMusicOn = 'fd_music_on';
  static const _kSfxOn = 'fd_sfx_on';
  static const _kMusicVol = 'fd_music_vol';
  static const _kSfxVol = 'fd_sfx_vol';
  static const _kDifficulty = 'fd_difficulty';
  static const _kShowHints = 'fd_show_hints';
  static const _kHaptics = 'fd_haptics_on';
  static const _kNames = 'fd_player_names'; // StringList, 2 entries
  static const _kTheme = 'fd_theme_id';
  static const _kDiscStyle = 'fd_disc_style';
  static const _kAccent = 'fd_board_accent';
  static const _kIsPro = 'fd_is_pro';
  static const _kCustomPrefix = 'fd_custom_';

  static const _kGamesPlayed = 'fd_games_played';
  static const _kBotWins = 'fd_bot_wins';
  static const _kBotLosses = 'fd_bot_losses';
  static const _kBotDraws = 'fd_bot_draws';
  static const _kP2BlackWins = 'fd_p2_black_wins';
  static const _kP2WhiteWins = 'fd_p2_white_wins';
  static const _kP2Draws = 'fd_p2_draws';

  static const defaultNames = ['You', 'Bot'];

  SharedPreferences? _prefs; // null in unit tests (AppSettings.test)

  // --- settings ---
  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.7;
  double sfxVolume = 0.8;
  BotDifficulty difficulty = BotDifficulty.medium;
  bool showHints = true;
  bool hapticsOn = true;

  // --- players ---
  List<String> playerNames = List.of(defaultNames);

  // --- appearance ---
  String themeId = 'plaster';
  String discStyleId = 'frosted';
  String accentId = 'brass';
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Keys: bg, surface, ink, sub,
  /// muted, line, accent, board.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'bg': 0xFFE8E6E1,
    'surface': 0xFFFBF9F4,
    'ink': 0xFF1C1B19,
    'sub': 0xFF494740,
    'muted': 0xFF76736C,
    'line': 0xFFCBC6BD,
    'accent': 0xFFC29B38,
    'board': 0xFF141312,
  };

  /// Test constructor: defaults, no persistence.
  AppSettings.test();

  AppSettings();

  /// The user's custom-built theme, from stored colors.
  GalleryThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    final board = c('board');
    return GalleryThemeDef(
      id: 'custom',
      name: 'My Creation',
      bg: c('bg'),
      surface: c('surface'),
      ink: c('ink'),
      sub: c('sub'),
      muted: c('muted'),
      line: c('line'),
      accent: c('accent'),
      board: board,
      boardHi: _lighten(board, 0.08),
      boardLo: _darken(board, 0.08),
    );
  }

  static Color _lighten(Color c, double amt) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amt).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _darken(Color c, double amt) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amt).clamp(0.0, 1.0))
        .toColor();
  }

  /// Resolved theme / disc style / board accent.
  GalleryThemeDef get gallery =>
      GalleryThemes.byId(themeId, custom: customTheme);
  DiscStyleDef get discStyle => DiscStyles.byId(discStyleId);
  BoardAccentDef get boardAccent => BoardAccents.byId(accentId);

  String playerName(int slot) =>
      (slot >= 0 && slot < playerNames.length)
          ? playerNames[slot]
          : defaultNames[slot.clamp(0, 1)];

  // --- stats ---
  int gamesPlayed = 0;
  int botWins = 0;
  int botLosses = 0;
  int botDraws = 0;
  int p2BlackWins = 0;
  int p2WhiteWins = 0;
  int p2Draws = 0;

  /// "EXHIBITION 04"-style session label.
  String get exhibitionLabel =>
      'EXHIBITION ${(gamesPlayed + 1).toString().padLeft(2, '0')}';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    musicOn = p.getBool(_kMusicOn) ?? true;
    sfxOn = p.getBool(_kSfxOn) ?? true;
    musicVolume = p.getDouble(_kMusicVol) ?? 0.7;
    sfxVolume = p.getDouble(_kSfxVol) ?? 0.8;
    difficulty = BotDifficulty
        .values[p.getInt(_kDifficulty) ?? BotDifficulty.medium.index];
    showHints = p.getBool(_kShowHints) ?? true;
    hapticsOn = p.getBool(_kHaptics) ?? true;

    final names = p.getStringList(_kNames);
    if (names != null && names.length == 2) {
      playerNames = [
        for (var i = 0; i < 2; i++)
          names[i].trim().isEmpty ? defaultNames[i] : names[i].trim()
      ];
    }

    themeId = p.getString(_kTheme) ?? 'plaster';
    discStyleId = p.getString(_kDiscStyle) ?? 'frosted';
    accentId = p.getString(_kAccent) ?? 'brass';
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }

    gamesPlayed = p.getInt(_kGamesPlayed) ?? 0;
    botWins = p.getInt(_kBotWins) ?? 0;
    botLosses = p.getInt(_kBotLosses) ?? 0;
    botDraws = p.getInt(_kBotDraws) ?? 0;
    p2BlackWins = p.getInt(_kP2BlackWins) ?? 0;
    p2WhiteWins = p.getInt(_kP2WhiteWins) ?? 0;
    p2Draws = p.getInt(_kP2Draws) ?? 0;

    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return; // unit tests
    await p.setBool(_kMusicOn, musicOn);
    await p.setBool(_kSfxOn, sfxOn);
    await p.setDouble(_kMusicVol, musicVolume);
    await p.setDouble(_kSfxVol, sfxVolume);
    await p.setInt(_kDifficulty, difficulty.index);
    await p.setBool(_kShowHints, showHints);
    await p.setBool(_kHaptics, hapticsOn);
    await p.setStringList(_kNames, playerNames);
    await p.setString(_kTheme, themeId);
    await p.setString(_kDiscStyle, discStyleId);
    await p.setString(_kAccent, accentId);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
    await p.setInt(_kGamesPlayed, gamesPlayed);
    await p.setInt(_kBotWins, botWins);
    await p.setInt(_kBotLosses, botLosses);
    await p.setInt(_kBotDraws, botDraws);
    await p.setInt(_kP2BlackWins, p2BlackWins);
    await p.setInt(_kP2WhiteWins, p2WhiteWins);
    await p.setInt(_kP2Draws, p2Draws);
  }

  void _notify() => notifyListeners();

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (GalleryThemes.isPro(themeId)) {
      themeId = 'plaster';
      changed = true;
    }
    if (DiscStyles.isPro(discStyleId)) {
      discStyleId = 'frosted';
      changed = true;
    }
    if (BoardAccents.isPro(accentId)) {
      accentId = 'brass';
      changed = true;
    }
    if (difficulty == BotDifficulty.hard) {
      difficulty = BotDifficulty.medium;
      changed = true;
    }
    if (changed) {
      if (!silent) {
        _notify();
        _save();
      }
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    _notify();
    await _save();
  }

  Future<void> setMusicOn(bool v) async {
    musicOn = v;
    _notify();
    await _save();
  }

  Future<void> setSfxOn(bool v) async {
    sfxOn = v;
    _notify();
    await _save();
  }

  Future<void> setMusicVolume(double v) async {
    musicVolume = v.clamp(0.0, 1.0);
    _notify();
    await _save();
  }

  Future<void> setSfxVolume(double v) async {
    sfxVolume = v.clamp(0.0, 1.0);
    _notify();
    await _save();
  }

  Future<void> setDifficulty(BotDifficulty d) async {
    // Hard is a Pro feature.
    if (!isPro && d == BotDifficulty.hard) return;
    difficulty = d;
    _notify();
    await _save();
  }

  Future<void> setShowHints(bool v) async {
    showHints = v;
    _notify();
    await _save();
  }

  Future<void> setHapticsOn(bool v) async {
    hapticsOn = v;
    _notify();
    await _save();
  }

  Future<void> setPlayerName(int slot, String name) async {
    if (slot < 0 || slot > 1) return;
    final clean = name.trim();
    // Cap length so trays never overflow.
    playerNames[slot] =
        clean.isEmpty ? defaultNames[slot] : clean.substring(0, clean.length.clamp(0, 16));
    _notify();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && GalleryThemes.isPro(id)) return;
    themeId = id;
    _notify();
    await _save();
  }

  Future<void> setDiscStyle(String id) async {
    if (!isPro && DiscStyles.isPro(id)) return;
    discStyleId = id;
    _notify();
    await _save();
  }

  Future<void> setAccent(String id) async {
    if (!isPro && BoardAccents.isPro(id)) return;
    accentId = id;
    _notify();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    _notify();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    _notify();
    await _save();
  }

  /// Records a finished game: [vsBot] distinguishes the two modes.
  /// [winner] is 1 (Black), 2 (White) or 0 (draw); in vs-bot mode the
  /// human always plays Black.
  Future<void> recordResult({required bool vsBot, required int winner}) async {
    gamesPlayed++;
    if (vsBot) {
      if (winner == 0) {
        botDraws++;
      } else if (winner == 1) {
        botWins++;
      } else {
        botLosses++;
      }
    } else {
      if (winner == 0) {
        p2Draws++;
      } else if (winner == 1) {
        p2BlackWins++;
      } else {
        p2WhiteWins++;
      }
    }
    _notify();
    await _save();
  }

  Future<void> resetToDefaults() async {
    musicOn = true;
    sfxOn = true;
    musicVolume = 0.7;
    sfxVolume = 0.8;
    difficulty = BotDifficulty.medium;
    showHints = true;
    hapticsOn = true;
    themeId = 'plaster';
    discStyleId = 'frosted';
    accentId = 'brass';
    _notify();
    await _save();
  }
}
