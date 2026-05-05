import 'package:agenda_backend/core/l10n/l10n.dart';
import 'package:agenda_backend/core/models/service_package.dart';
import 'package:agenda_backend/features/services/presentation/widgets/service_package_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('package status chips follow package state only', (tester) async {
    await tester.pumpWidget(
      _harness(
        const Column(
          children: [
            ServicePackageListItem(
              package: _publicPackage,
              isLast: false,
              isEvenRow: false,
              isWide: true,
              colorScheme: _colorScheme,
              onTap: _noop,
              onEdit: _noop,
              onCopyDirectLink: _noop,
              onDelete: _noop,
              readOnly: true,
            ),
            ServicePackageListItem(
              package: _directLinkPackage,
              isLast: false,
              isEvenRow: false,
              isWide: true,
              colorScheme: _colorScheme,
              onTap: _noop,
              onEdit: _noop,
              onCopyDirectLink: _noop,
              onDelete: _noop,
              readOnly: true,
            ),
            ServicePackageListItem(
              package: _hiddenPackage,
              isLast: false,
              isEvenRow: false,
              isWide: true,
              colorScheme: _colorScheme,
              onTap: _noop,
              onEdit: _noop,
              onCopyDirectLink: _noop,
              onDelete: _noop,
              readOnly: true,
            ),
            ServicePackageListItem(
              package: _brokenPackage,
              isLast: true,
              isEvenRow: false,
              isWide: true,
              colorScheme: _colorScheme,
              onTap: _noop,
              onEdit: _noop,
              onCopyDirectLink: _noop,
              onDelete: _noop,
              readOnly: true,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Public package'), findsOneWidget);
    expect(find.text('Direct package'), findsOneWidget);
    expect(find.text('Hidden package'), findsOneWidget);
    expect(find.text('Broken package'), findsOneWidget);
    expect(find.text('Solo tramite link diretto'), findsOneWidget);
    expect(find.text('Non prenotabile online'), findsOneWidget);
    expect(find.text('Non valido'), findsOneWidget);
  });
}

Widget _harness(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(useMaterial3: false, splashFactory: NoSplash.splashFactory),
      locale: const Locale('it'),
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.delegate.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void _noop() {}

const _colorScheme = ColorScheme.light();

const _packageItems = [
  ServicePackageItem(serviceId: 1, sortOrder: 0),
];

const _publicPackage = ServicePackage(
  id: 1,
  businessId: 1,
  locationId: 1,
  categoryId: 1,
  sortOrder: 0,
  name: 'Public package',
  onlineVisibility: 'public',
  effectivePrice: 20,
  effectiveDurationMinutes: 30,
  items: _packageItems,
);

const _directLinkPackage = ServicePackage(
  id: 2,
  businessId: 1,
  locationId: 1,
  categoryId: 1,
  sortOrder: 0,
  name: 'Direct package',
  onlineVisibility: 'direct_link',
  effectivePrice: 20,
  effectiveDurationMinutes: 30,
  items: _packageItems,
);

const _hiddenPackage = ServicePackage(
  id: 3,
  businessId: 1,
  locationId: 1,
  categoryId: 1,
  sortOrder: 0,
  name: 'Hidden package',
  isBookableOnline: false,
  onlineVisibility: 'hidden',
  effectivePrice: 20,
  effectiveDurationMinutes: 30,
  items: _packageItems,
);

const _brokenPackage = ServicePackage(
  id: 4,
  businessId: 1,
  locationId: 1,
  categoryId: 1,
  sortOrder: 0,
  name: 'Broken package',
  isBroken: true,
  onlineVisibility: 'public',
  effectivePrice: 20,
  effectiveDurationMinutes: 30,
  items: _packageItems,
);
