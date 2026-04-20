import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/risk_tiers.dart';

class RiskMeter extends StatefulWidget {
  const RiskMeter({super.key, required this.tier, this.size = 240});

  final RiskTier tier;
  final double size;

  @override
  State<RiskMeter> createState() => _RiskMeterState();
}

class _RiskMeterState extends State<RiskMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _anim;
  double _prevPos = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _anim = Tween<double>(begin: 0, end: widget.tier.meterPosition)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _prevPos = widget.tier.meterPosition;
  }

  @override
  void didUpdateWidget(covariant RiskMeter old) {
    super.didUpdateWidget(old);
    if (old.tier != widget.tier) {
      _anim = Tween<double>(begin: _prevPos, end: widget.tier.meterPosition)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
      _ctrl
        ..reset()
        ..forward();
      _prevPos = widget.tier.meterPosition;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.62,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (ctx, _) => CustomPaint(
          painter: _MeterPainter(
            position: _anim.value,
            activeColor: widget.tier.color,
          ),
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({required this.position, required this.activeColor});
  final double position; // 0..1
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    final segments = RiskTier.values.map((t) => t.color).toList();

    const startAngle = math.pi;
    const sweep = math.pi;
    final segSweep = sweep / segments.length;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;

    for (var i = 0; i < segments.length; i++) {
      arcPaint.color = segments[i].withValues(alpha: 0.85);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + i * segSweep,
        segSweep - 0.02,
        false,
        arcPaint,
      );
    }

    final angle = startAngle + position * sweep;
    final needleEnd = Offset(
      center.dx + math.cos(angle) * (radius - 4),
      center.dy + math.sin(angle) * (radius - 4),
    );
    final needlePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    canvas.drawCircle(center, 9, Paint()..color = activeColor);
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MeterPainter old) =>
      old.position != position || old.activeColor != activeColor;
}
