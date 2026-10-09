/// Physical disc rendering: frosted-glass discs with soft studio lighting.
///
/// White discs read warm-white porcelain, dark discs read deep charcoal
/// obsidian — never pure black. Softly diffused highlights, subtle edge
/// light from the upper-left key, realistic soft contact shadows.
///
/// [FlippingDisc] animates a pseudo-3D flip: the disc rotates around its
/// vertical axis (0 → π) with the old face visible for the first half and
/// the new face for the second, plus a slight lift so it reads as a
/// physical object being turned over.

library;
import 'dart:math';

import 'package:flutter/material.dart';

import '../game/engine.dart' show black, white;
import 'tokens.dart';

class DiscPainter extends CustomPainter {
  /// 1 = black (obsidian), 2 = white (porcelain).
  final int side;

  /// 0..1 — how "edge-on" the disc is (1 = flat facing viewer).
  final double facing;

  const DiscPainter({required this.side, this.facing = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sx = max(0.14, facing); // edge-on thickness, never fully zero

    void ellipse(Offset c, double rx, double ry, Paint p) =>
        canvas.drawOval(Rect.fromCenter(center: c, width: rx * 2, height: ry * 2), p);

    // Contact shadow (soft, offset down-right like a studio still life).
    ellipse(
      Offset(cx + r * 0.08, cy + r * 0.72),
      r * 0.92 * sx,
      r * 0.30,
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    ellipse(
      Offset(cx + r * 0.08, cy + r * 0.72),
      r * 0.70 * sx,
      r * 0.22,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    final c = Offset(cx, cy);
    final isWhite = side == white;

    // Body: softly diffused radial light, key from upper-left.
    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.38, -0.42),
        radius: 1.05,
        colors: isWhite
            ? [G.porcelainTop, const Color(0xFFF4F1EA), G.porcelainBottom]
            : [const Color(0xFF3B3936), G.obsidianTop, G.obsidianBottom],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    ellipse(c, r * sx, r, body);

    // Diffused top-left sheen (frosted, never a hard specular glint).
    ellipse(
      Offset(cx - r * 0.30 * sx, cy - r * 0.34),
      r * 0.52 * sx,
      r * 0.44,
      Paint()
        ..color = Colors.white.withValues(alpha: isWhite ? 0.35 : 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Edge light: thin bright arc on the upper-left rim.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, r * 0.05)
      ..color = Colors.white.withValues(alpha: isWhite ? 0.55 : 0.22);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(sx, 1);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.94),
      pi * 0.9,
      pi * 0.7,
      false,
      rim,
    );
    // Lower-right inner shade for roundness.
    final shade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, r * 0.06)
      ..color = Colors.black.withValues(alpha: isWhite ? 0.10 : 0.35);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.93),
      -pi * 0.1,
      pi * 0.7,
      false,
      shade,
    );
    canvas.restore();

    // Hairline outer edge to seat the disc on the board.
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(sx, 1);
    canvas.drawCircle(
      Offset.zero,
      r * 0.98,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DiscPainter old) =>
      old.side != side || old.facing != facing;
}

/// Static physical disc.
class Disc extends StatelessWidget {
  final int side;
  final double size;
  const Disc({super.key, required this.side, this.size = 40});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: DiscPainter(side: side)),
      );
}

/// Disc that plays a pseudo-3D flip animation whenever [flipNonce] changes.
class FlippingDisc extends StatefulWidget {
  final int side;
  final int flipNonce;
  final double size;
  final Duration duration;

  const FlippingDisc({
    super.key,
    required this.side,
    required this.flipNonce,
    this.size = 40,
    this.duration = const Duration(milliseconds: 340),
  });

  @override
  State<FlippingDisc> createState() => _FlippingDiscState();
}

class _FlippingDiscState extends State<FlippingDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late int _shownSide = widget.side;
  int _lastNonce = 0;
  bool _flipping = false;

  @override
  void initState() {
    super.initState();
    _lastNonce = widget.flipNonce;
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() {
          _flipping = false;
          _shownSide = widget.side;
        });
      }
    });
  }

  @override
  void didUpdateWidget(FlippingDisc old) {
    super.didUpdateWidget(old);
    if (widget.flipNonce != _lastNonce) {
      _lastNonce = widget.flipNonce;
      _flipping = true;
      _c.forward(from: 0);
    } else if (!_flipping) {
      _shownSide = widget.side;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_flipping) {
      return Disc(side: _shownSide, size: widget.size);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        final angle = t * pi;
        final facing = cos(angle).abs();
        final showSide = t < 0.5 ? _shownSide : widget.side;
        // Slight lift mid-flip so it reads as a physical turnover.
        final lift = sin(t * pi) * 0.12;
        return Transform.translate(
          offset: Offset(0, -widget.size * lift),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: DiscPainter(side: showSide, facing: facing),
            ),
          ),
        );
      },
    );
  }
}

/// Disc that scales in softly when first placed.
class PlacingDisc extends StatefulWidget {
  final int side;
  final double size;
  const PlacingDisc({super.key, required this.side, this.size = 40});

  @override
  State<PlacingDisc> createState() => _PlacingDiscState();
}

class _PlacingDiscState extends State<PlacingDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
      child: Disc(side: widget.side, size: widget.size),
    );
  }
}

// Re-export for convenience in game screens.
const int kBlack = black;
const int kWhite = white;
