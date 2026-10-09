/// Custom theme creator — design your own gallery (PRO).
///
/// Eight gallery tokens, each with a simple RGB-slider picker and a row
/// of curated swatches. Changes preview live and persist immediately.

library;
import 'package:flutter/material.dart';

import '../services/audio.dart';
import '../services/settings.dart';
import 'tokens.dart';
import 'widgets.dart';

class CustomThemeScreen extends StatelessWidget {
  final AppSettings settings;
  const CustomThemeScreen({super.key, required this.settings});

  static const _keys = [
    ('bg', 'Gallery wall', 'App backdrop'),
    ('surface', 'Card surface', 'Frosted cards'),
    ('ink', 'Ink', 'Headlines & primary text'),
    ('sub', 'Secondary text', 'Body copy'),
    ('muted', 'Captions', 'Hairlines & captions'),
    ('line', 'Borders', 'Subtle dividers'),
    ('accent', 'Accent metal', 'The single restrained accent'),
    ('board', 'Board lacquer', 'The matte board'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) {
        final t = settings.customTheme;
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
                        title: 'MY CREATION',
                        subtitle: 'CUSTOM GALLERY · PRO',
                        onBack: () {
                          AudioService.I.click();
                          Navigator.of(context).pop();
                        },
                        actions: [
                          CircleIconButton(
                            icon: Icons.restart_alt_rounded,
                            onTap: () {
                              AudioService.I.click();
                              settings.resetCustomColors();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24),
                      child: Text(
                        'Tap a token to recolour it. Your gallery previews live.',
                        style: t.italicCaption,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            24, 4, 24, 16),
                        itemCount: _keys.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final (key, name, blurb) = _keys[i];
                          final color = Color(
                              settings.customColors[key]!);
                          return FrostedCard(
                            onTap: () => _pickColor(
                                context, key, name, color),
                            radius: G.rPill,
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                    border: Border.all(
                                        color: t.line, width: 1),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: t.body.copyWith(
                                              fontSize: 14,
                                              color: t.ink,
                                              fontWeight:
                                                  FontWeight.w500)),
                                      Text(blurb,
                                          style: t.body.copyWith(
                                              fontSize: 12,
                                              color: t.muted)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                                  style: t.numerals(
                                      size: 11, color: t.muted),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          24, 0, 24, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: DarkButton(
                          label: 'Use this gallery',
                          icon: Icons.check_rounded,
                          onTap: () {
                            AudioService.I.click();
                            settings.setTheme('custom');
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _pickColor(
      BuildContext context, String key, String name, Color current) {
    AudioService.I.tapHaptic();
    showDialog(
      context: context,
      builder: (_) => _ColorPickerDialog(
        title: name,
        initial: current,
        onPick: (c) =>
            settings.setCustomColor(key, c.toARGB32()),
      ),
    );
  }
}

/// Simple RGB-slider color picker with curated swatches.
class _ColorPickerDialog extends StatefulWidget {
  final String title;
  final Color initial;
  final ValueChanged<Color> onPick;
  const _ColorPickerDialog(
      {required this.title,
      required this.initial,
      required this.onPick});

  @override
  State<_ColorPickerDialog> createState() =>
      _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double r = widget.initial.r * 255;
  late double g = widget.initial.g * 255;
  late double b = widget.initial.b * 255;

  static const _swatches = [
    0xFFE8E6E1, 0xFFFBF9F4, 0xFF1C1B19, 0xFF494740,
    0xFF76736C, 0xFFCBC6BD, 0xFFC29B38, 0xFF141312,
    0xFF8A6D2E, 0xFF5C3F26, 0xFF39424E, 0xFF3E4A3A,
    0xFF6E3B26, 0xFF4E4A44, 0xFFDDE1E4, 0xFFE6D2C0,
  ];

  Color get _color =>
      Color.fromARGB(255, r.round(), g.round(), b.round());

  @override
  Widget build(BuildContext context) {
    final t = GalleryScope.themeOf(context);
    return Dialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(G.rCard)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title.toUpperCase(),
                style: t.labelCaps(size: 12, color: t.ink)),
            const SizedBox(height: 14),
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _color,
                border: Border.all(color: t.line),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _swatches)
                  GestureDetector(
                    onTap: () {
                      final c = Color(s);
                      setState(() {
                        r = c.r * 255;
                        g = c.g * 255;
                        b = c.b * 255;
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(s),
                        border:
                            Border.all(color: t.line, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _slider('R', r, Colors.redAccent,
                (v) => setState(() => r = v)),
            _slider('G', g, Colors.green,
                (v) => setState(() => g = v)),
            _slider('B', b, Colors.blueAccent,
                (v) => setState(() => b = v)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: 'Cancel',
                    onTap: () {
                      AudioService.I.click();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DarkButton(
                    label: 'Apply',
                    onTap: () {
                      AudioService.I.click();
                      widget.onPick(_color);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(
      String label, double value, Color c, ValueChanged<double> onChanged) {
    final t = GalleryScope.themeOf(context);
    return Row(
      children: [
        SizedBox(
            width: 18,
            child: Text(label,
                style: t.labelCaps(size: 11, color: t.ink))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: c,
              inactiveTrackColor: t.muted.withValues(alpha: 0.3),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
                value: value, min: 0, max: 255, onChanged: onChanged),
          ),
        ),
        SizedBox(
            width: 34,
            child: Text('${value.round()}',
                style: t.numerals(size: 11, color: t.muted),
                textAlign: TextAlign.right)),
      ],
    );
  }
}
