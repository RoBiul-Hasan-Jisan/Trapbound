import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'backdrop.dart';
import 'core.dart';
import 'engine.dart';
import 'levels.dart';
import 'painter.dart';
import 'theme.dart';
import 'ui.dart';

// ============================================================================ MENU ====
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final AnimationController _walk =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void initState() {
    super.initState();
    if (!kReduceMotion) {
      _bob.repeat(reverse: true);
      _walk.repeat();
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _walk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Save.I;
    final label = s.unlocked > 0 ? 'Continue' : 'Play';
    return Stage(
      orbs: 8,
      children: [
        AnimatedBuilder(
          animation: _bob,
          builder: (_, __) => tx(
            480,
            84 + 8 * Curves.easeInOutSine.transform(_bob.value),
            'Trapbound',
            size: 84,
            color: col(0xff9eb5),
            weight: 800,
            shadows: [Shadow(offset: const Offset(0, 5), blurRadius: 10, color: col(0x140a28, .4))],
          ),
        ),
        AnimatedBuilder(
          animation: _walk,
          builder: (_, __) {
            final p = _walk.value;
            final tri = p < .5 ? p * 2 : 2 - p * 2;
            final x = 760 + 110 * Curves.easeInOutSine.transform(tri);
            final f = (DateTime.now().millisecondsSinceEpoch ~/ 130) % 2 == 0;
            return Positioned(
              left: x - 30,
              top: 98 - 40,
              width: 60,
              height: 80,
              child: CustomPaint(
                painter: ManPainter(f ? 'man_run1' : 'man_run2', flipX: p >= .5, scale: 2.5),
              ),
            );
          },
        ),
        tx(480, 142, 'tread lightly… not everything is as it seems', size: 19, color: col(0xc9bde0), weight: 600),
        tx(480, 172, '${s.done.length} of ${levels.length} levels cleared', size: 16, color: col(0xc9bde0, .8)),
        SoftButton(
          x: 480,
          y: 240,
          w: 380,
          h: 68,
          label: label,
          primary: true,
          onTap: () => go(context, GameScreen(index: math.min(s.unlocked, levels.length - 1))),
        ),
        SoftButton(x: 480, y: 330, w: 320, h: 68, label: 'Levels', onTap: () => go(context, const LevelsScreen())),
        SoftButton(
          x: 480,
          y: 425,
          w: 300,
          h: 68,
          size: 24,
          label: 'Sound: ${s.sound ? 'on' : 'off'}',
          onTap: () => setState(() {
            s.sound = !s.sound;
            s.store();
          }),
        ),
        tx(
          480,
          505,
          isTouchDevice ? '◀ ▶ move  ·  ▲ jump  ·  II pause' : 'A/D or ←/→ move  ·  W/↑/Space jump  ·  R restart  ·  Esc pause',
          size: 16,
          color: col(0xc9bde0, .85),
          weight: 600,
        ),
      ],
    );
  }
}

