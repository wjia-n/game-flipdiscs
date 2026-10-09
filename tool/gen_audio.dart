/// Procedural audio generator for Flip Discs.
/// Synthesizes all SFX + music loops as 16-bit PCM WAV files into assets/audio/.
/// Run: `dart tool/gen_audio.dart` from the project root.
///
/// Physical identity: frosted-glass / stone discs on a matte board —
/// soft wooden "thock" placements, bright glass "clack" flips, calm
/// gallery-quiet chimes. No harsh buzzers, no fanfare.

library;

// ignore_for_file: avoid_print, prefer_function_declarations_over_variables
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sr = 22050;

void main() {
  final dir = Directory('assets/audio');
  dir.createSync(recursive: true);

  final rng = Random(20261009);

  double noise() => rng.nextDouble() * 2 - 1;

  Float64List buf(double secs) => Float64List((secs * sr).round());

  // ---- SFX ----

  // UI tick: soft glass tick.
  var s = buf(0.09);
  for (var i = 0; i < s.length; i++) {
    final t = i / sr;
    s[i] = sin(2 * pi * 1400 * t) * exp(-t / 0.012) * 0.5 +
        0.18 * noise() * exp(-t / 0.005);
  }
  writeWav('${dir.path}/click.wav', s);

  // Disc placement: soft wooden "thock".
  s = buf(0.16);
  for (var i = 0; i < s.length; i++) {
    final t = i / sr;
    s[i] = sin(2 * pi * 196 * t) * exp(-t / 0.030) * 0.8 +
        0.5 * sin(2 * pi * 392 * t) * exp(-t / 0.018) +
        0.22 * noise() * exp(-t / 0.008);
  }
  writeWav('${dir.path}/place.wav', s);

  // Disc flip: brighter glass "clack".
  s = buf(0.12);
  for (var i = 0; i < s.length; i++) {
    final t = i / sr;
    s[i] = sin(2 * pi * 660 * t) * exp(-t / 0.020) * 0.7 +
        0.55 * sin(2 * pi * 1320 * t) * exp(-t / 0.012) +
        0.30 * noise() * exp(-t / 0.006);
  }
  writeWav('${dir.path}/flip.wav', s);

  // Invalid move: soft low "thud" (gallery calm, no harsh buzz).
  s = buf(0.25);
  for (var i = 0; i < s.length; i++) {
    final t = i / sr;
    s[i] = sin(2 * pi * 90 * t) * exp(-t / 0.090) * 0.8 +
        0.35 * sin(2 * pi * 135 * t) * exp(-t / 0.060);
  }
  writeWav('${dir.path}/invalid.wav', s);

  // Game start: gentle rising pair of tones.
  s = buf(0.60);
  tone(s, 392.0, 0.00, 0.60, 0.35, attack: 0.08);
  tone(s, 523.25, 0.18, 0.42, 0.30, attack: 0.08);
  writeWav('${dir.path}/start.wav', s);

  // Pass: muted double knock.
  s = buf(0.35);
  knock(s, 0.00, 0.5);
  knock(s, 0.14, 0.35);
  writeWav('${dir.path}/pass.wav', s);

  // Win: calm ascending triad (soft, no fanfare).
  s = buf(1.80);
  tone(s, 329.63, 0.00, 0.55, 0.32, attack: 0.03);
  tone(s, 392.00, 0.22, 0.55, 0.32, attack: 0.03);
  tone(s, 493.88, 0.44, 0.55, 0.32, attack: 0.03);
  tone(s, 659.25, 0.66, 0.80, 0.30, attack: 0.03);
  writeWav('${dir.path}/win.wav', s);

  // Lose: soft descending line.
  s = buf(1.80);
  tone(s, 220.00, 0.00, 0.60, 0.30, attack: 0.04);
  tone(s, 174.61, 0.30, 0.60, 0.30, attack: 0.04);
  tone(s, 146.83, 0.60, 0.80, 0.28, attack: 0.04);
  writeWav('${dir.path}/lose.wav', s);

  // ---- Music loops (seamless: every partial completes integer cycles) ----
  writeWav('${dir.path}/menu_music.wav',
      ambientLoop(12.0, [110.0, 164.81, 220.0, 277.18, 329.63], 0.30));
  writeWav('${dir.path}/game_music.wav',
      ambientLoop(16.0, [146.83, 220.0, 293.66, 369.99], 0.26,
          melody: [293.66, 329.63, 369.99, 440.0, 392.0, 369.99, 329.63, 293.66],
          noteLen: 2.0));

  print('done.');
}

