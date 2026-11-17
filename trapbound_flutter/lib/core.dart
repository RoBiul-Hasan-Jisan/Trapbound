import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent progress (same shape as the web save: unlocked / done / sound).
class Save extends ChangeNotifier {
  Save._();
  static final Save I = Save._();
  static const _key = 'trapbound.v2';

  int unlocked = 0;
  List<int> done = [];
  bool sound = true;
  SharedPreferences? _p;

  Future<void> load() async {
    try {
      _p = await SharedPreferences.getInstance();
      final s = jsonDecode(_p!.getString(_key) ?? '') as Map<String, dynamic>;
      final u = s['unlocked'];
      final d = s['done'];
      final snd = s['sound'];
      if (u is int && u >= 0 && d is List && d.every((e) => e is int) && snd is bool) {
        unlocked = u;
        done = d.cast<int>().toList();
        sound = snd;
      }
    } catch (_) {}
  }

  void store() {
    try {
      _p?.setString(_key, jsonEncode({'unlocked': unlocked, 'done': done, 'sound': sound}));
    } catch (_) {}
    notifyListeners();
  }
}

/// Tiny synthesized sound effects (sine / triangle beeps with a pitch slide),
/// generated as WAV bytes in memory - no audio assets needed.
class Sfx {
  static final Map<String, Uint8List> _cache = {};

  static void beep(double f, [double d = 0.1, String type = 'sine', double slide = 0]) {
    if (!Save.I.sound) return;
    try {
      final key = '$f|$d|$type|$slide';
      final bytes = _cache.putIfAbsent(key, () => _wav(f, d, type, slide));
      final p = AudioPlayer();
      p.play(BytesSource(bytes, mimeType: 'audio/wav')).catchError((_) {});
      Future.delayed(Duration(milliseconds: (d * 1000).round() + 1500), () {
        try {
          p.dispose();
        } catch (_) {}
      });
    } catch (_) {}
  }

  static Uint8List _wav(double f, double d, String type, double slide) {
    const sr = 22050;
    final n = (sr * d).round();
    final data = ByteData(44 + n * 2);
    void str(int o, String t) {
      for (var i = 0; i < t.length; i++) {
        data.setUint8(o + i, t.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sr, Endian.little);
    data.setUint32(28, sr * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, n * 2, Endian.little);

    double phase = 0;
    for (var i = 0; i < n; i++) {
      final t = i / sr;
      var freq = f + (slide != 0 ? slide * (t / d) : 0);
      if (freq < 30) freq = 30;
      phase += 2 * math.pi * freq / sr;
      final wave = type == 'triangle' ? (2 / math.pi) * math.asin(math.sin(phase)) : math.sin(phase);
      final env = t < 0.015 ? t / 0.015 : math.max(0.0, (d - t) / (d - 0.015));
      data.setInt16(44 + i * 2, (wave * env * 0.3 * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