// ========================================================================== LEVELS ====
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key, this.world});
  final int? world;
  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  late int w = widget.world ?? math.min(2, math.min(Save.I.unlocked, levels.length - 1) ~/ 10);

  Widget _tile(int k) {
    final i = w * 10 + k;
    final ok = i <= Save.I.unlocked;
    final done = Save.I.done.contains(i);
    final x = 480 + ((k % 5) - 2) * 150.0;
    final y = 205 + (k ~/ 5) * 115.0;
    final radius = BorderRadius.circular(22);
    return Positioned(
      left: x - 67,
      top: y - 48,
      width: 134,
      height: 96,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: ok ? () => go(context, GameScreen(index: i)) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 4,
              bottom: -4,
              child: DecoratedBox(decoration: BoxDecoration(color: col(0x140a28, .25), borderRadius: radius)),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: ok ? col(done ? 0x9ff0c8 : 0xffffff, done ? .26 : .14) : col(0xffffff, .06),
                  border: ok
                      ? Border.all(color: col(done ? 0x9ff0c8 : worldColors[w], .9), width: 2.5)
                      : null,
                ),
              ),
            ),
            Center(
              child: ok
                  ? Text('${k + 1}', style: ts(38, done ? col(0x9ff0c8) : col(0xffffff), 800))
                  : Opacity(opacity: .45, child: Text('🔒', style: ts(28, col(0xffffff)))),
            ),
            if (ok && done) Positioned(left: 101, top: 8, child: Text('✓', style: ts(20, col(0x9ff0c8)))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = [for (var k = 0; k < 10; k++) if (Save.I.done.contains(w * 10 + k)) k].length;
    return Stage(
      orbs: 6,
      children: [
        tx(480, 44, 'World ${w + 1} · ${worldNames[w]}', size: 34, color: col(worldColors[w]), weight: 800),
        tx(480, 84, '$doneCount of 10 cleared', size: 16, color: col(0xc9bde0)),
        Positioned(
          left: 480 - 120,
          top: 102,
          width: 240,
          height: 12,
          child: Stack(children: [
            Positioned.fill(
                child: DecoratedBox(
                    decoration: BoxDecoration(color: col(0xffffff, .14), borderRadius: BorderRadius.circular(6)))),
            if (doneCount > 0)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: math.max(12.0, 240.0 * doneCount / 10),
                child: DecoratedBox(
                    decoration: BoxDecoration(color: col(worldColors[w]), borderRadius: BorderRadius.circular(6))),
              ),
          ]),
        ),
        for (final dw in const [-1, 1])
          if (w + dw >= 0 && w + dw <= 2)
            SoftButton(
              x: 480.0 + dw * 420,
              y: 270,
              w: 84,
              h: 180,
              size: 36,
              label: dw < 0 ? '◀' : '▶',
              onTap: () => setState(() => w += dw),
            ),
        for (var k = 0; k < 10; k++) _tile(k),
        SoftButton(x: 480, y: 470, w: 260, h: 64, size: 24, label: 'Back', onTap: () => go(context, const MenuScreen())),
      ],
    );
  }
}

