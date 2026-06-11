import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class RevealBackButton extends StatelessWidget {
  const RevealBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          label: const Text(
            '返回',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: AppColors.surface.withValues(alpha: 0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.white12),
            ),
          ),
        ),
      ),
    );
  }
}
