// Smoke test del dashboard de la demo.
//
// No afirma nada sobre el overflow: la demo alterna entre el estado roto (tag
// `demo-bug`) y el arreglado por el agente, y el test debe pasar en ambos. Por
// eso drena la excepción de layout con `takeException()` en vez de fallar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agentic_hot_reload_flutter_demo/main.dart';

void main() {
  testWidgets('el contador incrementa y sobrevive al rebuild', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DemoApp());
    // Descarta el RenderFlex overflow si el bug está presente.
    tester.takeException();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    tester.takeException();

    expect(find.text('1'), findsOneWidget);
  });
}
