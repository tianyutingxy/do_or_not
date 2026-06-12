import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/record_photo_paths.dart';
import '../theme/app_theme.dart';

class JournalPhotoSlots extends StatelessWidget {
  const JournalPhotoSlots({
    super.key,
    required this.photoPaths,
    required this.onPickSlot,
  });

  final List<String?> photoPaths;
  final ValueChanged<int> onPickSlot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paths = RecordPhotoPaths.normalize(photoPaths);

    return Row(
      children: List.generate(RecordPhotoPaths.slotCount, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < RecordPhotoPaths.slotCount - 1 ? 8 : 0,
            ),
            child: _PhotoSlotCard(
              path: paths[index],
              hint: l10n.journalPhotoAddHint,
              onTap: () => onPickSlot(index),
            ),
          ),
        );
      }),
    );
  }
}

class _PhotoSlotCard extends StatelessWidget {
  const _PhotoSlotCard({
    required this.path,
    required this.hint,
    required this.onTap,
  });

  final String? path;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = path != null && File(path!).existsSync();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasPhoto
                  ? AppColors.gold.withValues(alpha: 0.35)
                  : Colors.white12,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: hasPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(path!),
                        fit: BoxFit.cover,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Icon(
                          Icons.photo_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 24,
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.28),
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
