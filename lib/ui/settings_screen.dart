/// Settings — "Tactile parameters & acoustic resonance".
///
/// Single frosted glass card of hairline-divided rows: music/SFX toggles,
/// volume sliders, bot difficulty, valid-move hints, haptics, then
/// "Reset to defaults".

library;
import 'package:flutter/material.dart';

import '../game/ai.dart';
import '../services/audio.dart';
import '../services/settings.dart';
import 'tokens.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  final AppSettings settings;
  const SettingsScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return GalleryBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) => ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
                    'Tactile parameters & acoustic resonance',
                    style: G.italicCaption,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                FrostedCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 6),
                  child: Column(
                    children: [
                      _row(
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
                      const _Hairline(),
                      _row(
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
                      const _Hairline(),
                      _sliderRow(
                        title: 'Music volume',
                        valueLabel:
                            '${(settings.musicVolume * 100).round()}%',
                        value: settings.musicVolume,
                        onChanged: settings.setMusicVolume,
                      ),
                      const _Hairline(),
                      _sliderRow(
                        title: 'SFX volume',
                        valueLabel:
                            '${(settings.sfxVolume * 100).round()}%',
                        value: settings.sfxVolume,
                        onChanged: (v) {
                          settings.setSfxVolume(v);
                        },
                        onChangeEnd: (_) => AudioService.I.place(),
                      ),
                      const _Hairline(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Bot difficulty',
                                      style: G.body.copyWith(
                                          fontSize: 14,
                                          color: G.ink,
                                          fontWeight:
                                              FontWeight.w500)),
                                ),
                                Text('HEURISTIC ENGINE',
                                    style: G.labelCaps(
                                        size: 9,
                                        color: G.basalt)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DifficultyPills(
                              selected:
                                  settings.difficulty.index,
                              onChanged: (i) {
                                AudioService.I.click();
                                settings.setDifficulty(
                                    BotDifficulty.values[i]);
                              },
                            ),
                          ],
                        ),
                      ),
                      const _Hairline(),
                      _row(
                        title: 'Show valid moves',
                        subtitle: 'Subtle brass micro-rings',
                        trailing: PhysicalToggle(
                          value: settings.showHints,
                          onChanged: (v) {
                            AudioService.I.click();
                            settings.setShowHints(v);
                          },
                        ),
                      ),
                      const _Hairline(),
                      _row(
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
                      const _Hairline(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        child: Row(
                          children: [
                            Text('EDITION NO. 01',
                                style: G.labelCaps(
                                    size: 10, color: G.basalt)),
                            const Spacer(),
                            Text('VERSION 1.0',
                                style: G.labelCaps(
                                    size: 10, color: G.basalt)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                        style: G.buttonLabel.copyWith(
                            fontSize: 12, letterSpacing: 1.6)),
                  ),
                ),
                const SizedBox(height: 16),
                const MicroCaption(
                    'Handcrafted digital mechanics for mindful competition'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(
      {required String title,
      required String subtitle,
      required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: G.body.copyWith(
                        fontSize: 14,
                        color: G.ink,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: G.body
                        .copyWith(fontSize: 12, color: G.basalt)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _sliderRow({
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
                    style: G.body.copyWith(
                        fontSize: 14,
                        color: G.ink,
                        fontWeight: FontWeight.w500)),
              ),
              Text(valueLabel, style: G.numerals(size: 12)),
            ],
          ),
          GallerySlider(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: G.outlineVariant.withValues(alpha: 0.6),
      );
}
