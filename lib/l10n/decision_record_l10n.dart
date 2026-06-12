import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../models/decision.dart';
import '../models/decision_record.dart';
import '../models/user_response.dart';
import 'reveal_style_l10n.dart';

extension DecisionRecordL10n on DecisionRecord {
  String formattedDate(AppLocalizations l10n, String localeName) {
    return DateFormat.yMMMd(localeName).add_Hm().format(decidedAt);
  }

  String summaryLine(AppLocalizations l10n) {
    final responseLabel = userResponse == UserResponse.comply
        ? l10n.choiceComply
        : l10n.choiceRebel;
    return l10n.journalSummary(
      objectiveDecision.label,
      responseLabel,
      finalDecision.label,
    );
  }

  String styleLine(AppLocalizations l10n) {
    final style = revealStyle.title(l10n);
    if (retryCount == 0) return style;
    return l10n.journalStyleWithRetries(style, retryCount);
  }
}

extension UserResponseL10n on UserResponse {
  String label(AppLocalizations l10n) {
    return switch (this) {
      UserResponse.comply => l10n.choiceComply,
      UserResponse.rebel => l10n.choiceRebel,
      UserResponse.retry => l10n.choiceRetry,
    };
  }
}
