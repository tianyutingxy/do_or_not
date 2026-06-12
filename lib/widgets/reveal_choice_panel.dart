import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user_response.dart';
import '../theme/app_theme.dart';
import 'shake_widget.dart';

class RevealChoicePanel extends StatelessWidget {
  const RevealChoicePanel({
    super.key,
    required this.onChoice,
    this.locked = false,
    this.shaking,
    this.confirmed,
    this.isMarked = false,
    this.onMarkToggle,
  });

  final void Function(UserResponse response) onChoice;
  final bool locked;
  final UserResponse? shaking;
  final UserResponse? confirmed;
  final bool isMarked;
  final ValueChanged<bool>? onMarkToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (confirmed != null) {
      return _ConfirmedPanel(
        response: confirmed!,
        isMarked: isMarked,
        onMarkToggle: onMarkToggle,
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              response: UserResponse.comply,
              icon: Icons.check_circle_outline_rounded,
              title: l10n.choiceComply,
              subtitle: l10n.choiceComplySubtitle,
              color: AppColors.doGreen,
            ),
            const SizedBox(height: 8),
            _buildButton(
              response: UserResponse.rebel,
              icon: Icons.bolt_rounded,
              title: l10n.choiceRebel,
              subtitle: l10n.choiceRebelSubtitle,
              color: AppColors.notRed,
            ),
            const SizedBox(height: 8),
            _buildButton(
              response: UserResponse.retry,
              icon: Icons.refresh_rounded,
              title: l10n.choiceRetry,
              subtitle: l10n.choiceRetrySubtitle,
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

class _ConfirmedPanel extends StatelessWidget {
  const _ConfirmedPanel({
    required this.response,
    required this.isMarked,
    this.onMarkToggle,
  });

  final UserResponse response;
  final bool isMarked;
  final ValueChanged<bool>? onMarkToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isComply = response == UserResponse.comply;
    final color = isComply ? AppColors.doGreen : AppColors.notRed;
    final icon = isComply ? Icons.check_circle_rounded : Icons.bolt_rounded;
    final line = isComply
        ? l10n.choiceConfirmedComply
        : l10n.choiceConfirmedRebel;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _MarkButton(
              isMarked: isMarked,
              onToggle: onMarkToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.isMarked,
    this.onToggle,
  });

  final bool isMarked;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = isMarked ? AppColors.gold : Colors.white54;
    final label = isMarked ? l10n.markedDecision : l10n.markDecision;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onToggle!(!isMarked);
              },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMarked
                  ? AppColors.gold.withValues(alpha: 0.55)
                  : Colors.white12,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMarked ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: color,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
