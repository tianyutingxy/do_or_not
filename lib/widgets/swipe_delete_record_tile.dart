import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../theme/app_theme.dart';

/// 左滑露出删除按钮；点击删除后二次确认。
class SwipeDeleteRecordTile extends StatefulWidget {
  const SwipeDeleteRecordTile({
    super.key,
    required this.child,
    required this.onDeleteConfirmed,
  });

  final Widget child;
  final Future<void> Function() onDeleteConfirmed;

  @override
  State<SwipeDeleteRecordTile> createState() => _SwipeDeleteRecordTileState();
}

class _SwipeDeleteRecordTileState extends State<SwipeDeleteRecordTile> {
  static const _deleteWidth = 76.0;

  double _offset = 0;

  void _snapOpen() => setState(() => _offset = -_deleteWidth);

  void _snapClosed() => setState(() => _offset = 0);

  Future<void> _handleDeleteTap() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.journalDeleteConfirmTitle),
        content: Text(l10n.journalDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.notRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.journalDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _snapClosed();
    await widget.onDeleteConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.background,
              child: Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: AppColors.notRed,
                  child: InkWell(
                    onTap: _handleDeleteTap,
                    child: SizedBox(
                      width: _deleteWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          const SizedBox(height: 4),
                          Text(
                            l10n.journalDelete,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _offset = (_offset + details.delta.dx).clamp(-_deleteWidth, 0);
              });
            },
            onHorizontalDragEnd: (_) {
              if (_offset < -_deleteWidth / 2) {
                _snapOpen();
              } else {
                _snapClosed();
              }
            },
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
