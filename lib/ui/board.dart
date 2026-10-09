/// The matte-black exhibition board: lacquered slab, hairline etched
/// grid, brass micro-ring hints on legal squares, coordinate labels.

library;
import 'package:flutter/material.dart';

import '../game/controller.dart';
import '../game/engine.dart';
import 'disc.dart';
import 'tokens.dart';
import 'widgets.dart';

class BoardView extends StatelessWidget {
  final GameController controller;
  const BoardView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final pad = side * 0.075; // room for coordinate labels
        final cell = (side - pad * 2) / 8;
        return SizedBox(
          width: side,
          height: side,
          child: CustomPaint(
            painter: _BoardPainter(pad: pad),
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8),
                itemCount: 64,
                itemBuilder: (_, i) => _Cell(
                  controller: controller,
                  index: i,
                  cellSize: cell,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final GameController controller;
  final int index;
  final double cellSize;

  const _Cell(
      {required this.controller,
      required this.index,
      required this.cellSize});

  @override
  Widget build(BuildContext context) {
    final v = controller.engine.board[index];
    final isLegal =
        controller.humanTurn && controller.legalMoves.contains(index);
    final showHint = controller.settings.showHints && isLegal;
    final justPlaced = controller.lastPlaced == index;
    final discSize = cellSize * 0.86;

    Widget? disc;
    if (v != empty) {
      final flipped = controller.lastFlips.contains(index);
      if (justPlaced && !flipped) {
        disc = PlacingDisc(
            key: ValueKey('p${controller.flipEpoch}'), side: v, size: discSize);
      } else if (flipped) {
        disc = FlippingDisc(
          key: ValueKey('f$index'),
          side: v,
          flipNonce: controller.flipEpoch,
          size: discSize,
        );
      } else {
        disc = Disc(side: v, size: discSize);
      }
    }

    final cell = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.tapCell(index),
      child: Center(
        child: disc ??
            (showHint
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: G.brass.withValues(alpha: 0.40),
                        width: 1,
                      ),
                    ),
                  )
                : const SizedBox.expand()),
      ),
    );

    if (controller.invalidCell == index && !controller.over) {
      return Shake(
        key: ValueKey('s${controller.invalidNonce}'),
        nonce: controller.invalidNonce,
        child: cell,
      );
    }
    return cell;
  }
}

class _BoardPainter extends CustomPainter {
  final double pad;
  const _BoardPainter({required this.pad});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Soft drop shadow under the slab.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          rect.translate(0, 10), const Radius.circular(G.rBoard)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    // Matte black lacquered slab.
    final slab = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B1A18), G.board, Color(0xFF100F0E)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(G.rBoard)),
      slab,
    );

    // Faint rim light on the top edge (studio key).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 1.5, size.width - 4, size.height - 3),
          const Radius.circular(G.rBoard - 1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.10),
    );

    // Hairline etched grid.
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = G.boardGrid;
    final inner = Rect.fromLTWH(pad, pad, size.width - pad * 2, size.height - pad * 2);
    final cell = inner.width / 8;
    for (var i = 0; i <= 8; i++) {
      final o = inner.left + i * cell;
      canvas.drawLine(Offset(o, inner.top), Offset(o, inner.bottom), gridPaint);
      final o2 = inner.top + i * cell;
      canvas.drawLine(Offset(inner.left, o2), Offset(inner.right, o2), gridPaint);
    }

    // Coordinate labels: a–h across the top, 1–8 down the left.
    const cols = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    for (var i = 0; i < 8; i++) {
      _label(
        canvas,
        cols[i],
        Offset(inner.left + i * cell + cell / 2, pad * 0.52),
      );
      _label(
        canvas,
        '${8 - i}',
        Offset(pad * 0.52, inner.top + i * cell + cell / 2),
      );
    }
  }

  void _label(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: G.basalt.withValues(alpha: 0.75),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => old.pad != pad;
}
