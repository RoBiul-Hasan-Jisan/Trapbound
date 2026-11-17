import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'backdrop.dart';
import 'engine.dart' show kW, kH;
import 'theme.dart';

/// Page change with a soft fade (replaces the current screen).
void go(BuildContext context, Widget page) {
  Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 150),
  ));
}

const BoxDecoration kSkyDecoration = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4A3D82), Color(0xFF7656A6), Color(0xFFA56FA8)],
    stops: [0, .55, 1],
  ),
);

/// A 960x540 canvas scaled to fit the screen, with the animated sky behind it.
class Stage extends StatelessWidget {
  const Stage({super.key, required this.children, this.orbs = 6});
  final List<Widget> children;
  final int orbs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7656A6),
      body: Container(
        decoration: kSkyDecoration,
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: kW,
              height: kH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [Positioned.fill(child: BackdropLayer(orbs: orbs)), ...children],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text centred on (x, y) in stage coordinates.
Widget tx(double x, double y, String s,
    {double size = 20, Color? color, int weight = 700, List<Shadow>? shadows}) {
  return Positioned(
    left: x - 480,
    top: y - size,
    width: 960,
    height: size * 2,
    child: Center(
      child: Text(s,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: ts(size, color ?? col(0xfdf6ff), weight, shadows)),
    ),
  );
}

/// Soft rounded button, centred on (x, y) in stage coordinates.
class SoftButton extends StatefulWidget {
  const SoftButton({
    super.key,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.color = 0xff9eb5,
    this.size = 26,
  });
  final double x, y, w, h, size;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final int color;

  @override
  State<SoftButton> createState() => _SoftButtonState();
}

class _SoftButtonState extends State<SoftButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final r = math.min(26.0, widget.h / 2.4);
    final radius = BorderRadius.circular(r);
    return Positioned(
      left: widget.x - widget.w / 2,
      top: widget.y - widget.h / 2,
      width: widget.w,
      height: widget.h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? .96 : 1,
          duration: const Duration(milliseconds: 80),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 5,
                bottom: -5,
                child: DecoratedBox(
                    decoration: BoxDecoration(color: col(0x140a28, .28), borderRadius: radius)),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: widget.primary
                      ? BoxDecoration(color: col(widget.color), borderRadius: radius)
                      : BoxDecoration(
                          color: col(0xffffff, .14),
                          borderRadius: radius,
                          border: Border.all(color: col(0xffffff, .3), width: 2)),
                ),
              ),
              if (widget.primary)
                Positioned(
                  left: 5,
                  right: 5,
                  top: 4,
                  height: widget.h * .4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: col(0xffffff, .22),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(r - 4),
                        topRight: Radius.circular(r - 4),
                        bottomLeft: Radius.circular(r / 3),
                        bottomRight: Radius.circular(r / 3),
                      ),
                    ),
                  ),
                ),
              Center(
                child: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Text(widget.label,
                      maxLines: 1,
                      style: ts(widget.size, widget.primary ? col(0x3b2d5c) : col(0xfdf6ff), 800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Left/right touch zone; slide between halves without lifting the finger.
class MovePad extends StatefulWidget {
  const MovePad({super.key, required this.onDir, this.width = 124, this.height = 76});
  final void Function(bool left, bool right) onDir;
  final double width, height;

  @override
  State<MovePad> createState() => _MovePadState();
}

class _MovePadState extends State<MovePad> {
  int? _act;
  int _d = 0;

  void _dir(PointerEvent e) {
    final x = e.localPosition.dx / widget.width;
    final l = x < .46, r = x > .54;
    setState(() => _d = l ? -1 : (r ? 1 : 0));
    widget.onDir(l, r);
  }

  void _end(PointerEvent e) {
    if (e.pointer != _act) return;
    _act = null;
    setState(() => _d = 0);
    widget.onDir(false, false);
  }

  @override
  Widget build(BuildContext context) {
    final rad = widget.height / 2;
    Widget half(String s, bool on) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            alignment: Alignment.center,
            color: on ? col(0xff9eb5, .42) : Colors.transparent,
            child: Text(s, style: ts(24, col(0xfdf6ff), 700)),
          ),
        );
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        _act = e.pointer;
        _dir(e);
      },
      onPointerMove: (e) {
        if (e.pointer == _act) _dir(e);
      },
      onPointerUp: _end,
      onPointerCancel: _end,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(rad),
          border: Border.all(color: col(0xffffff, .3), width: 1.5),
          color: col(0xffffff, .14),
          boxShadow: [BoxShadow(color: col(0x140a28, .35), blurRadius: 28, offset: const Offset(0, 10))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(children: [half('◀', _d < 0), half('▶', _d > 0)]),
      ),
    );
  }
}

class JumpButton extends StatefulWidget {
  const JumpButton({super.key, required this.onChange, this.size = 88});
  final void Function(bool down) onChange;
  final double size;

  @override
  State<JumpButton> createState() => _JumpButtonState();
}

class _JumpButtonState extends State<JumpButton> {
  int? _act;
  bool _on = false;

  void _set(bool v) {
    setState(() => _on = v);
    widget.onChange(v);
  }

  void _end(PointerEvent e) {
    if (e.pointer != _act) return;
    _act = null;
    _set(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        _act = e.pointer;
        HapticFeedback.selectionClick();
        _set(true);
      },
      onPointerUp: _end,
      onPointerCancel: _end,
      child: AnimatedScale(
        scale: _on ? .92 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: col(0xffffff, .45), width: 1.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _on
                  ? [col(0xffddc4), col(0xffaec4)]
                  : [col(0xffd0b0), col(0xff9eb5)],
            ),
            boxShadow: [BoxShadow(color: col(0x140a28, .38), blurRadius: 28, offset: const Offset(0, 10))],
          ),
          child: Text('▲', style: ts(28, col(0x3b2d5c), 800)),
        ),
      ),
    );
  }
}
