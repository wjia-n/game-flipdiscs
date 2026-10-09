/// Gallery theme, disc-style and board-accent catalogs for Flip Discs.
///
/// Every entry stays inside the gallery-minimalist still-life world
/// (warm museum walls, frosted glass / stone discs, matte boards, a single
/// restrained metal accent). No neon, no glow — variety comes from different
/// wall tones, board lacquers and physical disc materials.
///
/// Free tier: the first 4 themes, first 3 disc styles and first 2 board
/// accents. Everything else is PRO.

library;
import 'package:flutter/material.dart';

/// A full gallery color scheme.
class GalleryThemeDef {
  final String id;
  final String name;
  final Color bg; // app backdrop (warm gallery wall)
  final Color surface; // frosted card surfaces
  final Color ink; // primary text / headlines
  final Color sub; // secondary text
  final Color muted; // captions, hairlines
  final Color line; // subtle borders
  final Color accent; // single restrained metal accent (never luminous)
  final Color board; // matte board lacquer
  final Color boardHi; // board top-left sheen
  final Color boardLo; // board bottom-right depth

  const GalleryThemeDef({
    required this.id,
    required this.name,
    required this.bg,
    required this.surface,
    required this.ink,
    required this.sub,
    required this.muted,
    required this.line,
    required this.accent,
    required this.board,
    required this.boardHi,
    required this.boardLo,
  });

  Color get boardGrid => muted.withValues(alpha: 0.18);

  GalleryThemeDef copyWith({
    String? id,
    String? name,
    Color? bg,
    Color? surface,
    Color? ink,
    Color? sub,
    Color? muted,
    Color? line,
    Color? accent,
    Color? board,
    Color? boardHi,
    Color? boardLo,
  }) =>
      GalleryThemeDef(
        id: id ?? this.id,
        name: name ?? this.name,
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        ink: ink ?? this.ink,
        sub: sub ?? this.sub,
        muted: muted ?? this.muted,
        line: line ?? this.line,
        accent: accent ?? this.accent,
        board: board ?? this.board,
        boardHi: boardHi ?? this.boardHi,
        boardLo: boardLo ?? this.boardLo,
      );
}

class GalleryThemes {
  /// Free starter themes. The rest are PRO.
  static const List<String> freeIds = [
    'plaster',
    'marble',
    'charcoal',
    'ivory',
  ];

  static bool isPro(String id) =>
      !freeIds.contains(id) && id != 'custom';

