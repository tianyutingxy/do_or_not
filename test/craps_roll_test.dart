import 'package:do_or_not/models/craps_roll.dart';
import 'package:do_or_not/models/decision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CrapsRoll natural totals are 7 or 11', () {
    for (var i = 0; i < 50; i++) {
      final roll = CrapsRoll.randomFor(Decision.doIt);
      expect(roll.isNatural, isTrue);
      expect(roll.total, isIn([7, 11]));
      expect(roll.die1 + roll.die2, roll.total);
    }
  });

  test('CrapsRoll craps totals are 2, 3, or 12', () {
    for (var i = 0; i < 50; i++) {
      final roll = CrapsRoll.randomFor(Decision.notIt);
      expect(roll.isNatural, isFalse);
      expect(roll.total, isIn([2, 3, 12]));
      expect(roll.die1 + roll.die2, roll.total);
    }
  });
}
