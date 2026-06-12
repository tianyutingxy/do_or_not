import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_version.dart';
import '../theme/app_theme.dart';

Future<void> showAboutAuthorCard(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: _PixelAboutCard(l10n: l10n),
      );
    },
  );
}

class _PixelAboutCard extends StatelessWidget {
  const _PixelAboutCard({required this.l10n});

  final AppLocalizations l10n;

  static const _border = 3.0;
  static const _shadow = 6.0;

  TextStyle get _titleStyle => GoogleFonts.pressStart2p(
        fontSize: 16,
        color: AppColors.gold,
        height: 1.55,
      );

  TextStyle get _bodyStyle => GoogleFonts.vt323(
        fontSize: 22,
        color: Colors.white.withValues(alpha: 0.88),
        height: 1.4,
      );

  TextStyle get _quoteStyle => GoogleFonts.vt323(
        fontSize: 21,
        color: Colors.white.withValues(alpha: 0.72),
        height: 1.45,
      );

  TextStyle get _buttonStyle => GoogleFonts.pressStart2p(
        fontSize: 13,
        color: Colors.black,
        height: 1.45,
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: _shadow,
          top: _shadow,
          right: -_shadow,
          bottom: -_shadow,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.black, width: _border),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.gold, width: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: double.infinity,
                    height: 78,
                    color: AppColors.gold,
                  ),
                  Positioned(
                    bottom: -42,
                    child: _SquareAvatar(asset: kAuthorAvatarAsset),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: _titleStyle,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: CustomPaint(
                  painter: _DashedRectPainter(
                    color: AppColors.gold.withValues(alpha: 0.55),
                    strokeWidth: 2,
                    dash: 6,
                    gap: 4,
                  ),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.background,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoLine(
                          label: l10n.aboutVersionLabel,
                          value: kAppVersion,
                          style: _bodyStyle,
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.aboutAuthorQuote, style: _quoteStyle),
                        const SizedBox(height: 12),
                        _InfoLine(
                          label: l10n.aboutContactLabel,
                          value: kAuthorContactDisplay,
                          style: _bodyStyle.copyWith(
                            color: AppColors.gold,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.gold.withValues(alpha: 0.55),
                          ),
                          onTap: () {
                            Clipboard.setData(
                              const ClipboardData(text: kAuthorContactEmail),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.aboutContactCopied)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                child: _PixelButton(
                  label: l10n.aboutGotIt,
                  style: _buttonStyle,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SquareAvatar extends StatelessWidget {
  const _SquareAvatar({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.gold, width: 3),
      ),
      child: Image.asset(
        asset,
        width: 84,
        height: 84,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    required this.style,
    this.onTap,
  });

  final String label;
  final String value;
  final TextStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: style.copyWith(color: Colors.white.withValues(alpha: 0.45)),
          ),
          TextSpan(text: value, style: style),
        ],
      ),
    );

    if (onTap == null) return text;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: text,
    );
  }
}

class _PixelButton extends StatelessWidget {
  const _PixelButton({
    required this.label,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onPressed;

  static const _shadow = 4.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: _shadow,
          top: _shadow,
          right: -_shadow,
          bottom: -_shadow,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: const SizedBox(width: double.infinity, height: 48),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: Material(
            color: AppColors.gold,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: Text(label, style: style, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold, width: 3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRect(Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) => false;
}
