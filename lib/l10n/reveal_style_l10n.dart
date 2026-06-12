import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/animation_style.dart';

extension RevealStyleL10n on RevealStyle {
  String title(AppLocalizations l10n) => switch (this) {
    RevealStyle.coin => l10n.styleCoinTitle,
    RevealStyle.cards => l10n.styleCardsTitle,
    RevealStyle.dice => l10n.styleDiceTitle,
  };

  String subtitle(AppLocalizations l10n) => switch (this) {
    RevealStyle.coin => l10n.styleCoinSubtitle,
    RevealStyle.cards => l10n.styleCardsSubtitle,
    RevealStyle.dice => l10n.styleDiceSubtitle,
  };
}
