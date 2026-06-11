import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_response.dart';
import '../theme/app_theme.dart';
import 'shake_widget.dart';

class RevealChoicePanel extends StatelessWidget {
  const RevealChoicePanel({
    super.key,
    required this.onChoice,
    this.locked = false,
    this.shaking,
  });

  final void Function(UserResponse response) onChoice;
  final bool locked;
  final UserResponse? shaking;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              response: UserResponse.comply,
              icon: Icons.check_circle_outline_rounded,
              title: '遵从',
              subtitle: '就如此吧',
              color: AppColors.doGreen,
            ),
            const SizedBox(height: 8),
            _buildButton(
              response: UserResponse.rebel,
              icon: Icons.bolt_rounded,
              title: '反抗',
              subtitle: '我就反着来',
              color: AppColors.notRed,
            ),
            const SizedBox(height: 8),
            _buildButton(
              response: UserResponse.retry,
              icon: Icons.refresh_rounded,
              title: '再来一次',
              subtitle: '我有点犹豫',
              color: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required UserResponse response,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isShaking = shaking == response;
    final enabled = !locked || isShaking;

    final button = _ChoiceButton(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
      highlighted: isShaking,
      enabled: enabled,
      onTap: () {
        if (locked) return;
        if (response == UserResponse.retry) {
          HapticFeedback.lightImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
        onChoice(response);
      },
    );

    return ShakeWidget(shake: isShaking, child: button);
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.enabled = true,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: highlighted ? 1 : 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: highlighted ? 0.85 : 0.35),
              width: highlighted ? 2 : 1,
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
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
