import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class HealthScoreCard extends StatelessWidget {
  const HealthScoreCard({
    super.key,
    required this.healthScore,
    required this.healthLabel,
  });

  final int healthScore;
  final String healthLabel;

  Color _gaugeColor() {
    if (healthScore >= 85) return AppColors.gain;
    if (healthScore >= 70) return const Color(0xFF84CC16); // lightGreen
    if (healthScore >= 50) return AppColors.warning;
    return AppColors.loss;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Health',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _GaugePainter(
                    score: healthScore,
                    gaugeColor: _gaugeColor(),
                    trackColor: context.palette.bgSurface,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$healthScore',
                          style: TextStyle(
                            color: _gaugeColor(),
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          healthLabel,
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.score,
    required this.gaugeColor,
    required this.trackColor,
  });

  final int score;
  final Color gaugeColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    const startAngle = math.pi * 0.75;   // 135 degrees
    const sweepTotal = math.pi * 1.5;    // 270 degrees arc

    // Track (background)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // Progress arc
    final progressSweep = sweepTotal * (score / 100.0);
    final progressPaint = Paint()
      ..color = gaugeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressSweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.gaugeColor != gaugeColor;
}
