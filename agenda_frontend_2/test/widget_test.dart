import 'package:agenda_frontend/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    // Verifica che l'app si avvii correttamente
    expect(find.byType(App), findsOneWidget);
  });
}
