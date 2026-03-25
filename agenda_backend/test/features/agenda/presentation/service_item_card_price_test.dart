import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/l10n.dart';
import 'package:agenda_backend/core/models/service.dart';
import 'package:agenda_backend/core/models/service_category.dart';
import 'package:agenda_backend/core/models/service_variant.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/features/agenda/domain/service_item_data.dart';
import 'package:agenda_backend/features/agenda/presentation/widgets/service_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'price confirm stays open and does not update when validation rejects change',
    (tester) async {
      final updates = <ServiceItemData>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: false,
              splashFactory: NoSplash.splashFactory,
            ),
            locale: const Locale('it'),
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: L10n.delegate.supportedLocales,
            home: Scaffold(
              body: ServiceItemCard(
                item: const ServiceItemData(
                  key: '1',
                  serviceId: 1,
                  serviceVariantId: 10,
                  staffId: 5,
                  startTime: TimeOfDay(hour: 10, minute: 0),
                  durationMinutes: 30,
                  price: 20,
                ),
                index: 0,
                services: const [
                  Service(
                    id: 1,
                    businessId: 1,
                    categoryId: 1,
                    name: 'Taglio',
                  ),
                ],
                categories: const [
                  ServiceCategory(id: 1, businessId: 1, name: 'Cat'),
                ],
                variants: const [
                  ServiceVariant(
                    id: 10,
                    serviceId: 1,
                    locationId: 1,
                    durationMinutes: 30,
                    price: 30,
                  ),
                ],
                eligibleStaff: const [5],
                allStaff: const [
                  Staff(
                    id: 5,
                    businessId: 1,
                    name: 'Mario',
                    surname: 'Rossi',
                    color: Colors.blue,
                    locationIds: [1],
                  ),
                ],
                formFactor: AppFormFactor.desktop,
                onChanged: updates.add,
                onRemove: _noop,
                onStartTimeChanged: _noopTime,
                onEndTimeChanged: _noopTime,
                onDurationChanged: _noopInt,
                onPriceChangeConfirmed: (_) async => false,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('€ 20.00'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      final textField = find.byType(TextField).last;
      await tester.enterText(textField, '10');
      await tester.tap(find.text('Conferma'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(updates, isEmpty);
    },
  );
}

void _noop() {}
void _noopTime(TimeOfDay _) {}
void _noopInt(int _) {}
