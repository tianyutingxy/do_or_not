import 'dart:math';

import 'package:do_or_not/widgets/pixel_cat/cat_patrol_routine.dart';
import 'package:do_or_not/widgets/pixel_cat/cat_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routine generator produces varied beats', () {
    final gen = CatPatrolRoutineGenerator();
    final a = gen.generate(Random(1));
    final b = gen.generate(Random(2));

    expect(a.beats.length, greaterThanOrEqualTo(5));
    expect(a.beats.any((e) => e.action.moves), isTrue);
    expect(a.beats.any((e) => !e.action.moves), isTrue);
    expect(
      a.beats.map((e) => e.action).toList(),
      isNot(equals(b.beats.map((e) => e.action).toList())),
    );
  });

  test('no consecutive too-similar actions in generated routine', () {
    final gen = CatPatrolRoutineGenerator();
    for (var seed = 0; seed < 30; seed++) {
      final routine = gen.generate(Random(seed), beatCount: 10);
      final actions = routine.beats.map((b) => b.action).toList();
      for (var i = 1; i < actions.length; i++) {
        expect(
          actions[i - 1].isTooSimilar(actions[i]),
          isFalse,
          reason: 'seed $seed: ${actions[i - 1]} -> ${actions[i]}',
        );
      }
    }
  });

  test('lying posture never follows lying posture', () {
    final gen = CatPatrolRoutineGenerator();
    for (var seed = 0; seed < 50; seed++) {
      final routine = gen.generate(Random(seed), beatCount: 12);
      final actions = routine.beats.map((b) => b.action).toList();
      for (var i = 1; i < actions.length; i++) {
        if (actions[i - 1].posture == CatPosture.lying) {
          expect(
            actions[i].posture,
            isNot(CatPosture.lying),
            reason: 'seed $seed: ${actions[i - 1]} -> ${actions[i]}',
          );
        }
      }
    }
  });

  test('generated routine favors walk and lying over grooming', () {
    final gen = CatPatrolRoutineGenerator();
    var walkOrLie = 0;
    var groom = 0;
    for (var seed = 0; seed < 40; seed++) {
      final routine = gen.generate(Random(seed), beatCount: 10);
      for (final beat in routine.beats) {
        final p = beat.action.posture;
        if (p == CatPosture.move || p == CatPosture.lying) walkOrLie++;
        if (p == CatPosture.groom) groom++;
      }
    }
    expect(walkOrLie, greaterThan(groom * 3));
  });

  test('laying plays once style has hold on last frame', () {
    expect(CatAction.laying.animStyle, CatAnimStyle.playOnceHoldLast);
    expect(CatAction.laying.loopCycles, 1);
    expect(CatAction.laying.frameCount, 8);
    expect(
      CatAction.laying.holdDuration.inMilliseconds,
      greaterThan(CatAction.laying.msPerFrame * 8),
    );
  });

  test('sprite frame counts match sheet width', () {
    expect(CatAction.walk.frameCount, 8);
    expect(CatAction.meow.frameCount, 4);
    expect(CatAction.stretching.frameCount, 13);
    expect(CatAction.itch.frameCount, 2);
  });
}
