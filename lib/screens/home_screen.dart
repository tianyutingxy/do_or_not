import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/animation_style.dart' show RevealStyle;
import '../models/decision.dart';
import '../models/user_response.dart';
import '../models/user_stats.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/card_reveal_animation.dart';
import '../widgets/coin_reveal_animation.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _statsService = StatsService();
  final _random = Random();

  UserStats _stats = const UserStats();
  RevealStyle _style = RevealStyle.coin;
  bool _isDeciding = false;
  Decision? _pendingDecision;
  int _decisionRound = 0;
  int _sessionRetryCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _statsService.loadStats();
    final styleName = await _statsService.loadAnimationStyle();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      if (styleName != null) {
        _style = RevealStyle.values.firstWhere(
          (s) => s.name == styleName,
          orElse: () => RevealStyle.coin,
        );
      }
    });
  }

  Future<void> _decide() async {
    if (_isDeciding) return;

    HapticFeedback.mediumImpact();
    final decision = _random.nextBool() ? Decision.doIt : Decision.notIt;

    setState(() {
      _isDeciding = true;
      _pendingDecision = decision;
      _decisionRound++;
      _sessionRetryCount = 0;
    });
  }

  void _onRevealed() {
    // 动画播完，等待用户选择；统计在 _onChoice 中记录
  }

  Future<void> _onChoice(UserResponse response) async {
    final objective = _pendingDecision;
    if (objective == null) return;

    switch (response) {
      case UserResponse.comply:
        await _finalize(objective, UserResponse.comply);
      case UserResponse.rebel:
        await _finalize(objective.opposite, UserResponse.rebel);
      case UserResponse.retry:
        HapticFeedback.lightImpact();
        _sessionRetryCount++;
        final updated = await _statsService.recordRetryPress();
        if (!mounted) return;
        final next = _random.nextBool() ? Decision.doIt : Decision.notIt;
        setState(() {
          _stats = updated;
          _pendingDecision = next;
          _decisionRound++;
        });
    }
  }

  Future<void> _finalize(Decision recorded, UserResponse response) async {
    final updated = await _statsService.recordUserChoice(
      decision: recorded,
      response: response,
      retriesThisSession: _sessionRetryCount,
    );
    if (!mounted) return;
    setState(() {
      _stats = updated;
      _isDeciding = false;
      _pendingDecision = null;
      _sessionRetryCount = 0;
    });
  }

  Future<void> _switchStyle(RevealStyle style) async {
    if (_style == style) return;
    HapticFeedback.selectionClick();
    await _statsService.saveAnimationStyle(style.name);
    if (!mounted) return;
    setState(() => _style = style);
  }

  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatsScreen(stats: _stats),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'DO OR NOT',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          letterSpacing: 6,
                          color: AppColors.gold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text('二选一，命运替你决定', style: TextStyle(color: Colors.white38)),
                  const SizedBox(height: 40),
                  _StyleSelector(
                    current: _style,
                    onChanged: _isDeciding ? null : _switchStyle,
                  ),
                  const Spacer(),
                  _DecideButton(
                    onPressed: _isDeciding ? null : _decide,
                  ),
                  const SizedBox(height: 24),
                  _MiniStatsBar(stats: _stats, onTap: _openStats),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isDeciding && _pendingDecision != null)
            Positioned.fill(
              child: _style == RevealStyle.coin
                  ? CoinRevealAnimation(
                      key: ValueKey(_decisionRound),
                      decision: _pendingDecision!,
                      onRevealed: _onRevealed,
                      onChoice: _onChoice,
                    )
                  : CardRevealAnimation(
                      key: ValueKey(_decisionRound),
                      decision: _pendingDecision!,
                      onRevealed: _onRevealed,
                      onChoice: _onChoice,
                    ),
            ),
        ],
      ),
    );
  }
}

class _StyleSelector extends StatelessWidget {
  const _StyleSelector({required this.current, required this.onChanged});

  final RevealStyle current;
  final void Function(RevealStyle)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: RevealStyle.values.map((style) {
        final selected = style == current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: style == RevealStyle.coin ? 8 : 0,
              left: style == RevealStyle.cards ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(style),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppColors.gold.withValues(alpha: 0.6)
                        : Colors.white12,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      style == RevealStyle.coin
                          ? Icons.toll_rounded
                          : Icons.style_rounded,
                      color: selected ? AppColors.gold : Colors.white38,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      style.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : Colors.white54,
                      ),
                    ),
                    Text(
                      style.subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.white30),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DecideButton extends StatefulWidget {
  const _DecideButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<_DecideButton> createState() => _DecideButtonState();
}

class _DecideButtonState extends State<_DecideButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = enabled ? 0.15 + _pulse.value * 0.15 : 0.0;
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.25 + glow),
                  AppColors.surface,
                ],
              ),
              border: Border.all(
                color: enabled
                    ? AppColors.gold.withValues(alpha: 0.5 + glow)
                    : Colors.white12,
                width: 2,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: glow),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '去吧',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text('TAP', style: TextStyle(fontSize: 12, color: Colors.white38, letterSpacing: 4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatsBar extends StatelessWidget {
  const _MiniStatsBar({required this.stats, required this.onTap});

  final UserStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(AppColors.doGreen, 'DO ${stats.doCount}'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('·', style: TextStyle(color: Colors.white24)),
            ),
            _dot(AppColors.notRed, 'NOT ${stats.notCount}'),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white60, fontSize: 14)),
      ],
    );
  }
}
