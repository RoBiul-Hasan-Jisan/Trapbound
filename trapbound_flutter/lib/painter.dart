import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'backdrop.dart';
import 'engine.dart';
import 'theme.dart';

// Procedural stick-man (24x32), 4 poses - identical coordinates to the Phaser version.
const Map<String, List<List<double>>> _poses = {
  'man_idle': [[12, 12, 6, 20], [12, 12, 18, 20], [12, 21, 8, 31], [12, 21, 16, 31]],
  'man_run1': [[12, 12, 5, 17], [12, 12, 19, 21], [12, 21, 4, 29], [12, 21, 18, 31]],
  'man_run2': [[12, 12, 19, 17], [12, 12, 5, 21], [12, 21, 20, 29], [12, 21, 6, 31]],
  'man_jump': [[12, 12, 4, 6], [12, 12, 20, 6], [12, 21, 6, 28], [12, 21, 18, 28]],
};

/// Draws the man in a 24x32 box with its top-left at the origin.
void paintMan(Canvas c, String pose) {
  final line = Paint()
    ..color = col(0xffe3b0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final fill = Paint()..color = col(0xffe3b0);
  c.drawCircle(const Offset(12, 6), 5.5, fill);
  c.drawLine(const Offset(12, 11), const Offset(12, 21), line);
  for (final l in _poses[pose]!) {
    c.drawLine(Offset(l[0], l[1]), Offset(l[2], l[3]), line);
  }
  c.drawCircle(const Offset(14, 5), 1.2, Paint()..color = col(0x2a2547));
}

class ManPainter extends CustomPainter {
  const ManPainter(this.pose, {this.flipX = false, this.scale = 1});
  final String pose;
  final bool flipX;
  final double scale;
  @override
  void paint(Canvas c, Size size) {
    c.scale(scale);
    if (flipX) {
      c.translate(12, 16);
      c.scale(-1, 1);
      c.translate(-12, -16);
    }
    paintMan(c, pose);
  }

  @override
  bool shouldRepaint(covariant ManPainter old) =>
      old.pose != pose || old.flipX != flipX || old.scale != scale;
}

Path _star(double cx, double cy, int pts, double ir, double or, double rot) {
  final p = Path();
  for (var i = 0; i < pts * 2; i++) {
    final r = i.isEven ? or : ir;
    final a = rot - math.pi / 2 + i * math.pi / pts;
    final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
    if (i == 0) {
      p.moveTo(x, y);
    } else {
      p.lineTo(x, y);
    }
  }
  p.close();
  return p;
}

class GamePainter extends CustomPainter {
  GamePainter(this.g, this.spec) : super(repaint: g);
  final TrapboundGame g;
  final BackdropSpec spec;
  final math.Random _r = math.Random();

  @override
  void paint(Canvas c, Size size) {
    drawBackdrop(c, spec, g.bgT / 1000, rm: g.reduceMotion);
    c.save();
    if (g.shake > 0) {
      c.translate((_r.nextDouble() * 2 - 1) * 3.8, (_r.nextDouble() * 2 - 1) * 2.2);
    }
    for (final r in g.plats) {
      _solid(c, r, 1);
    }
    for (final s in g.ts) {
      _trap(c, s);
    }
    final ex = g.level.exit;
    _door(c, ex[0], ex[1], g.won ? _winScale(g.winT) : 1);
    if (!g.dead) _man(c);
    for (final s in g.sparks) {
      final f = s.t / 400;
      final p = Paint()..color = col(s.color, 1 - f);
      c.drawCircle(Offset(s.x + s.dx * f, s.y + s.dy * f), s.r * (1 - .7 * f), p);
    }
    for (final k in g.confetti) {
      if (k.t < k.delay) continue;
      final f = math.min(1.0, (k.t - k.delay) / k.dur);
      c.save();
      c.translate(k.x + k.dx * f, -10 + 570 * f);
      c.rotate(k.ang * f * math.pi / 180);
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: k.w, height: k.h), Paint()..color = col(k.color));
      c.restore();
    }
    c.restore();
    for (final m in g.msgs) {
      final f = math.min(1.0, m.age / 1700);
      final tp = TextPainter(
        text: TextSpan(
          text: m.text,
          style: ts(22, col(0xffe3a8, 1 - f), 800,
              [Shadow(offset: const Offset(0, 2), blurRadius: 6, color: col(0x140a28, (1 - f) * .6))]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(480 - tp.width / 2, 84 + (64 - 84) * f - tp.height / 2));
    }
    if (g.flash > 0) {
      c.drawRect(const Rect.fromLTWH(0, 0, kW, kH), Paint()..color = col(0x9cc8ff, g.flash / 150 * .85));
    }
  }

  double _winScale(double t) {
    if (t < 250) return 1 - .85 * t / 250;
    if (t < 500) return .15 + .85 * (t - 250) / 250;
    return 1;
  }

  void _solid(Canvas c, Rect r, double a) {
    c.drawRect(r, Paint()..color = col(0xb7a3e6, a));
    c.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = col(0xf0eaff, a));
  }

  void _box(Canvas c, Rect r, int fill, {int? stroke, double a = 1}) {
    c.drawRect(r, Paint()..color = col(fill, a));
    if (stroke != null) {
      c.drawRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = col(stroke, a));
    }
  }

  void _door(Canvas c, double x, double y, double sx) {
    // pulsing glow
    final t = g.bgT / 1400;
    final u = t % 2;
    final f = u < 1 ? u : 2 - u;
    final p = 0.5 - 0.5 * math.cos(math.pi * f);
    final a = .45 + (.75 - .45) * p;
    final radius = 65 * (1 + .15 * p);
    final ctr = Offset(x + 16, y + 24);
    c.drawCircle(ctr, radius,
        Paint()..shader = ui.Gradient.radial(ctr, radius, [col(0x9ff0c8, a), col(0x9ff0c8, 0)]));
    final r = Rect.fromLTWH(x, y, 32 * sx, 48);
    c.drawRect(r, Paint()..color = col(0x9ff0c8));
    c.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = col(0x4fbf93));
  }

  void _trap(Canvas c, TrapState s) {
    final d = s.d;
    final r = d.r;
    switch (d.t) {
      case 'spike':
        if (s.alpha > 0) {
          final path = Path()
            ..moveTo(s.x, s.y + r[3])
            ..lineTo(s.x + r[2] / 2, s.y)
            ..lineTo(s.x + r[2], s.y + r[3])
            ..close();
          c.drawPath(path, Paint()..color = col(0xff8fa3));
        }
        break;
      case 'collapse':
      case 'vanish':
        if (s.alpha > 0) _solid(c, Rect.fromLTWH(s.x, s.y, r[2], r[3]), s.alpha);
        break;
      case 'block':
        _box(c, Rect.fromLTWH(s.x, s.y, r[2], r[3]), 0xc9b8f2, stroke: 0xf0eaff);
        break;
      case 'fake':
        _door(c, r[0], r[1], 1);
        break;
      case 'saw':
        {
          final p = _star(s.x + r[2] / 2, s.y + r[3] / 2, 8, 10, 20, 2 * math.pi * g.tw / 600);
          c.drawPath(p, Paint()..color = col(0xffc27a));
          c.drawPath(
              p,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = col(0xfff0d0));
        }
        break;
      case 'timed':
        _box(c, Rect.fromLTWH(r[0], r[1], r[2], r[3]), 0xff8fa3, a: s.alpha);
        break;
      case 'wall':
        _box(c, Rect.fromLTWH(s.x, s.y, r[2], r[3]), 0xff7a93);
        break;
      case 'mover':
        _box(c, Rect.fromLTWH(s.x, r[1], r[2], r[3]), 0x8fb4ff, stroke: 0xd0e0ff);
        break;
    }
  }

  void _man(Canvas c) {
    c.save();
    c.translate(g.px + kPW / 2, g.py + kPH / 2);
    c.scale(g.flipX ? -1 : 1, g.gf < 0 ? -1 : 1);
    c.translate(-kPW / 2, -kPH / 2);
    paintMan(c, g.pose);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter old) => true;
}