// =========================================================================== GAME =====
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.index});
  final int index;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const double _step = 1000 / 60;
  late final TrapboundGame g;
  late final Ticker _tk;
  late final BackdropSpec _spec = BackdropSpec(5, 23);
  final FocusNode _focus = FocusNode();
  Duration? _last;
  double _acc = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    g = TrapboundGame()
      ..reduceMotion = kReduceMotion
      ..onMenu = () {
        if (mounted) go(context, const MenuScreen());
      }
      ..start(widget.index);
    _tk = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tk.dispose();
    _focus.dispose();
    g.dispose();
    super.dispose();
  }

  void _onTick(Duration e) {
    final dt = _last == null ? 0.0 : (e - _last!).inMicroseconds / 1000.0;
    _last = e;
    final d = dt > 50 ? 50.0 : dt;
    g.bgT += d;
    _acc += d;
    var n = 0;
    while (_acc >= _step && n < 4) {
      g.tick(_step);
      _acc -= _step;
      n++;
    }
    if (n == 4) _acc = 0;
    g.repaint();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s != AppLifecycleState.resumed) {
      g.tL = g.tR = g.tJ = false;
      if (!g.dead && !g.won && !g.paused) _pause(true);
    }
  }

  void _pause(bool on) {
    g.paused = on;
    g.ui.ping();
  }

  void _restart() {
    g.start(g.index, fresh: false);
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    final down = e is KeyDownEvent;
    final up = e is KeyUpEvent;
    if (!down && !up) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.keyA || k == LogicalKeyboardKey.arrowLeft) {
      g.kL = down;
    } else if (k == LogicalKeyboardKey.keyD || k == LogicalKeyboardKey.arrowRight) {
      g.kR = down;
    } else if (k == LogicalKeyboardKey.keyW || k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.space) {
      g.kJ = down;
    } else if (down && k == LogicalKeyboardKey.keyR) {
      _restart();
    } else if (down && k == LogicalKeyboardKey.escape) {
      if (!g.dead && !g.won) _pause(!g.paused);
    } else if (down && k == LogicalKeyboardKey.keyM && g.paused) {
      go(context, const MenuScreen());
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _pill(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: col(0x1b1530, .4), borderRadius: BorderRadius.circular(14)),
        child: Text(t, style: ts(16, c, 700)),
      );

  Widget _hud() {
    final wc = worldColors[g.index ~/ 10];
    return Stack(clipBehavior: Clip.none, children: [
      Positioned(left: 72, top: 8, child: _pill('${g.index ~/ 10 + 1}-${g.index % 10 + 1}  ${g.level.name}', col(wc))),
      Positioned(right: 12, top: 8, child: _pill('oops ${g.deaths}', col(0xc9bde0))),
      Positioned(
        left: 8,
        top: 8,
        width: 56,
        height: 56,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!g.dead && !g.won) _pause(!g.paused);
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: col(0xffffff, .16),
              border: Border.all(color: col(0xffffff, .32), width: 2),
            ),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < 2; i++) ...[
                if (i == 1) const SizedBox(width: 6),
                Container(
                    width: 6,
                    height: 20,
                    decoration: BoxDecoration(color: col(0xfdf6ff), borderRadius: BorderRadius.circular(3))),
              ]
            ]),
          ),
        ),
      ),
      if (g.paused) ..._pauseMenu(),
      if (g.won) _winCard(),
    ]);
  }

  List<Widget> _pauseMenu() {
    final labels = ['Resume', 'Restart', 'Sound: ${Save.I.sound ? 'on' : 'off'}', 'Menu'];
    final acts = <VoidCallback>[
      () => _pause(false),
      () => _restart(),
      () {
        Save.I.sound = !Save.I.sound;
        Save.I.store();
        g.ui.ping();
      },
      () => go(context, const MenuScreen()),
    ];
    return [
      Positioned.fill(child: GestureDetector(onTap: () {}, child: ColoredBox(color: col(0x140a28, .62)))),
      Positioned(
        left: 480 - 210,
        top: 262 - 230,
        width: 420,
        height: 460,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: col(0x1b1530, .7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: col(0xffffff, .28), width: 2),
          ),
        ),
      ),
      tx(480, 92, 'Paused', size: 42, weight: 800),
      for (var k = 0; k < 4; k++)
        SoftButton(
          x: 480,
          y: 175.0 + k * 85,
          w: 340,
          h: 68,
          label: labels[k],
          primary: k == 0,
          color: 0x9ff0c8,
          onTap: acts[k],
        ),
    ];
  }

  Widget _winCard() => Positioned.fill(
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: g.reduceMotion ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 250),
            builder: (_, v, child) => Opacity(opacity: v, child: child),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: 480 - 190,
                top: 270 - 75,
                width: 380,
                height: 150,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: col(0x1b1530, .65),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: col(0x9ff0c8, .28), width: 2),
                  ),
                ),
              ),
              tx(480, 244, 'Nicely done!', size: 44, color: col(0x9ff0c8), weight: 800),
              tx(480, 298, 'level cleared  ·  oops ${g.deaths}', size: 20),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final touch = isTouchDevice;
    final sideL = 142.0 + pad.left, sideR = 142.0 + pad.right;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (g.paused) {
          go(context, const MenuScreen());
        } else if (!g.dead && !g.won) {
          _pause(true);
        }
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _key,
        child: Scaffold(
          backgroundColor: const Color(0xFF7656A6),
          body: Container(
            decoration: kSkyDecoration,
            child: Row(children: [
              if (touch)
                SizedBox(
                  width: sideL,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: math.max(16.0, pad.left), bottom: math.max(16.0, pad.bottom)),
                      child: MovePad(onDir: (l, r) {
                        g.tL = l;
                        g.tR = r;
                      }),
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: kW,
                      height: kH,
                      child: Stack(clipBehavior: Clip.hardEdge, children: [
                        Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: GamePainter(g, _spec)))),
                        Positioned.fill(child: AnimatedBuilder(animation: g.ui, builder: (_, __) => _hud())),
                      ]),
                    ),
                  ),
                ),
              ),
              if (touch)
                SizedBox(
                  width: sideR,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: math.max(16.0, pad.right), bottom: math.max(16.0, pad.bottom)),
                      child: JumpButton(onChange: (v) => g.tJ = v),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