  static const List<GalleryThemeDef> all = [
    GalleryThemeDef(
      id: 'plaster',
      name: 'Gallery Plaster',
      bg: Color(0xFFE8E6E1),
      surface: Color(0xFFFBF9F4),
      ink: Color(0xFF1C1B19),
      sub: Color(0xFF494740),
      muted: Color(0xFF76736C),
      line: Color(0xFFCBC6BD),
      accent: Color(0xFFC29B38),
      board: Color(0xFF141312),
      boardHi: Color(0xFF1B1A18),
      boardLo: Color(0xFF100F0E),
    ),
    GalleryThemeDef(
      id: 'marble',
      name: 'Marble Hall',
      bg: Color(0xFFEDEAE3),
      surface: Color(0xFFFFFFFF),
      ink: Color(0xFF23211E),
      sub: Color(0xFF4E4B44),
      muted: Color(0xFF8A857A),
      line: Color(0xFFD8D2C6),
      accent: Color(0xFF9A8C5B),
      board: Color(0xFF1E1C1A),
      boardHi: Color(0xFF262421),
      boardLo: Color(0xFF141210),
    ),
    GalleryThemeDef(
      id: 'charcoal',
      name: 'Charcoal Study',
      bg: Color(0xFF3A3835),
      surface: Color(0xFF4A4742),
      ink: Color(0xFFF0ECE3),
      sub: Color(0xFFCFC8B9),
      muted: Color(0xFF9A948A),
      line: Color(0xFF5C5850),
      accent: Color(0xFFC9A45C),
      board: Color(0xFF171614),
      boardHi: Color(0xFF211F1D),
      boardLo: Color(0xFF0E0D0C),
    ),
    GalleryThemeDef(
      id: 'ivory',
      name: 'Ivory Atelier',
      bg: Color(0xFFF4F0E6),
      surface: Color(0xFFFFFDF8),
      ink: Color(0xFF2A2721),
      sub: Color(0xFF57534A),
      muted: Color(0xFF918B7C),
      line: Color(0xFFE0D9C8),
      accent: Color(0xFF8C6D2F),
      board: Color(0xFF201D19),
      boardHi: Color(0xFF292520),
      boardLo: Color(0xFF171411),
    ),
    GalleryThemeDef(
      id: 'sepia',
      name: 'Sepia Archive',
      bg: Color(0xFFE3D5BE),
      surface: Color(0xFFF7F0E0),
      ink: Color(0xFF2E2415),
      sub: Color(0xFF5C4E36),
      muted: Color(0xFF97866A),
      line: Color(0xFFD3C3A4),
      accent: Color(0xFF8A6D2E),
      board: Color(0xFF1B1712),
      boardHi: Color(0xFF251F17),
      boardLo: Color(0xFF12100C),
    ),
    GalleryThemeDef(
      id: 'slate',
      name: 'Slate Conservatory',
      bg: Color(0xFFDDE1E4),
      surface: Color(0xFFF7F9FA),
      ink: Color(0xFF1E2328),
      sub: Color(0xFF495058),
      muted: Color(0xFF7E8891),
      line: Color(0xFFC4CBD1),
      accent: Color(0xFF7C6A3F),
      board: Color(0xFF16191C),
      boardHi: Color(0xFF1E2226),
      boardLo: Color(0xFF101315),
    ),
    GalleryThemeDef(
      id: 'sandstone',
      name: 'Sandstone Wing',
      bg: Color(0xFFE9DCC4),
      surface: Color(0xFFFBF4E4),
      ink: Color(0xFF2B2114),
      sub: Color(0xFF5B4C34),
      muted: Color(0xFF9C8A68),
      line: Color(0xFFD9C9A8),
      accent: Color(0xFF9C7430),
      board: Color(0xFF1D1812),
      boardHi: Color(0xFF272118),
      boardLo: Color(0xFF14100C),
    ),
    GalleryThemeDef(
      id: 'olive',
      name: 'Olive Annex',
      bg: Color(0xFFDCD8C4),
      surface: Color(0xFFF5F2E6),
      ink: Color(0xFF232418),
      sub: Color(0xFF4C4D3C),
      muted: Color(0xFF84825F),
      line: Color(0xFFC6C2A8),
      accent: Color(0xFF8F7433),
      board: Color(0xFF191A12),
      boardHi: Color(0xFF222318),
      boardLo: Color(0xFF11120C),
    ),
    GalleryThemeDef(
      id: 'terracotta',
      name: 'Terracotta Court',
      bg: Color(0xFFE6D2C0),
      surface: Color(0xFFF9F0E4),
      ink: Color(0xFF2B1F16),
      sub: Color(0xFF5A4939),
      muted: Color(0xFF99826A),
      line: Color(0xFFD8C0A6),
      accent: Color(0xFF9A6B32),
      board: Color(0xFF1C1611),
      boardHi: Color(0xFF261E16),
      boardLo: Color(0xFF14100C),
    ),
    GalleryThemeDef(
      id: 'porcelain',
      name: 'Porcelain Room',
      bg: Color(0xFFEEECE7),
      surface: Color(0xFFFFFFFF),
      ink: Color(0xFF1D1D1B),
      sub: Color(0xFF4A4A46),
      muted: Color(0xFF85857F),
      line: Color(0xFFD5D5CE),
      accent: Color(0xFF8E7B4A),
      board: Color(0xFF131313),
      boardHi: Color(0xFF1B1B1B),
      boardLo: Color(0xFF0C0C0C),
    ),
    GalleryThemeDef(
      id: 'walnut',
      name: 'Walnut Gallery',
      bg: Color(0xFFD9CDB8),
      surface: Color(0xFFF3EBDB),
      ink: Color(0xFF241A10),
      sub: Color(0xFF52432F),
      muted: Color(0xFF8D7B60),
      line: Color(0xFFCCBCA0),
      accent: Color(0xFF97742F),
      board: Color(0xFF191410),
      boardHi: Color(0xFF221B15),
      boardLo: Color(0xFF100D0A),
    ),
    GalleryThemeDef(
      id: 'dusk',
      name: 'Dusk Salon',
      bg: Color(0xFF4E4A44),
      surface: Color(0xFF5D5850),
      ink: Color(0xFFF2EDE2),
      sub: Color(0xFFD2CAB9),
      muted: Color(0xFFA39A88),
      line: Color(0xFF6B6459),
      accent: Color(0xFFC2A054),
      board: Color(0xFF121110),
      boardHi: Color(0xFF1A1917),
      boardLo: Color(0xFF0B0A09),
    ),
    GalleryThemeDef(
      id: 'linen',
      name: 'Linen Loft',
      bg: Color(0xFFEFE9DC),
      surface: Color(0xFFFFFBF2),
      ink: Color(0xFF262219),
      sub: Color(0xFF534D3F),
      muted: Color(0xFF8E8774),
      line: Color(0xFFDCD3BE),
      accent: Color(0xFF96762E),
      board: Color(0xFF1A1714),
      boardHi: Color(0xFF231F1A),
      boardLo: Color(0xFF12100D),
    ),
    GalleryThemeDef(
      id: 'basalt',
      name: 'Basalt Chamber',
      bg: Color(0xFF2E2C29),
      surface: Color(0xFF3C3934),
      ink: Color(0xFFEFE9DC),
      sub: Color(0xFFC8C0AE),
      muted: Color(0xFF948C7C),
      line: Color(0xFF4E4A43),
      accent: Color(0xFFBE9C4E),
      board: Color(0xFF0F0E0D),
      boardHi: Color(0xFF171614),
      boardLo: Color(0xFF080707),
    ),
  ];

