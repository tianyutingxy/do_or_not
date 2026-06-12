import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum Suit { spade, heart, diamond, club }

extension SuitX on Suit {
  String get symbol => switch (this) {
        Suit.spade => '♠',
        Suit.heart => '♥',
        Suit.diamond => '♦',
        Suit.club => '♣',
      };

  Color get color => switch (this) {
        Suit.heart || Suit.diamond => const Color(0xFFC62828),
        Suit.spade || Suit.club => const Color(0xFF1A1A2E),
      };
}

class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget({
    super.key,
    required this.rank,
    required this.suit,
    this.width = 100,
    this.faceDown = false,
    this.highlight = false,
    this.highlightStrength = 1.0,
    this.opacity = 1.0,
  });

  final String rank;
  final Suit suit;
  final double width;
  final bool faceDown;
  final bool highlight;
  final double highlightStrength;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;
    final t = opacity.clamp(0.0, 1.0);
    final glow = highlight ? highlightStrength.clamp(0.0, 1.0) : 0.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: glow > 0
                ? AppColors.gold.withValues(alpha: 0.6 * glow * t)
                : Colors.black.withValues(alpha: 0.5 * t),
            blurRadius: 12 + 12 * glow,
            spreadRadius: 2 * glow,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: faceDown ? _buildBack() : _buildFront(),
      ),
    );
  }

  Widget _buildBack() {
    final t = opacity.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E3A5F).withValues(alpha: t),
            const Color(0xFF0D1B2A).withValues(alpha: t),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: width * 0.75,
          height: width * 1.0,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.4 * t),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final suit in Suit.values)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.012),
                      child: Text(
                        suit.symbol,
                        style: TextStyle(
                          fontSize: width * 0.18,
                          color: suit.color.withValues(alpha: 0.72 * t),
                          height: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFront() {
    final t = opacity.clamp(0.0, 1.0);

    return Container(
      color: AppColors.cardWhite.withValues(alpha: t),
      padding: EdgeInsets.all(width * 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rank,
            style: TextStyle(
              fontSize: width * 0.28,
              fontWeight: FontWeight.w800,
              color: suit.color.withValues(alpha: t),
              height: 1,
            ),
          ),
          Text(
            suit.symbol,
            style: TextStyle(
              fontSize: width * 0.22,
              color: suit.color.withValues(alpha: t),
              height: 1,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: 3.14159,
              child: Column(
                children: [
                  Text(
                    rank,
                    style: TextStyle(
                      fontSize: width * 0.28,
                      fontWeight: FontWeight.w800,
                      color: suit.color.withValues(alpha: t),
                      height: 1,
                    ),
                  ),
                  Text(
                    suit.symbol,
                    style: TextStyle(
                      fontSize: width * 0.22,
                      color: suit.color.withValues(alpha: t),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
