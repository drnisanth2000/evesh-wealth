import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class EVeshLogo extends StatelessWidget {
  const EVeshLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'e',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.55,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            children: [
              const TextSpan(
                text: 'e',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(
                text: 'Vesh',
                style: TextStyle(color: context.palette.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
