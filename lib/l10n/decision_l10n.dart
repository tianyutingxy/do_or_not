import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/decision.dart';

extension DecisionL10n on Decision {
  String subtitle(AppLocalizations l10n) {
    return isDo ? l10n.decisionDoSubtitle : l10n.decisionNotSubtitle;
  }
}
