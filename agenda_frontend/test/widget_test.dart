import 'package:agenda_frontend/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Test semplificato - verifica solo che l'app si costruisca
    // I provider fanno chiamate API reali ma il test termina prima
    await tester.pumpWidget(const App());

    // Attende che il primo frame sia renderizzato
    await tester.pump();

    // Verifica che l'app si avvii correttamente
    expect(find.byType(App), findsOneWidget);
  });
}
