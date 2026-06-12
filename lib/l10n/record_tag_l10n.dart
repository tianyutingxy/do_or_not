import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/record_tags.dart';

extension RecordTagL10n on String {
  String tagLabel(AppLocalizations l10n) {
    return switch (this) {
      RecordTags.work => l10n.journalTagWork,
      RecordTags.relationship => l10n.journalTagRelationship,
      RecordTags.spending => l10n.journalTagSpending,
      RecordTags.health => l10n.journalTagHealth,
      RecordTags.life => l10n.journalTagLife,
      RecordTags.other => l10n.journalTagOther,
      _ => this,
    };
  }
}
