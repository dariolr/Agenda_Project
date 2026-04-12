import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils/app_form_smoke_harness.dart';

void main() {
  testWidgets(
    'AppForm mobile injects required Material ancestry for form controls',
    (tester) async {
      await expectAppFormOpensWithoutFrameworkErrors(
        tester,
        formFactor: AppFormFactor.mobile,
        bodyBuilder: (context) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Create form'),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Email')),
            ],
          );
        },
      );

      expect(find.text('Create form'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets(
    'AppForm tablet injects required Material ancestry for form controls',
    (tester) async {
      await expectAppFormOpensWithoutFrameworkErrors(
        tester,
        formFactor: AppFormFactor.tablet,
        bodyBuilder: (context) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Create form'),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Email')),
            ],
          );
        },
      );

      expect(find.text('Create form'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