  static GalleryThemeDef byId(String id, {GalleryThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

// ---------------------------------------------------------------------------
/// A physical disc material: dark-face and light-face color pairs.
class DiscStyleDef {
  final String id;
  final String name;
  final Color darkTop;
  final Color darkBottom;
  final Color lightTop;
  final Color lightBottom;
  final String blurb;

  const DiscStyleDef({
    required this.id,
    required this.name,
    required this.darkTop,
    required this.darkBottom,
    required this.lightTop,
    required this.lightBottom,
    required this.blurb,
  });
}

class DiscStyles {
  /// Free starter styles. The rest are PRO.
  static const List<String> freeIds = [
    'frosted',
    'porcelain',
    'slate',
  ];

  static bool isPro(String id) => !freeIds.contains(id);

  static const List<DiscStyleDef> all = [
    DiscStyleDef(
      id: 'frosted',
      name: 'Frosted Glass',
      darkTop: Color(0xFF2B2A27),
      darkBottom: Color(0xFF151413),
      lightTop: Color(0xFFFFFFFF),
      lightBottom: Color(0xFFE3E1DA),
      blurb: 'Obsidian & bone porcelain',
    ),
    DiscStyleDef(
      id: 'porcelain',
      name: 'Honed Porcelain',
      darkTop: Color(0xFF4A3E30),
      darkBottom: Color(0xFF2A231B),
      lightTop: Color(0xFFFFF8EA),
      lightBottom: Color(0xFFEDE0C8),
      blurb: 'Warm umber & cream',
    ),
    DiscStyleDef(
      id: 'slate',
      name: 'Polished Slate',
      darkTop: Color(0xFF39424E),
      darkBottom: Color(0xFF20262E),
      lightTop: Color(0xFFE8EDF2),
      lightBottom: Color(0xFFC9D2DB),
      blurb: 'Blue-grey quarry stone',
    ),
    DiscStyleDef(
      id: 'walnut',
      name: 'Walnut & Ivory',
      darkTop: Color(0xFF5C3F26),
      darkBottom: Color(0xFF33220F),
      lightTop: Color(0xFFF6EFDD),
      lightBottom: Color(0xFFE2D3B4),
      blurb: 'Turned wood pair',
    ),
    DiscStyleDef(
      id: 'marble',
      name: 'Carrara Marble',
      darkTop: Color(0xFF3B3B3D),
      darkBottom: Color(0xFF1E1E20),
      lightTop: Color(0xFFF4F4F2),
      lightBottom: Color(0xFFD9D9D6),
      blurb: 'Veined stone, honed matte',
    ),
    DiscStyleDef(
      id: 'sage',
      name: 'Ceramic Sage',
      darkTop: Color(0xFF3E4A3A),
      darkBottom: Color(0xFF232B20),
      lightTop: Color(0xFFE9EBDD),
      lightBottom: Color(0xFFCBD0B8),
      blurb: 'Glazed studio ceramic',
    ),
    DiscStyleDef(
      id: 'terracotta',
      name: 'Kiln Terracotta',
      darkTop: Color(0xFF6E3B26),
      darkBottom: Color(0xFF3E2115),
      lightTop: Color(0xFFF3E4D2),
      lightBottom: Color(0xFFE0C3A4),
      blurb: 'Fired clay duo',
    ),
    DiscStyleDef(
      id: 'noir',
      name: 'Ink & Paper',
      darkTop: Color(0xFF1A1A1A),
      darkBottom: Color(0xFF050505),
      lightTop: Color(0xFFFFFEF8),
      lightBottom: Color(0xFFE8E4D2),
      blurb: 'Maximum contrast pair',
    ),
    DiscStyleDef(
      id: 'olive',
      name: 'Olive & Bone',
      darkTop: Color(0xFF4B4A2A),
      darkBottom: Color(0xFF2A2A16),
      lightTop: Color(0xFFF2EDDA),
      lightBottom: Color(0xFFDCD4B6),
      blurb: 'Pressed olive, bone ash',
    ),
    DiscStyleDef(
      id: 'graphite',
      name: 'Graphite & Chalk',
      darkTop: Color(0xFF33302C),
      darkBottom: Color(0xFF191713),
      lightTop: Color(0xFFF1EEE8),
      lightBottom: Color(0xFFD5D0C2),
      blurb: 'Drawing-room neutrals',
    ),
  ];

  static DiscStyleDef byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }
}

// ---------------------------------------------------------------------------
/// Board frame accent: the inlay/edge treatment around the lacquered slab.
class BoardAccentDef {
  final String id;
  final String name;
  final Color frame; // rim / inlay color
  final Color hint; // valid-move hint ring color
  final String blurb;

  const BoardAccentDef({
    required this.id,
    required this.name,
    required this.frame,
    required this.hint,
    required this.blurb,
  });
}

class BoardAccents {
  /// Free starter accents. The rest are PRO.
  static const List<String> freeIds = [
    'brass',
    'charcoal',
  ];

  static bool isPro(String id) => !freeIds.contains(id);

  static const List<BoardAccentDef> all = [
    BoardAccentDef(
      id: 'brass',
      name: 'Museum Brass',
      frame: Color(0xFFC29B38),
      hint: Color(0xFFC29B38),
      blurb: 'The gallery standard',
    ),
    BoardAccentDef(
      id: 'charcoal',
      name: 'Charcoal Edge',
      frame: Color(0xFF3A3835),
      hint: Color(0xFF76736C),
      blurb: 'Quiet, almost invisible',
    ),
    BoardAccentDef(
      id: 'bronze',
      name: 'Aged Bronze',
      frame: Color(0xFFA67C3D),
      hint: Color(0xFFA67C3D),
      blurb: 'Warm antique metal',
    ),
    BoardAccentDef(
      id: 'walnut',
      name: 'Walnut Inlay',
      frame: Color(0xFF6B4A2F),
      hint: Color(0xFF8A6A45),
      blurb: 'Cabinet-maker trim',
    ),
    BoardAccentDef(
      id: 'ivory',
      name: 'Ivory Line',
      frame: Color(0xFFD8D2C4),
      hint: Color(0xFFD8D2C4),
      blurb: 'Pale hairline frame',
    ),
    BoardAccentDef(
      id: 'copper',
      name: 'Copper Rim',
      frame: Color(0xFFB0704A),
      hint: Color(0xFFB0704A),
      blurb: 'Soft metallic warmth',
    ),
    BoardAccentDef(
      id: 'slate',
      name: 'Slate Trim',
      frame: Color(0xFF5A6470),
      hint: Color(0xFF7E8891),
      blurb: 'Cool architectural edge',
    ),
    BoardAccentDef(
      id: 'umber',
      name: 'Umber Band',
      frame: Color(0xFF7A5B3A),
      hint: Color(0xFF8A6A45),
      blurb: 'Earthy gallery rail',
    ),
  ];

  static BoardAccentDef byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return all.first;
  }
}
