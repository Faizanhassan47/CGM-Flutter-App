import 'dart:math' as math;
import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class GlucoseTrendCard extends StatefulWidget {
  const GlucoseTrendCard({
    super.key,
    required this.samples,
    this.lowTarget = 90.0,
    this.highTarget = 130.0,
  });

  final List<GlucoseSample> samples;
  final double lowTarget;
  final double highTarget;

  @override
  State<GlucoseTrendCard> createState() => _GlucoseTrendCardState();
}

class _GlucoseTrendCardState extends State<GlucoseTrendCard> {
  String selectedSpan = '3H';

  Duration get _spanDuration {
    switch (selectedSpan) {
      case '3H':
        return const Duration(hours: 3);
      case '6H':
        return const Duration(hours: 6);
      case '12H':
        return const Duration(hours: 12);
      case '24H':
      default:
        return const Duration(hours: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cutoff = now.subtract(_spanDuration);

    final filtered = widget.samples
        .where((s) => s.value != null && s.measuredAt.isAfter(cutoff))
        .toList();

    // Calculate in target %
    int inTargetCount = 0;
    for (final s in filtered) {
      final mg = s.value! * 18.0182;
      if (mg >= widget.lowTarget && mg <= widget.highTarget) {
        inTargetCount++;
      }
    }
    final inTargetPercent = filtered.isEmpty
        ? 93
        : ((inTargetCount / filtered.length) * 100).round();

    return Container(
      padding: AppInsets.all20,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r24,
        border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Glucose Trend & Corridor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkPurple,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Continuous telemetry curve &\nglycemic target band',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: ['3H', '6H', '12H', '24H'].map((span) {
                  final isSelected = selectedSpan == span;
                  return GestureDetector(
                    onTap: () => setState(() => selectedSpan = span),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        span,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? AppTheme.primaryPurple
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IN TARGET',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$inTargetPercent%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: _CorridorChartPainter(
                samples: filtered,
                startTime: cutoff,
                endTime: now,
                lowTarget: widget.lowTarget,
                highTarget: widget.highTarget,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend matching screenshot 091620
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLegendItem(
                  'In target (${widget.lowTarget.round()}-${widget.highTarget.round()})',
                  AppPalette.hexFF00B2E2,
                ),
                const SizedBox(width: 14),
                _buildLegendItem(
                  'Low (<${widget.lowTarget.round()})',
                  AppPalette.hexFF0288D1,
                ),
                const SizedBox(width: 14),
                _buildLegendItem(
                  'High (>${widget.highTarget.round()})',
                  AppPalette.hexFF7E57C2,
                ),
                const SizedBox(width: 14),
                _buildLegendItem('Urgent (<55 / >250)', AppPalette.hexFF4A148C),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CorridorChartPainter extends CustomPainter {
  _CorridorChartPainter({
    required this.samples,
    required this.startTime,
    required this.endTime,
    required this.lowTarget,
    required this.highTarget,
  });

  final List<GlucoseSample> samples;
  final DateTime startTime;
  final DateTime endTime;
  final double lowTarget;
  final double highTarget;

  @override
  void paint(Canvas canvas, Size size) {
    final double minMg = 40.0;
    final double maxMg = 260.0;
    final double h = size.height;
    final double w = size.width;

    double yForMg(double mg) {
      final clamped = mg.clamp(minMg, maxMg);
      final ratio = (clamped - minMg) / (maxMg - minMg);
      return h - (ratio * h);
    }

    // 1. Draw Glycemic Target Corridor (90 - 130)
    final targetTop = yForMg(highTarget);
    final targetBottom = yForMg(lowTarget);
    final targetRect = Rect.fromLTRB(0, targetTop, w, targetBottom);

    final corridorPaint = Paint()
      ..color = AppPalette.hexFFE1F5FE.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, const Radius.circular(8)),
      corridorPaint,
    );

    // Target corridor boundary lines
    final dashPaint = Paint()
      ..color = AppPalette.hexFFB3E5FC
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(0, targetTop),
      Offset(w, targetTop),
      dashPaint,
    );
    _drawDashedLine(
      canvas,
      Offset(0, targetBottom),
      Offset(w, targetBottom),
      dashPaint,
    );

    if (samples.isEmpty) {
      // Draw smooth demonstration wave if no historical points yet
      final demoPath = Path();
      demoPath.moveTo(0, yForMg(110));
      demoPath.cubicTo(
        w * 0.25,
        yForMg(102),
        w * 0.45,
        yForMg(122),
        w * 0.7,
        yForMg(116),
      );
      demoPath.cubicTo(
        w * 0.85,
        yForMg(114),
        w * 0.95,
        yForMg(112),
        w,
        yForMg(112),
      );

      final linePaint = Paint()
        ..color = AppPalette.hexFF00B2E2
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(demoPath, linePaint);

      // Current end point dot
      final dotPaint = Paint()..color = AppPalette.hexFF00B2E2;
      canvas.drawCircle(Offset(w, yForMg(112)), 5, dotPaint);
      canvas.drawCircle(
        Offset(w, yForMg(112)),
        8,
        Paint()..color = AppPalette.hexFF00B2E2.withValues(alpha: 0.25),
      );
      return;
    }

    // 2. Plot actual samples
    final totalSpanMs = math.max(
      1,
      endTime.difference(startTime).inMilliseconds,
    );
    final points = <Offset>[];

    for (final s in samples) {
      if (s.value == null) continue;
      final ms = s.measuredAt.difference(startTime).inMilliseconds;
      final x = (ms / totalSpanMs).clamp(0.0, 1.0) * w;
      final mg = s.value! * 18.0182;
      final y = yForMg(mg);
      points.add(Offset(x, y));
    }

    if (points.length < 2) {
      if (points.isNotEmpty) {
        canvas.drawCircle(
          points.first,
          6,
          Paint()..color = AppPalette.hexFF00B2E2,
        );
      }
      return;
    }

    // Draw paths with gap handling (breaks curve when reading gap > 20 minutes)
    final curvePaint = Paint()
      ..color = AppPalette.hexFF00B2E2
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final validSamples = samples.where((s) => s.value != null).toList();
    Path currentPath = Path();
    bool hasActivePath = false;

    for (int i = 0; i < points.length; i++) {
      if (!hasActivePath) {
        currentPath.moveTo(points[i].dx, points[i].dy);
        hasActivePath = true;
      } else {
        final prevSample = validSamples[i - 1];
        final currSample = validSamples[i];
        final gapMinutes = currSample.measuredAt
            .difference(prevSample.measuredAt)
            .inMinutes
            .abs();

        if (gapMinutes > 20) {
          // Break path across the missing data gap
          canvas.drawPath(currentPath, curvePaint);
          currentPath = Path();
          currentPath.moveTo(points[i].dx, points[i].dy);
        } else {
          final p0 = points[i - 1];
          final p1 = points[i];
          final midX = (p0.dx + p1.dx) / 2;
          currentPath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
        }
      }
    }
    if (hasActivePath) {
      canvas.drawPath(currentPath, curvePaint);
    }

    // Latest dot
    final lastPoint = points.last;
    canvas.drawCircle(lastPoint, 5, Paint()..color = AppPalette.hexFF00B2E2);
    canvas.drawCircle(
      lastPoint,
      9,
      Paint()..color = AppPalette.hexFF00B2E2.withValues(alpha: 0.25),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double currentX = p1.dx;
    while (currentX < p2.dx) {
      canvas.drawLine(
        Offset(currentX, p1.dy),
        Offset(math.min(currentX + dashWidth, p2.dx), p1.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _CorridorChartPainter oldDelegate) => true;
}
