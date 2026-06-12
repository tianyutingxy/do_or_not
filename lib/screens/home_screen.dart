import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../l10n/reveal_style_l10n.dart';
import '../models/animation_style.dart' show RevealStyle;
import '../models/decision.dart';
import '../models/user_response.dart';
import '../models/user_stats.dart';
import '../services/decision_record_service.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/card_reveal_animation.dart';
import '../widgets/coin_reveal_animation.dart';
import '../widgets/pixel_cat/home_pixel_cat.dart';
import '../widgets/pixel_cat/pixel_paw_slap.dart';
import '../widgets/journal_lamp_button.dart';
import 'journal_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _statsService = StatsService();
  final _decisionRecordService = DecisionRecordService();
  final _random = Random();
  final _bodyStackKey = GlobalKey();
  final _catKey = GlobalKey<HomePixelCatState>();
  final _coinStyleKey = GlobalKey();
  final _cardsStyleKey = GlobalKey();
  final _patrolAreaKey = GlobalKey();

  UserStats _stats = const UserStats();
  RevealStyle _style = RevealStyle.coin;
  bool _isDeciding = false;
  bool _pawSlapping = false;
  Rect? _pawTargetRect;
  final _pawSlapCompleter = _AsyncGate();
  Decision? _pendingDecision;
  int _decisionRound = 0;
  int _sessionRetryCount = 0;
  bool _isConfirming = false;
  UserResponse? _confirmingResponse;
  UserResponse? _confirmedResponse;
  int? _currentRecordId;
  bool _isMarked = false;
  bool _hasMarkedRecords = false;
  Rect _patrolBounds = Rect.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _statsService.loadStats();
    final styleName = await _statsService.loadAnimationStyle();
    final markedCount = await _decisionRecordService.countMarked();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _hasMarkedRecords = markedCount > 0;
      if (styleName != null) {
        _style = RevealStyle.values.firstWhere(
          (s) => s.name == styleName,
          orElse: () => RevealStyle.coin,
        );
      }
    });
  }

  Future<void> _refreshJournalBadge() async {
    final markedCount = await _decisionRecordService.countMarked();
    if (!mounted) return;
    setState(() => _hasMarkedRecords = markedCount > 0);
  }

  Offset _stackOrigin() {
    final stackBox =
        _bodyStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return Offset.zero;
    return stackBox.localToGlobal(Offset.zero);
  }

  void _updatePatrolBounds() {
    final areaBox =
        _patrolAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (areaBox == null || !areaBox.hasSize) return;

    final origin = _stackOrigin();
    final topLeft = areaBox.localToGlobal(Offset.zero) - origin;
    final next = topLeft & areaBox.size;
    final patrolChanged = next != _patrolBounds;
    if (patrolChanged) {
      final firstLayout = _patrolBounds == Rect.zero;
      setState(() => _patrolBounds = next);
      if (_catKey.currentState != null && !_isDeciding) {
        if (firstLayout) {
          _catKey.currentState!.beginHomeSession(_patrolBounds);
        } else {
          _catKey.currentState!.updateBounds(_patrolBounds);
        }
      }
    }
  }

  void _beginCatHomeSession() {
    if (_patrolBounds == Rect.zero) return;
    _catKey.currentState?.beginHomeSession(_patrolBounds);
  }

  Rect? _selectedStyleRectInStack() {
    final key = _style == RevealStyle.coin ? _coinStyleKey : _cardsStyleKey;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final origin = _stackOrigin();
    final topLeft = box.localToGlobal(Offset.zero) - origin;
    return topLeft & box.size;
  }

  Future<void> _decide() async {
    if (_isDeciding || _pawSlapping) return;

    _catKey.currentState?.freeze();
    HapticFeedback.mediumImpact();

    final pawRect = _selectedStyleRectInStack();
    if (pawRect != null) {
      setState(() {
        _pawSlapping = true;
        _pawTargetRect = pawRect;
      });
      await _pawSlapCompleter.wait();
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    if (!mounted) return;

    final decision = _random.nextBool() ? Decision.doIt : Decision.notIt;
    setState(() {
      _pawSlapping = false;
      _pawTargetRect = null;
      _isDeciding = true;
      _pendingDecision = decision;
      _decisionRound++;
      _sessionRetryCount = 0;
      _isConfirming = false;
      _confirmingResponse = null;
      _confirmedResponse = null;
      _currentRecordId = null;
      _isMarked = false;
    });
  }

  void _onRevealed() {
    // 动画播完，等待用户选择；统计在 _onChoice 中记录
  }

  Future<void> _onChoice(UserResponse response) async {
    final objective = _pendingDecision;
    if (objective == null || _isConfirming) return;

    switch (response) {
      case UserResponse.comply:
        await _finalizeWithShake(objective, UserResponse.comply);
      case UserResponse.rebel:
        await _finalizeWithShake(objective.opposite, UserResponse.rebel);
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
          _isConfirming = false;
          _confirmingResponse = null;
          _confirmedResponse = null;
          _currentRecordId = null;
          _isMarked = false;
        });
    }
  }

  Future<void> _finalizeWithShake(
    Decision recorded,
    UserResponse response,
  ) async {
    setState(() {
      _isConfirming = true;
      _confirmingResponse = response;
      _confirmedResponse = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 560));
    if (!mounted) return;

    final updated = await _statsService.recordUserChoice(
      decision: recorded,
      response: response,
      retriesThisSession: _sessionRetryCount,
    );
    if (!mounted) return;

    final objective = _pendingDecision!;
    final record = await _decisionRecordService.createFromSession(
      revealStyle: _style,
      objective: objective,
      finalDecision: recorded,
      response: response,
      retryCount: _sessionRetryCount,
    );
    if (!mounted) return;

    setState(() {
      _stats = updated;
      _confirmingResponse = null;
      _confirmedResponse = response;
      _currentRecordId = record.id;
      _isMarked = false;
    });
  }

  Future<void> _onMarkToggle(bool marked) async {
    final id = _currentRecordId;
    if (id == null) return;

    await _decisionRecordService.setMarked(id, marked);
    if (!mounted) return;
    setState(() => _isMarked = marked);
    await _refreshJournalBadge();
  }

  void _exitReveal() {
    HapticFeedback.lightImpact();
    setState(() {
      _isDeciding = false;
      _pendingDecision = null;
      _sessionRetryCount = 0;
      _isConfirming = false;
      _confirmingResponse = null;
      _confirmedResponse = null;
      _currentRecordId = null;
      _isMarked = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _beginCatHomeSession();
      _refreshJournalBadge();
    });
  }

  Future<void> _switchStyle(RevealStyle style) async {
    if (_style == style) return;
    HapticFeedback.selectionClick();
    await _statsService.saveAnimationStyle(style.name);
    if (!mounted) return;
    setState(() => _style = style);
  }

  Future<void> _openJournal() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => JournalScreen(service: _decisionRecordService),
      ),
    );
    if (!mounted) return;
    await _refreshJournalBadge();
    _beginCatHomeSession();
  }

  Future<void> _openStats() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => StatsScreen(stats: _stats),
      ),
    );
    if (!mounted) return;
    await _refreshJournalBadge();
    _beginCatHomeSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePatrolBounds());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showCat = !_isDeciding;

    return Scaffold(
      body: Stack(
        key: _bodyStackKey,
        clipBehavior: Clip.none,
        children: [
          if (_patrolBounds != Rect.zero)
            HomePixelCat(
              key: _catKey,
              patrolBounds: _patrolBounds,
              visible: showCat || _pawSlapping,
              frozen: _pawSlapping,
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      JournalLampButton(
                        isBright: _hasMarkedRecords,
                        enabled: !_isDeciding && !_pawSlapping,
                        tooltip: l10n.journalTitle,
                        onTap: _openJournal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DO OR NOT',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          letterSpacing: 6,
                          color: AppColors.gold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.homeTagline, style: const TextStyle(color: Colors.white38)),
                  const SizedBox(height: 40),
                  _StyleSelector(
                    current: _style,
                    onChanged: _isDeciding || _pawSlapping ? null : _switchStyle,
                    coinKey: _coinStyleKey,
                    cardsKey: _cardsStyleKey,
                    dimUnselected: _pawSlapping,
                  ),
                  Expanded(
                    key: _patrolAreaKey,
                    child: const SizedBox.expand(),
                  ),
                  _DecideButton(
                    onPressed: _isDeciding || _pawSlapping ? null : _decide,
                    label: l10n.decideButton,
                    tapLabel: l10n.decideTap,
                  ),
                  const SizedBox(height: 24),
                  _MiniStatsBar(stats: _stats, onTap: _openStats),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_pawSlapping && _pawTargetRect != null)
            Positioned.fromRect(
              rect: _pawTargetRect!,
              child: PixelPawSlapOverlay(
                key: ValueKey('paw_${_style.name}_$_decisionRound'),
                onComplete: _pawSlapCompleter.complete,
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
                      choiceLocked: _isConfirming,
                      shakingChoice: _confirmingResponse,
                      confirmedChoice: _confirmedResponse,
                      isMarked: _isMarked,
                      onMarkToggle: _onMarkToggle,
                    )
                  : CardRevealAnimation(
                      key: ValueKey(_decisionRound),
                      decision: _pendingDecision!,
                      onRevealed: _onRevealed,
                      onChoice: _onChoice,
                      choiceLocked: _isConfirming,
                      shakingChoice: _confirmingResponse,
                      confirmedChoice: _confirmedResponse,
                      isMarked: _isMarked,
                      onMarkToggle: _onMarkToggle,
                    ),
            ),
          if (_isDeciding && _confirmedResponse != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _exitReveal,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AsyncGate {
  Completer<void>? _completer;

  Future<void> wait() {
    _completer = Completer<void>();
    return _completer!.future;
  }

  void complete() {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete();
    }
    _completer = null;
  }
}

class _StyleSelector extends StatelessWidget {
  const _StyleSelector({
    required this.current,
    required this.onChanged,
    required this.coinKey,
    required this.cardsKey,
    this.dimUnselected = false,
  });

  final RevealStyle current;
  final void Function(RevealStyle)? onChanged;
  final GlobalKey coinKey;
  final GlobalKey cardsKey;
  final bool dimUnselected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: RevealStyle.values.map((style) {
        final selected = style == current;
        final tileKey =
            style == RevealStyle.coin ? coinKey : cardsKey;
        final dimmed = dimUnselected && !selected;
        return Expanded(
          child: Padding(
            key: tileKey,
            padding: EdgeInsets.only(
              right: style == RevealStyle.coin ? 8 : 0,
              left: style == RevealStyle.cards ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(style),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: dimmed ? 0.35 : 1,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 120),
                  scale: dimUnselected && selected ? 0.94 : 1,
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
                        style.title(l10n),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : Colors.white54,
                        ),
                      ),
                      Text(
                        style.subtitle(l10n),
                        style: const TextStyle(fontSize: 11, color: Colors.white30),
                      ),
                    ],
                  ),
                ),
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
  const _DecideButton({
    required this.onPressed,
    required this.label,
    required this.tapLabel,
  });

  final VoidCallback? onPressed;
  final String label;
  final String tapLabel;

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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.tapLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white38,
                  letterSpacing: 4,
                ),
              ),
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
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(AppColors.doGreen, '${l10n.choiceComply} ${stats.complyCount}'),
              _separator,
              _dot(AppColors.notRed, '${l10n.choiceRebel} ${stats.rebelCount}'),
              _separator,
              _dot(AppColors.gold, '${l10n.choiceRetry} ${stats.retryPressCount}'),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  static const _separator = Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text('·', style: TextStyle(color: Colors.white24)),
  );

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
