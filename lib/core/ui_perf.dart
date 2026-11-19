import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter/widgets.dart';

/// UI-performance helpers for low-end devices.
class UiPerf {
  UiPerf._();

  /// Prefer quieter motion when the OS asks for reduced animation.
  static bool preferReducedMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// True for compact / low-density phones where chart density should drop.
  /// Biased toward treating more devices as low-end (safer for jank).
  static bool isLowEndLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return size.shortestSide < 400 ||
        size.height < 780 ||
        dpr <= 2.5;
  }

  /// Cap decoded bitmap size for a logical box (device pixels).
  static int cachePx(BuildContext context, double logicalPx) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalPx * dpr).round().clamp(32, 2048);
  }

  /// Keep chart paths cheap: at most [maxPoints] evenly spaced samples.
  static List<GlucoseSample> downsample(
    List<GlucoseSample> samples, {
    int maxPoints = 240,
  }) {
    if (samples.length <= maxPoints) return samples;
    final out = <GlucoseSample>[];
    final last = samples.length - 1;
    for (var i = 0; i < maxPoints; i++) {
      final index = ((i * last) / (maxPoints - 1)).round();
      out.add(samples[index]);
    }
    return out;
  }
}
