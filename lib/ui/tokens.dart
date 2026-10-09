/// Gallery design tokens — the Stitch "Gallery Exhibition Reversi" system
/// (see stitch-batch2/flipdiscs/DESIGN.md), expressed in Flutter.
///
/// Art direction: gallery-minimalist still life. Frosted glass discs on a
/// matte black board, warm-gray museum-wall backdrop, single brass accent
/// (never luminescent). Newsreader light serif for display, Manrope for UI.

library;
import 'package:flutter/material.dart';

class G {
  G._();

  // --- palette ---
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
  static const _serif = 'Newsreader';
  static const _sans = 'Manrope';

  /// Display headline: light serif, uppercase, wide tracking.
  static TextStyle get display => const TextStyle(
        fontFamily: _serif,
        fontWeight: FontWeight.w300,
        fontSize: 40,
        letterSpacing: 3.2, // 0.08em
        color: ink,
        height: 1.1,
      );

  static TextStyle get headline => const TextStyle(
        fontFamily: _serif,
        fontWeight: FontWeight.w300,
        fontSize: 30,
        letterSpacing: 1.8, // 0.06em
        color: ink,
        height: 1.15,
      );

  static TextStyle get titleCaps => const TextStyle(
        fontFamily: _serif,
        fontWeight: FontWeight.w400,
        fontSize: 17,
        letterSpacing: 3.4, // 0.20em
        color: ink,
      );

  /// Micro captions: letterspaced caps.
  static TextStyle labelCaps({double size = 11, Color color = basalt}) =>
      TextStyle(
        fontFamily: _sans,
        fontWeight: FontWeight.w600,
        fontSize: size,
        letterSpacing: size * 0.16,
        color: color,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: _sans,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: onSurfaceVariant,
        height: 1.55,
      );

  static TextStyle get buttonLabel => const TextStyle(
        fontFamily: _sans,
        fontWeight: FontWeight.w500,
        fontSize: 13,
        letterSpacing: 0.4,
        color: ink,
      );

  static TextStyle get darkButtonLabel => const TextStyle(
        fontFamily: _sans,
        fontWeight: FontWeight.w500,
        fontSize: 13,
        letterSpacing: 0.4,
        color: Color(0xFFE8E6E1),
      );

  /// Italic serif for quiet editorial captions.
  static TextStyle get italicCaption => const TextStyle(
        fontFamily: _serif,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: onSurfaceVariant,
        height: 1.4,
      );

  /// Tabular lining figures so score strips never jitter.
  static TextStyle numerals(
          {double size = 15,
          FontWeight weight = FontWeight.w600,
          Color color = ink}) =>
      TextStyle(
        fontFamily: _sans,
        fontWeight: weight,
        fontSize: size,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: plaster,
        fontFamily: _sans,
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

/// Photographic backdrop: warm-gray plaster with a soft studio vignette
/// (the only gradient allowed — photographic, per DESIGN.md).
class GalleryBackdrop extends StatelessWidget {
  final Widget child;
  const GalleryBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.35, -0.55), // soft key from upper-left
          radius: 1.35,
          colors: [Color(0xFFF1EEE8), G.plaster, Color(0xFFDDD9D1)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}
