import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'engine.dart' show kW, kH;
import 'theme.dart';

class _Orb {
  _Orb(this.x, this.y, this.size, this.tint, this.dx, this.dy, this.dur, this.a2);
  final double x, y, size, dx, dy, dur, a2; // dur in seconds
  final int tint;
}

class _Star {
  _Star(this.x, this.y, this.r, this.a0, this.dur, this.delay);
  final double x, y, r, a0, dur, delay;
}

/// Soft dusk sky: gradient + drifting glow orbs + twinkling stars.
class BackdropSpec {
  BackdropSpec(int n, [int seed = 7]) {
    final rnd = math.Random(seed);
    double r(double a, double b) => a + rnd.nextDouble() * (b - a);
    const cols = [0xff9eb5, 0x9cc8ff, 0xc9a8ff, 0xffc9a3, 0x9ff0c8];
    for (var i = 0; i < n; i++) {
      orbs.add(_Orb(r(0, 960), r(60, 520), r(180, 340), cols[i % 5], r(-90, 90), r(-50, 50),
          r(4.5, 8), .07 + rnd.nextDouble() * .1));
    }
    for (var i = 0; i < 24; i++) {
      stars.add(_Star(r(0, 960), r(0, 300), r(.8, 1.8), r(.25, .7), r(1.4, 3.2), r(0, 2)));
    }
  }
  final List<_Orb> orbs = [];
  final List<_Star> stars = [];
}

const List<Color> _skyColors = [Color(0xFF4A3D82), Color(0xFF7656A6), Color(0xFFA56FA8)];

void drawBackdrop(Canvas c, BackdropSpec s, double t, {bool rm = false}) {
  if (rm) t = 0;
  final rect = const Rect.fromLTWH(0, 0, kW, kH);
  c.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(0, kH), _skyColors, [0, .55, 1]));
  for (final o in s.orbs) {
    final p = 0.5 - 0.5 * math.cos(math.pi * t / o.dur); // yoyo with sine easing
    final a = 0.15 + (o.a2 - 0.15) * p;
    final center = Offset(o.x + o.dx * p, o.y + o.dy * p);
    c.drawCircle(
        center,
        o.size / 2,
        Paint()
          ..shader = ui.Gradient.radial(center, o.size / 2,
              [col(o.tint, a), col(o.tint, 0)]));
  }
  for (final st in s.stars) {
    double a = st.a0;
    if (!rm && t > st.delay) {
      final u = (t - st.delay) % (2 * st.dur);
      final f = u < st.dur ? u / st.dur : 2 - u / st.dur;
      a = st.a0 + (0.1 - st.a0) * f;
    }
    c.drawCircle(Offset(st.x, st.y), st.r, Paint()..color = col(0xffffff, a));
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.spec, this.time, this.rm) : super(repaint: time);
  final BackdropSpec spec;
  final ValueNotifier<double> time;
  final bool rm;
  @override
  void paint(Canvas canvas, Size size) => drawBackdrop(canvas, spec, time.value, rm: rm);
  @override
  bool shouldRepaint(covariant _BackdropPainter old) => false;
}

/// Animated backdrop that fills a 960x540 stage.
class BackdropLayer extends StatefulWidget {
  const BackdropLayer({super.key, this.orbs = 6});
  final int orbs;
  @override
  State<BackdropLayer> createState() => _BackdropLayerState();
}

class _BackdropLayerState extends State<BackdropLayer> with SingleTickerProviderStateMixin {
  late final BackdropSpec spec = BackdropSpec(widget.orbs, 11 + widget.orbs);
  final ValueNotifier<double> time = ValueNotifier(0);
  late final Ticker _tk;
  final bool rm = kReduceMotion;

  @override
  void initState() {
    super.initState();
    _tk = createTicker((d) => time.value = d.inMilliseconds / 1000.0);
    if (!rm) _tk.start();
  }

  @override
  void dispose() {
    _tk.dispose();
    time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          size: const Size(kW, kH),
          painter: _BackdropPainter(spec, time, rm),
        ),
      );
}
