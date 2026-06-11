import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_response.dart';
import '../theme/app_theme.dart';

class RevealChoicePanel extends StatelessWidget {
  const RevealChoicePanel({
    super.key,
    required this.onChoice,
  });

  final void Function(UserResponse response) onChoice;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChoiceButton(
              icon: Icons.check_circle_outline_rounded,
              title: '遵从',
              subtitle: '就如此吧',
              color: AppColors.doGreen,
              onTap: () => _tap(UserResponse.comply, onChoice),
            ),
            const SizedBox(height: 8),
            _ChoiceButton(
              icon: Icons.bolt_rounded,
              title: '反抗',
              subtitle: '我就反着来',
              color: AppColors.notRed,
              onTap: () => _tap(UserResponse.rebel, onChoice),
            ),
            const SizedBox(height: 8),
            _ChoiceButton(
              icon: Icons.refresh_rounded,
              title: '再来一次',
              subtitle: '我有点犹豫',
              color: AppColors.gold,
              onTap: () => _tap(UserResponse.retry, onChoice),
            ),
          ],
        ),
      ),
    );
  }

  void _tap(UserResponse response, void Function(UserResponse) onChoice) {
    HapticFeedback.mediumImpact();
    onChoice(response);
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
