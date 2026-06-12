import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user_stats.dart';

extension UserStatsL10n on UserStats {
  String doNotLabel(AppLocalizations l10n) {
    if (total == 0) return l10n.statsNoFinalChoice;
    if (doPercent >= 70) return l10n.statsUsuallyDo;
    if (doPercent >= 55) return l10n.statsLeanDo;
    if (doPercent >= 45) return l10n.statsBalanced;
    if (doPercent >= 30) return l10n.statsLeanNot;
    return l10n.statsUsuallyNot;
  }

  String attitudeLabel(AppLocalizations l10n) {
    if (finalizedCount == 0) return '';

    final complyRatio = complyCount / finalizedCount;
    final rebelRatio = rebelCount / finalizedCount;
    final avg = avgRetriesBeforeFinal;

    final String stance;
    if (complyRatio >= 0.6) {
      stance = l10n.personalityFateFollower;
    } else if (rebelRatio >= 0.6) {
      stance = l10n.personalityBornRebel;
    } else if ((complyRatio - rebelRatio).abs() <= 0.15) {
      stance = l10n.personalityGoWithFlow;
    } else if (complyRatio > rebelRatio) {
      stance = l10n.personalityMostlyCompliant;
    } else {
      stance = l10n.personalityMostlyRebellious;
    }

    final String hesitation;
    if (avg >= 2.5) {
      hesitation = l10n.hesitationManyRetries;
    } else if (avg >= 1.2) {
      hesitation = l10n.hesitationSometimes;
    } else if (avg >= 0.4) {
      hesitation = l10n.hesitationRarely;
    } else {
      hesitation = l10n.hesitationAlmostNever;
    }

    return '$stance$hesitation';
  }

  String personalityLabel(AppLocalizations l10n) {
    if (finalizedCount == 0) return l10n.statsNoRecords;
    return attitudeLabel(l10n);
  }
}
