import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/simulation_models.dart';

// ─── Asset class color map ────────────────────────────────────────────────────
const Map<String, Color> _assetClassColors = {
  'coreEquity': Color(0xFF1B8A5A),
  'satelliteEquity': Color(0xFF2DBF7E),
  'hybrid': Color(0xFF3B82F6),
  'debt': Color(0xFF8B5CF6),
  'liquid': Color(0xFF06B6D4),
  'gold': Color(0xFFF59E0B),
  'alternate': Color(0xFFFF6B35),
};

Color _bandColor(String key) =>
    _assetClassColors[key] ?? const Color(0xFF8BA4C0);

Color _bucketColor(int bucketNumber) {
  switch (bucketNumber) {
    case 1:
      return AppColors.bucket1;
    case 2:
      return AppColors.bucket2;
    case 3:
      return AppColors.bucket3;
    default:
      return AppColors.bucket1;
  }
}

// ─── Compact ₹ formatter ──────────────────────────────────────────────────────
String _compactRupee(double value) {
  if (value >= 1e7) {
    return '₹${(value / 1e7).toStringAsFixed(1)}Cr';
  } else if (value >= 1e5) {
    return '₹${(value / 1e5).toStringAsFixed(1)}L';
  } else if (value >= 1e3) {
    return '₹${(value / 1e3).toStringAsFixed(0)}K';
  }
  return '₹${value.toStringAsFixed(0)}';
}

// ─── Public widget ────────────────────────────────────────────────────────────
class VerticalBuckets extends StatelessWidget {
  const VerticalBuckets({
    super.key,
    required this.buckets,
    this.height = 220,
  });

  final List<BucketComposition> buckets;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3-Bucket Allocation',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildBucketColumns(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBucketColumns() {
    final result = <Widget>[];
    for (int i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];
      result.add(
        Expanded(
          child: _BucketColumn(bucket: bucket, maxHeight: height),
        ),
      );

      // Spill arrow between buckets
      if (i < buckets.length - 1) {
        final hasSpill = bucket.overflowPct > 0 &&
            bucket.spillsIntoBucket != null &&
            bucket.spillsIntoBucket == buckets[i + 1].bucketNumber;
        result.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: _SpillArrow(active: hasSpill),
          ),
        );
      }
    }
    return result;
  }
}

// ─── Spill arrow widget ───────────────────────────────────────────────────────
class _SpillArrow extends StatelessWidget {
  const _SpillArrow({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.arrow_forward_rounded,
          size: 16,
          color: active
              ? AppColors.warning
              : context.palette.textTertiary.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

// ─── Single bucket column ─────────────────────────────────────────────────────
class _BucketColumn extends StatelessWidget {
  const _BucketColumn({
    required this.bucket,
    required this.maxHeight,
  });

  final BucketComposition bucket;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (bucket.status) {
      'overweight' => AppColors.loss,
      'underweight' => AppColors.warning,
      _ => AppColors.gain,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Overflow badge
        if (bucket.overflowPct > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.loss.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.loss.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Text(
              '+${bucket.overflowPct.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppColors.loss,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          const SizedBox(height: 20), // keep alignment uniform

        // Painter
        SizedBox(
          height: maxHeight,
          child: CustomPaint(
            painter: _BucketPainter(bucket: bucket),
            size: Size.infinite,
          ),
        ),

        const SizedBox(height: 6),

        // Bucket name
        Text(
          bucket.bucketName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 2),

        // current% → ideal%
        Text(
          '${bucket.currentPct.toStringAsFixed(0)}% → ${bucket.idealPct.toStringAsFixed(0)}%',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: statusColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 2),

        // ₹ value
        Text(
          _compactRupee(bucket.currentValue),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.palette.textSecondary,
            fontSize: 10,
          ),
        ),

        const SizedBox(height: 6),

        // Asset class legend dots (max 3)
        _LegendDots(bands: bucket.bands),
      ],
    );
  }
}

// ─── Legend dots ──────────────────────────────────────────────────────────────
class _LegendDots extends StatelessWidget {
  const _LegendDots({required this.bands});

  final List<AssetClassBand> bands;

  @override
  Widget build(BuildContext context) {
    final visible = bands.take(3).toList();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: visible.map((band) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _bandColor(band.assetClassKey),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              band.displayName,
              style: TextStyle(
                color: context.palette.textTertiary,
                fontSize: 9,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─── CustomPainter ────────────────────────────────────────────────────────────
class _BucketPainter extends CustomPainter {
  const _BucketPainter({required this.bucket});

  final BucketComposition bucket;

  @override
  void paint(Canvas canvas, Size size) {
    final bucketColor = _bucketColor(bucket.bucketNumber);
    final fillHeight = math.min(
      (bucket.currentPct / 100.0) * size.height,
      size.height,
    );
    final idealY = size.height - (bucket.idealPct / 100.0) * size.height;

    const radius = Radius.circular(6);
    final bucketRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bucketRRect = RRect.fromRectAndRadius(bucketRect, radius);

    // 1. Bucket outline / background
    final outlinePaint = Paint()
      ..color = bucketColor.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bucketRRect, outlinePaint);

    final borderPaint = Paint()
      ..color = bucketColor.withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(bucketRRect, borderPaint);

    // 2. Clip to bucket shape for band fills
    canvas.save();
    canvas.clipRRect(bucketRRect);

    // 3. Draw bands from bottom up
    if (bucket.bands.isNotEmpty) {
      double yOffset = size.height;
      for (final band in bucket.bands) {
        final bandHeight = (band.valuePct / 100.0) * fillHeight;
        if (bandHeight <= 0) continue;
        yOffset -= bandHeight;
        final bandRect = Rect.fromLTWH(0, yOffset, size.width, bandHeight);
        final bandPaint = Paint()
          ..color = _bandColor(band.assetClassKey).withValues(alpha: 0.60)
          ..style = PaintingStyle.fill;
        canvas.drawRect(bandRect, bandPaint);
      }
    } else {
      // Fallback: solid fill with bucket color
      final fillRect =
          Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight);
      final fillPaint = Paint()
        ..color = bucketColor.withValues(alpha: 0.50)
        ..style = PaintingStyle.fill;
      canvas.drawRect(fillRect, fillPaint);
    }

    canvas.restore();

    // 4. Dashed ideal line
    _drawDashedLine(
      canvas: canvas,
      y: idealY,
      width: size.width,
      color: AppColors.warning.withValues(alpha: 0.85),
    );

    // 5. "ideal" micro-label
    final labelPainter = TextPainter(
      text: const TextSpan(
        text: 'ideal',
        style: TextStyle(
          color: AppColors.warning,
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    final labelY = (idealY - labelPainter.height - 2).clamp(0.0, size.height);
    labelPainter.paint(canvas, Offset(size.width - labelPainter.width - 2, labelY));
  }

  void _drawDashedLine({
    required Canvas canvas,
    required double y,
    required double width,
    required Color color,
  }) {
    const dashWidth = 4.0;
    const gapWidth = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double x = 0;
    while (x < width) {
      final end = math.min(x + dashWidth, width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(_BucketPainter oldDelegate) =>
      oldDelegate.bucket != bucket;
}
