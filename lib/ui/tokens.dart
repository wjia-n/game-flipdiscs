/// Gallery design tokens — the Stitch "Gallery Exhibition Reversi" system
/// (see stitch-batch2/flipdiscs/DESIGN.md), expressed in Flutter.
///
/// Art direction: gallery-minimalist still life. Frosted glass discs on a
/// matte board, warm-gray museum-wall backdrop, a single restrained metal
/// accent (never luminous). Newsreader light serif for display, Manrope
/// for UI.
///
/// The active gallery theme is provided down the tree by [GalleryScope];
/// widgets read it with `GalleryScope.themeOf(context)` and style text
/// with the [GalleryText] extension. The static [G] class keeps the
/// default (plaster) tokens plus radii, shadows and font families.

library;
import 'package:flutter/material.dart';

import '../theme/gallery.dart';

class G {
  G._();

  // --- palette (default "Gallery Plaster" theme) ---
  static const plaster = Color(0xFFE8E6E1); // app backdrop
  static const surface = Color(0xFFFBF9F4); // frosted card surfaces
  static const ink = Color(0xFF1C1B19); // primary text / dark disc side
  static const onSurfaceVariant = Color(0xFF494740); // secondary text
  static const basalt = Color(0xFF76736C); // captions, hairlines
  static const outlineVariant = Color(0xFFCBC6BD); // subtle borders
  static const obsidianTop = Color(0xFF2B2A27); // dark disc face
  static const obsidianBottom = Color(0xFF151413);
  static const porcelainTop = Color(0xFFFFFFFF); // white disc face
  static const porcelainBottom = Color(0xFFE3E1DA);
  static const brass = Color(0xFFC29B38); // single accent, non-luminescent
  static const board = Color(0xFF141312); // matte black board
  static Color get boardGrid => basalt.withValues(alpha: 0.18);
  static Color get glassWhite => Colors.white.withValues(alpha: 0.65);

  // --- radii ---
  static const rCard = 20.0;
  static const rPill = 999.0;
  static const rBoard = 18.0;

  // --- shadows ---
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: Color(0x24000000), // 14% black
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        const BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ];

  // --- typography ---
  static const serif = 'Newsreader';
  static const sans = 'Manrope';

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: plaster,
        fontFamily: sans,
        colorScheme: const ColorScheme.light(
          primary: ink,
          onPrimary: plaster,
          surface: surface,
          onSurface: ink,
          surfaceContainerHighest: plaster,
          outlineVariant: outlineVariant,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: ink,
        ),
      );
}

/// Provides the active [GalleryThemeDef] down the widget tree.
class GalleryScope extends InheritedWidget {
  final GalleryThemeDef theme;

  const GalleryScope({super.key, required this.theme, required super.child});

  static GalleryThemeDef themeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<GalleryScope>();
    return scope?.theme ?? GalleryThemes.all.first;
  }

  @override
  bool updateShouldNotify(GalleryScope old) => old.theme != theme;
}

/// Typography bound to a theme's colors: hierarchy by size + tracking +
/// weight only — no color-coding, no bold-everything.
extension GalleryText on GalleryThemeDef {
  TextStyle get display => TextStyle(
        fontFamily: G.serif,
        fontWeight: FontWeight.w300,
        fontSize: 40,
        letterSpacing: 3.2,
        color: ink,
        height: 1.1,
      );

  TextStyle get headline => TextStyle(
        fontFamily: G.serif,
        fontWeight: FontWeight.w300,
        fontSize: 30,
        letterSpacing: 1.8,
        color: ink,
        height: 1.15,
      );

  TextStyle get titleCaps => TextStyle(
        fontFamily: G.serif,
        fontWeight: FontWeight.w400,
        fontSize: 17,
        letterSpacing: 3.4,
        color: ink,
      );

  TextStyle labelCaps({double size = 11, Color? color}) => TextStyle(
        fontFamily: G.sans,
        fontWeight: FontWeight.w600,
        fontSize: size,
        letterSpacing: size * 0.16,
        color: color ?? muted,
      );

  TextStyle get body => TextStyle(
        fontFamily: G.sans,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: sub,
        height: 1.55,
      );

  TextStyle get buttonLabel => TextStyle(
        fontFamily: G.sans,
        fontWeight: FontWeight.w500,
        fontSize: 13,
        letterSpacing: 0.4,
        color: ink,
      );

  TextStyle get darkButtonLabel => TextStyle(
        fontFamily: G.sans,
        fontWeight: FontWeight.w500,
        fontSize: 13,
        letterSpacing: 0.4,
        color: bg,
      );

  TextStyle get italicCaption => TextStyle(
        fontFamily: G.serif,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: sub,
        height: 1.4,
      );

  TextStyle numerals(
          {double size = 15,
          FontWeight weight = FontWeight.w600,
          Color? color}) =>
      TextStyle(
        fontFamily: G.sans,
        fontWeight: weight,
        fontSize: size,
        color: color ?? ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Frosted-glass fill that reads on this theme's backdrop.
  Color get glassFill {
    final hsl = HSLColor.fromColor(bg);
    final light = hsl.lightness > 0.5;
    return (light ? Colors.white : surface)
        .withValues(alpha: light ? 0.65 : 0.16);
  }

  /// Card fill for dark vs light themes.
  Color get cardFill {
    final hsl = HSLColor.fromColor(bg);
    return hsl.lightness > 0.5
        ? Colors.white.withValues(alpha: 0.55)
        : surface.withValues(alpha: 0.10);
  }
}

/// Photographic backdrop: gallery wall with a soft studio vignette (the
/// only gradient allowed — photographic, per DESIGN.md).
class GalleryBackdrop extends StatelessWidget {
  final Widget child;
  final GalleryThemeDef? theme;

  const GalleryBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? GalleryScope.themeOf(context);
    final hsl = HSLColor.fromColor(t.bg);
    final light = hsl.lightness > 0.5;
    final hi = hsl.withLightness((hsl.lightness + 0.05).clamp(0.0, 1.0)).toColor();
    final lo = hsl.withLightness((hsl.lightness - 0.06).clamp(0.0, 1.0)).toColor();
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.55), // soft key from upper-left
          radius: 1.35,
          colors: light ? [hi, t.bg, lo] : [hi, t.bg, lo],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}
