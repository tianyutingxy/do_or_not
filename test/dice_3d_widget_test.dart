import 'package:do_or_not/widgets/dice_3d_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dice3DWidget builds without exception', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Dice3DWidget(
            size: 88,
            rotationX: -0.82,
            rotationY: 0.1,
            rotationZ: 0.3,
            highlight: true,
            highlightStrength: 0.8,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
