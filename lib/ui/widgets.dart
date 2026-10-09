/// Shared gallery widgets: frosted glass cards/buttons, physical
/// toggles/sliders, pills, top bar — all per the Stitch design system.

library;
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Frosted translucent glass card: background blur, 1px hairline border,
/// soft realistic drop shadow.
class FrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const FrostedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = G.rCard,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: G.glassWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: G.outlineVariant, width: 1),
            boxShadow: G.cardShadow,
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// Frosted glass button row (menu actions): label + sublabel + trailing arrow.
class GlassButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const GlassButton({
    super.key,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      onTap: onTap,
      radius: G.rPill,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: G.ink,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: G.buttonLabel.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(sublabel,
                    style: G.body.copyWith(
                        fontSize: 12, color: G.basalt, height: 1.3)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: G.ink, size: 20),
        ],
      ),
    );
  }
}

/// Primary action: solid matte charcoal pill with warm-gray text.
class DarkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const DarkButton(
      {super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 17),
        decoration: BoxDecoration(
          color: G.ink,
          borderRadius: BorderRadius.circular(G.rPill),
          boxShadow: G.buttonShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: G.plaster, size: 18),
              const SizedBox(width: 10),
            ],
            Text(label.toUpperCase(),
                style: G.darkButtonLabel
                    .copyWith(letterSpacing: 1.6, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Secondary action: frosted glass pill.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const GhostButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      onTap: onTap,
      radius: G.rPill,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      child: Center(
        child: Text(label.toUpperCase(),
            style: G.buttonLabel.copyWith(letterSpacing: 1.6, fontSize: 13)),
      ),
    );
  }
}

/// Small pill button (Undo / Menu).
class MiniPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const MiniPill(
      {super.key, required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      onTap: onTap,
      radius: G.rPill,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: G.ink),
            const SizedBox(width: 8),
            Text(label.toUpperCase(),
                style: G.buttonLabel
                    .copyWith(fontSize: 12, letterSpacing: 1.4)),
          ],
        ),
      ),
    );
  }
}

/// Physical toggle: frosted glass track, charcoal knob. No platform switch.
class PhysicalToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PhysicalToggle(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value
              ? G.ink.withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.55),
          border: Border.all(color: G.outlineVariant, width: 1),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 3)),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: value
                        ? [G.porcelainTop, G.porcelainBottom]
                        : [const Color(0xFF3A3835), G.ink],
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x30000000),
                        blurRadius: 4,
                        offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slim physical slider: hairline track, charcoal disc thumb.
class GallerySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const GallerySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        activeTrackColor: G.ink,
        inactiveTrackColor: G.basalt.withValues(alpha: 0.35),
        thumbShape: const _DiscThumb(),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(
          value: value, onChanged: onChanged, onChangeEnd: onChangeEnd),
    );
  }
}

class _DiscThumb extends SliderComponentShape {
  const _DiscThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(22, 22);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(
        center + const Offset(0, 3),
        10,
        Paint()..color = const Color(0x22000000));
    canvas.drawCircle(
        center,
        10,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A3835), G.ink],
          ).createShader(Rect.fromCircle(center: center, radius: 10)));
    canvas.drawCircle(
        center + const Offset(-2.5, -2.5),
        3.2,
        Paint()..color = Colors.white.withValues(alpha: 0.28));
  }
}

/// Difficulty pills (Easy / Medium / Hard) — selected is matte charcoal.
class DifficultyPills extends StatelessWidget {
  final int selected; // 0,1,2
  final ValueChanged<int> onChanged;
  final List<String> labels;

  const DifficultyPills({
    super.key,
    required this.selected,
    required this.onChanged,
    this.labels = const ['Easy', 'Medium', 'Hard'],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(G.rPill),
        border: Border.all(color: G.outlineVariant, width: 1),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? G.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(G.rPill),
                  boxShadow: active ? G.buttonShadow : null,
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: G.buttonLabel.copyWith(
                      fontSize: 12,
                      letterSpacing: 0.6,
                      color: active ? G.plaster : G.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Minimal top bar: back chevron / centered title block / actions.
class GalleryTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const GalleryTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: onBack == null
              ? const SizedBox.shrink()
              : _CircleIcon(
                  icon: Icons.chevron_left_rounded,
                  onTap: onBack!,
                ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(title, style: G.titleCaps),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: G.labelCaps(size: 10, color: G.basalt)),
            ],
          ),
        ),
        SizedBox(
          width: 44 * (actions.isEmpty ? 1 : actions.length).toDouble(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ),
      ],
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) =>
      _CircleIcon(icon: icon, onTap: onTap, active: active);
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _CircleIcon(
      {required this.icon, required this.onTap, this.active = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: active ? 1.0 : 0.35,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: G.glassWhite,
            border: Border.all(color: G.outlineVariant, width: 1),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Icon(icon, size: 20, color: G.ink),
        ),
      ),
    );
  }
}

/// Quiet letterspaced micro-caption.
class MicroCaption extends StatelessWidget {
  final String text;
  const MicroCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: G.labelCaps(size: 10, color: G.basalt),
      );
}

/// Gentle shake for invalid moves (gallery calm: no red flashes).
class Shake extends StatefulWidget {
  final int nonce;
  final Widget child;
  const Shake({super.key, required this.nonce, required this.child});

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  int _last = 0;

  @override
  void initState() {
    super.initState();
    _last = widget.nonce;
  }

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (widget.nonce != _last) {
      _last = widget.nonce;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shakeOffset(_c.value), 0),
        child: child,
      ),
      child: widget.child,
    );
  }

  double _shakeOffset(double t) {
    if (t == 0 || t == 1) return 0;
    // Damped oscillation: ±5px, ~3 visible swings.
    return 5.0 * (1 - t) * (1 - t) * sin(t * pi * 6);
  }
}
