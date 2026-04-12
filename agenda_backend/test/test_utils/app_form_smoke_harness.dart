import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/widgets/app_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef FormBodyBuilder = Widget Function(BuildContext context);

Future<void> expectAppFormOpensWithoutFrameworkErrors(
  WidgetTester tester, {
  required AppFormFactor formFactor,
  required FormBodyBuilder bodyBuilder,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  AppForm.show<void>(
                    context: context,
                    formFactor: formFactor,
                    builder: (ctx) => bodyBuilder(ctx),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
}