void knock(Float64List s, double at, double gain) {
  final start = (at * sr).round();
  for (var i = 0; i < (0.12 * sr).round() && start + i < s.length; i++) {
    final t = i / sr;
    s[start + i] += gain *
        (sin(2 * pi * 180 * t) * exp(-t / 0.025) +
            0.3 * sin(2 * pi * 360 * t) * exp(-t / 0.015));
  }
}

void tone(Float64List s, double freq, double at, double dur, double gain,
    {double attack = 0.01}) {
  final start = (at * sr).round();
  final n = (dur * sr).round();
  for (var i = 0; i < n && start + i < s.length; i++) {
    final t = i / sr;
    final a = min(1.0, t / attack);
    final r = exp(-t / (dur * 0.55));
    s[start + i] += gain * a * r * sin(2 * pi * freq * t);
  }
}

/// Seamless ambient pad loop. Frequencies are quantized so every partial
/// completes a whole number of cycles inside [secs].
Float64List ambientLoop(
    double secs, List<double> chord, double gain,
    {List<double>? melody, double noteLen = 2.0}) {
  final n = (secs * sr).round();
  final s = Float64List(n);
  final q = (double f) => (f * secs).round() / secs; // quantize for seamless loop

  for (final f0 in chord) {
    final f = q(f0);
    final lfoCycles = 2; // slow breathing, integer cycles -> seamless
    for (var i = 0; i < n; i++) {
      final t = i / sr;
      final lfo = 0.75 + 0.25 * sin(2 * pi * lfoCycles * t / secs);
      s[i] += gain *
          lfo *
          (sin(2 * pi * f * t) * 0.6 +
              0.3 * sin(2 * pi * 2 * f * t + 0.7) +
              0.12 * sin(2 * pi * 3 * f * t + 1.9));
    }
  }
  if (melody != null) {
    var at = 0.0;
    for (final f0 in melody) {
      final f = q(f0);
      final start = (at * sr).round();
      final len = (noteLen * sr).round();
      for (var i = 0; i < len && start + i < n; i++) {
        final t = i / sr;
        final env = sin(pi * i / len); // raised-cosine swell, seamless
        s[start + i] += gain * 0.55 * env * sin(2 * pi * f * t);
      }
      at += noteLen;
    }
  }
  // Normalize to a calm level.
  var peak = 0.0;
  for (final v in s) {
    peak = max(peak, v.abs());
  }
  if (peak > 0) {
    final k = 0.5 / peak;
    for (var i = 0; i < n; i++) {
      s[i] *= k;
    }
  }
  return s;
}

void writeWav(String path, Float64List samples) {
  var peak = 0.0;
  for (final v in samples) {
    peak = max(peak, v.abs());
  }
  final g = peak > 0.98 ? 0.98 / peak : 1.0;
  final data = ByteData(44 + samples.length * 2);
  void wstr(int o, String v) {
    for (var i = 0; i < v.length; i++) {
      data.setUint8(o + i, v.codeUnitAt(i));
    }
  }

  wstr(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  wstr(8, 'WAVE');
  wstr(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sr, Endian.little);
  data.setUint32(28, sr * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  wstr(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i] * g).clamp(-1.0, 1.0);
    data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  File(path).writeAsBytesSync(data.buffer.asUint8List());
  print('wrote $path (${(File(path).lengthSync() / 1024).round()} KB)');
}
