import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'core.dart';
import 'levels.dart';

// Logical game resolution (same as the Phaser version). Everything is scaled to fit.
const double kW = 960;
const double kH = 540;
const double kPW = 24; // player body size
const double kPH = 32;

bool _touching(Rect a, Rect b) =>
    !(a.right < b.left || a.bottom < b.top || a.left > b.right || a.top > b.bottom);

bool _overlap(Rect a, Rect b) =>
    a.right - b.left > 0.01 &&
    b.right - a.left > 0.01 &&
    a.bottom - b.top > 0.01 &&
    b.bottom - a.top > 0.01;

double _cl(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _sine(double t) => 0.5 - 0.5 * math.cos(math.pi * t); // Sine.inOut

class UiPing extends ChangeNotifier {
  void ping() => notifyListeners();
}

class Msg {
  Msg(this.text);
  final String text;
  double age = 0;
}

class Spark {
  Spark(this.x, this.y, this.dx, this.dy, this.r, this.color);
  final double x, y, dx, dy, r;
  final int color;
  double t = 0;
}

class Confetto {
  Confetto(this.x, this.w, this.h, this.dx, this.ang, this.dur, this.delay, this.color);
  final double x, w, h, dx, ang, dur, delay;
  final int color;
  double t = 0;
}

class _Timer {
  _Timer(this.left, this.fn, this.gen);
  double left;
  final VoidCallback fn;
  final int gen;
}

class _Solid {
  _Solid(this.rect, [this.vx = 0, this.mover]);
  final Rect rect;
  final double vx;
  final TrapState? mover;
}

class TrapState {
  TrapState(this.d)
      : x = d.r[0],
        y = d.r[1];
  final Trap d;
  bool on = false;
  bool kill = false;
  Rect? trig;
  double t = 0; // ms since fired
  double x, y; // current top-left
  double prevX = 0;
  double vx = 0;
  double alpha = 1;
  bool solidOn = true;
}

class TrapboundGame extends ChangeNotifier {
  final UiPing ui = UiPing(); // rebuilds HUD / overlays (not every frame)
  bool reduceMotion = false;
  VoidCallback? onMenu;

  late Level level;
  int index = 0;
  int deaths = 0;

  double clk = 0; // gameplay clock (ms)
  double tw = 0; // tween clock (ms)
  double bgT = 0; // background clock (ms)
  double gf = 1; // gravity factor (1 normal, -1 flipped)
  bool dead = false, won = false, paused = false;
  double rev = 0, coy = 0, buf = 0;
  bool jp = false;

  // player
  double px = 0, py = 0, vx = 0, vy = 0, accX = 0;
  bool flipX = false, grounded = false;
  bool contactDown = false, contactUp = false;
  TrapState? ride;

  // input
  bool kL = false, kR = false, kJ = false; // keyboard
  bool tL = false, tR = false, tJ = false; // touch

  List<Rect> plats = [];
  List<TrapState> ts = [];
  List<TrapState> movers = [];
  final List<_Timer> _timers = [];
  int _gen = 0;

  final List<Msg> msgs = [];
  final List<Spark> sparks = [];
  final List<Confetto> confetti = [];
  double shake = 0, flash = 0, winT = 0;
  final math.Random _rng = math.Random();

  void repaint() => notifyListeners();

  double _rnd(double a, double b) => a + _rng.nextDouble() * (b - a);

  String get pose => !grounded
      ? 'man_jump'
      : (vx.abs() > 40 ? (((clk / 110).floor() % 2) == 1 ? 'man_run1' : 'man_run2') : 'man_idle');

  void start(int i, {bool fresh = true}) {
    if (fresh) deaths = 0;
    index = i;
    level = levels[i];
    _gen++;
    dead = false;
    won = false;
    paused = false;
    clk = 0;
    tw = 0;
    gf = 1;
    rev = 0;
    coy = 0;
    buf = 0;
    jp = false;
    accX = 0;
    px = level.spawn[0] - kPW / 2;
    py = level.spawn[1] - kPH / 2;
    vx = 0;
    vy = 0;
    flipX = false;
    grounded = false;
    contactDown = false;
    contactUp = false;
    ride = null;
    _timers.clear();
    msgs.clear();
    sparks.clear();
    confetti.clear();
    shake = 0;
    flash = 0;
    winT = 0;
    plats = level.plats.map((p) => Rect.fromLTWH(p[0], p[1], p[2], p[3])).toList();
    ts = [];
    movers = [];
    for (final d in level.traps) {
      final s = TrapState(d);
      final r = d.r;
      switch (d.t) {
        case 'spike':
          s.y = r[1] + r[3]; // hidden below the platform until triggered
          s.alpha = 0;
          break;
        case 'fake':
        case 'saw':
        case 'wall':
          s.kill = true;
          break;
        case 'timed':
          s.alpha = .25;
          break;
        case 'mover':
          s.vx = d.v ?? 100;
          movers.add(s);
          break;
      }
      if (d.trig != null) {
        final t = d.trig!;
        s.trig = Rect.fromLTWH(t[0], t[1], t[2], t[3]);
      } else if (d.t == 'collapse' || d.t == 'vanish') {
        s.trig = Rect.fromLTWH(r[0], r[1] - 6, r[2], 8);
      }
      ts.add(s);
    }
    ui.ping();
    notifyListeners();
  }

  void after(double ms, VoidCallback fn) => _timers.add(_Timer(ms, fn, _gen));

  void _msg(String t) => msgs.add(Msg(t));

  /// One fixed 1/60 s step.
  void tick(double dtMs) {
    if (paused) return;
    _update(dtMs);
    _moveMovers(dtMs / 1000);
    if (!dead) _physics(dtMs / 1000);
  }

  // ---- traps -------------------------------------------------------------------------
  void _fire(TrapState s) {
    s.on = true;
    s.t = 0;
    final d = s.d;
    Sfx.beep(300, .12, 'sine', -120);
    final ch = d.chain;
    if (ch != null) {
      for (var n = 0; n < ch.length; n++) {
        final j = ch[n];
        after(250.0 * (n + 1), () {
          if (j >= 0 && j < ts.length && !ts[j].on) _fire(ts[j]);
        });
      }
    }
    switch (d.t) {
      case 'spike':
      case 'block':
        s.kill = true;
        break;
      case 'grav':
        gf = d.v!;
        _msg(gf < 0 ? 'Whoa, gravity flipped!' : 'Gravity is back to normal');
        if (!reduceMotion) flash = 150;
        break;
      case 'rev':
        rev = 3000;
        _msg('Oops, controls reversed!');
        break;
      case 'collapse':
        after(260, () => s.solidOn = false);
        break;
      case 'vanish':
        after(350, () => s.solidOn = false);
        break;
    }
  }

  void _animate(double dt) {
    for (final s in ts) {
      final d = s.d;
      final r = d.r;
      switch (d.t) {
        case 'saw':
          {
            final to = d.to!;
            final dur = math.sqrt(math.pow(to[0] - r[0], 2) + math.pow(to[1] - r[1], 2)) / (d.v ?? 120) * 1000;
            if (dur > 0) {
              final u = tw % (2 * dur);
              final p = _sine(u < dur ? u / dur : 2 - u / dur);
              s.x = _lerp(r[0], to[0], p);
              s.y = _lerp(r[1], to[1], p);
            }
          }
          break;
        case 'wall':
          {
            final to = d.to!;
            final dur = math.sqrt(math.pow(to[0] - r[0], 2) + math.pow(to[1] - r[1], 2)) / (d.v ?? 120) * 1000;
            if (dur > 0) {
              final period = 2 * dur + 600;
              final u = tw % period;
              double f;
              if (u < dur) {
                f = u / dur;
              } else if (u < dur + 300) {
                f = 1;
              } else if (u < 2 * dur + 300) {
                f = 1 - (u - dur - 300) / dur;
              } else {
                f = 0;
              }
              final p = _sine(f);
              s.x = _lerp(r[0], to[0], p);
              s.y = _lerp(r[1], to[1], p);
            }
          }
          break;
        case 'spike':
          if (s.on) {
            s.t += dt;
            s.alpha = 1;
            s.y = r[1] + r[3] * (1 - math.min(1.0, s.t / 80));
          }
          break;
        case 'block':
          if (s.on) {
            s.t += dt;
            final p = math.min(1.0, s.t / 220);
            s.y = _lerp(r[1], d.to![1], p * p); // Quad.In
          }
          break;
        case 'collapse':
          if (s.on) {
            s.t += dt;
            if (s.t < 260) {
              final m = s.t % 80;
              s.x = r[0] + 3 * (m < 40 ? m / 40 : 2 - m / 40);
            } else {
              final f = math.min(1.0, (s.t - 260) / 500);
              s.x = r[0];
              s.alpha = 1 - f;
              s.y = r[1] + 400 * f;
            }
          }
          break;
        case 'vanish':
          if (s.on && s.t >= 0) {
            s.t += dt;
            if (s.t > 350) s.alpha = 1 - math.min(1.0, (s.t - 350) / 150);
          }
          break;
      }
    }
  }

  Rect _hitbox(TrapState s) {
    final r = s.d.r;
    if (s.d.t == 'saw') {
      final cx = s.x + r[2] / 2, cy = s.y + r[3] / 2;
      return Rect.fromLTWH(cx - 14, cy - 14, 28, 28);
    }
    return Rect.fromLTWH(s.x + 3, s.y + 3, r[2] - 6, r[3] - 6);
  }

  // ---- per-tick game logic (input, traps, win / death) --------------------------------
  void _runTimers(double dt) {
    if (_timers.isEmpty) return;
    for (final t in _timers) {
      t.left -= dt;
    }
    final due = _timers.where((t) => t.left <= 0).toList();
    _timers.removeWhere((t) => t.left <= 0);
    for (final t in due) {
      if (t.gen == _gen) t.fn();
    }
  }

  void _update(double dt) {
    tw += dt;
    for (final m in msgs) {
      m.age += dt;
    }
    msgs.removeWhere((m) => m.age >= 1700);
    for (final s in sparks) {
      s.t += dt;
    }
    sparks.removeWhere((s) => s.t >= 400);
    for (final c in confetti) {
      c.t += dt;
    }
    confetti.removeWhere((c) => c.t >= c.dur + c.delay);
    if (shake > 0) shake = math.max(0, shake - dt);
    if (flash > 0) flash = math.max(0, flash - dt);
    if (won) winT += dt;

    _runTimers(dt);
    _animate(dt);
    if (dead || won) return;

    var dir = ((kR || tR) ? 1 : 0) - ((kL || tL) ? 1 : 0);
    if (rev > 0) {
      dir = -dir;
      rev -= dt;
      if (rev <= 0) _msg('Controls restored');
    }
    accX = dir * 1800.0;

    final gr = gf > 0 ? contactDown : contactUp;
    grounded = gr;
    coy = gr ? 100 : coy - dt;
    final jd = kJ || tJ;
    buf = (jd && !jp) ? 120 : buf - dt;
    jp = jd;
    if (buf > 0 && coy > 0) {
      vy = -560 * gf;
      buf = 0;
      coy = 0;
      Sfx.beep(420, .09, 'sine', 260);
    }
    if (!jd && vy * gf < -220) vy = -220 * gf;
    if (vx < -10) {
      flipX = true;
    } else if (vx > 10) {
      flipX = false;
    }

    for (final m in movers) {
      final v = (m.d.v ?? 100).abs();
      if (m.x <= m.d.r[0]) {
        m.vx = v;
      } else if (m.x >= m.d.to![0]) {
        m.vx = -v;
      }
    }

    clk += dt;
    final pr = Rect.fromLTWH(px, py, kPW, kPH);
    for (final s in ts) {
      if (s.d.t == 'timed') {
        s.kill = (clk + s.d.to![0]) % s.d.v! < s.d.v! / 2;
        s.alpha = s.kill ? 1 : .25;
      }
      if (!s.on && s.trig != null && _touching(pr, s.trig!)) _fire(s);
      if (s.kill && _touching(pr, _hitbox(s))) {
        _die();
        return;
      }
    }
    if (py > 570 || py < -90) {
      _die();
      return;
    }
    final ex = level.exit;
    if (_touching(pr, Rect.fromLTWH(ex[0], ex[1], 32, 48))) _win();
  }

  void _die() {
    if (dead || won) return;
    dead = true;
    deaths++;
    Sfx.beep(190, .3, 'triangle', -110);
    HapticFeedback.heavyImpact();
    final cx = px + kPW / 2, cy = py + kPH / 2;
    for (var n = 0; n < 12; n++) {
      sparks.add(Spark(cx, cy, _rnd(-70, 70), _rnd(-70, 40), _rnd(3, 5), n.isOdd ? 0xffe3b0 : 0xff9eb5));
    }
    if (!reduceMotion) shake = 120;
    after(350, () => start(index, fresh: false));
    ui.ping();
  }

  void _win() {
    if (won || dead) return;
    won = true;
    vx = 0;
    vy = 0;
    accX = 0;
    winT = 0;
    final s = Save.I;
    if (!s.done.contains(index)) s.done.add(index);
    s.unlocked = math.max(s.unlocked, math.min(index + 1, levels.length - 1));
    s.store();
    Sfx.beep(520, .4, 'triangle', 500);
    if (!reduceMotion) {
      const cols = [0xff9eb5, 0xffc9a3, 0x9ff0c8, 0x9cc8ff, 0xc9a8ff, 0xffe3b0];
      for (var n = 0; n < 26; n++) {
        confetti.add(Confetto(_rnd(40, 920), _rnd(6, 10), _rnd(4, 7), _rnd(-60, 60), _rnd(-360, 360),
            _rnd(1100, 1900), _rnd(0, 300), cols[n % 6]));
      }
    }
    after(1200, () {
      if (index + 1 < levels.length) {
        start(index + 1, fresh: true);
      } else {
        onMenu?.call();
      }
    });
    ui.ping();
  }

  // ---- physics (port of Phaser Arcade: 60 Hz semi-implicit Euler, AABB vs. statics) ---
  void _moveMovers(double dt) {
    for (final m in movers) {
      m.prevX = m.x;
      m.x += m.vx * dt;
    }
  }

  List<_Solid> _solids() {
    final out = <_Solid>[for (final p in plats) _Solid(p)];
    for (final s in ts) {
      final r = s.d.r;
      if ((s.d.t == 'collapse' || s.d.t == 'vanish') && s.solidOn) {
        out.add(_Solid(Rect.fromLTWH(r[0], r[1], r[2], r[3])));
      } else if (s.d.t == 'mover') {
        out.add(_Solid(Rect.fromLTWH(s.x, r[1], r[2], r[3]), s.vx, s));
      }
    }
    return out;
  }

  void _physics(double dt) {
    final solids = _solids();

    // carried by a moving platform
    final carrier = ride;
    if (carrier != null) px += carrier.x - carrier.prevX;

    // horizontal
    if (accX != 0) {
      vx += accX * dt;
    } else if (vx > 0) {
      vx = math.max(0.0, vx - 1500 * dt);
    } else if (vx < 0) {
      vx = math.min(0.0, vx + 1500 * dt);
    }
    vx = _cl(vx, -260, 260);
    px += vx * dt;
    if (px < 0) {
      px = 0;
      if (vx < 0) vx = 0;
    }
    if (px + kPW > kW) {
      px = kW - kPW;
      if (vx > 0) vx = 0;
    }
    for (final s in solids) {
      final pr = Rect.fromLTWH(px, py, kPW, kPH);
      if (_overlap(pr, s.rect)) {
        final rel = vx - s.vx;
        if (rel > 0) {
          px = s.rect.left - kPW;
        } else if (rel < 0) {
          px = s.rect.right;
        } else {
          px = (px + kPW / 2 < s.rect.center.dx) ? s.rect.left - kPW : s.rect.right;
        }
        vx = s.vx;
      }
    }

    // vertical (world gravity 1500, plus -3000 body gravity while flipped)
    final g = 1500.0 + (gf < 0 ? -3000.0 : 0.0);
    vy = _cl(vy + g * dt, -900, 900);
    py += vy * dt;
    contactDown = false;
    contactUp = false;
    ride = null;
    for (final s in solids) {
      final pr = Rect.fromLTWH(px, py, kPW, kPH);
      if (_overlap(pr, s.rect)) {
        if (vy > 0 || (vy == 0 && g > 0)) {
          py = s.rect.top - kPH;
          contactDown = true;
        } else {
          py = s.rect.bottom;
          contactUp = true;
        }
        vy = 0;
        if (s.mover != null) ride = s.mover;
      }
    }
  }
}
