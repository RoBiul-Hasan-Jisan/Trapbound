import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const String kFamily = 'Nunito';
const List<String> kFallback = ['Quicksand', 'Trebuchet MS', 'sans-serif'];

/// World accent colours (same as the Phaser version).
const List<int> worldColors = [0xff9eb5, 0x9cc8ff, 0xc9a8ff];
const List<String> worldNames = ['The Warm-Up', 'False Confidence', 'Reality Glitch'];

/// rgb like 0xff9eb5 + opacity 0..1 -> Color
Color col(int rgb, [double a = 1]) =>
    Color(0xFF000000 | rgb).withAlpha((a.clamp(0.0, 1.0) * 255).round());

TextStyle ts(double size, Color color, [int weight = 700, List<Shadow>? shadows]) => TextStyle(
      fontFamily: kFamily,
      fontFamilyFallback: kFallback,
      fontSize: size,
      color: color,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      shadows: shadows,
      decoration: TextDecoration.none,
    );

bool get kReduceMotion =>
    WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

bool get isTouchDevice =>
    defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
