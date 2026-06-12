import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/animation_style.dart';

extension RevealStyleL10n on RevealStyle {
  String title(AppLocalizations l10n) {
    switch (this) {
      case RevealStyle.coin:
        return l10n.styleCoinTitle;
      case RevealStyle.cards:
        return l10n.styleCardsTitle;
    }
  }

  String subtitle(AppLocalizations l10n) {
    switch (this) {
      case RevealStyle.coin:
        return l10n.styleCoinSubtitle;
      case RevealStyle.cards:
        return l10n.styleCardsSubtitle;
    }
  }
}
