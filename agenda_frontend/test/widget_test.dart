import 'package:agenda_frontend/app/app.dart';
import 'package:agenda_frontend/features/booking/providers/booking_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Mocka i provider che fanno API calls per evitare timer pendenti
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async => []),
          servicesProvider.overrideWith((ref) async => []),
          staffProvider.overrideWith((ref) async => []),
        ],
        child: const App(),
      ),
    );

    // Attende che il primo frame sia renderizzato
    await tester.pump();

    // Verifica che l'app si avvii correttamente
    expect(find.byType(App), findsOneWidget);
  });
}
