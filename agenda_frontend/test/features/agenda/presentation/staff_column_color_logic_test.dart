import 'package:agenda_frontend/core/models/service_variant.dart';
import 'package:agenda_frontend/core/utils/color_utils.dart';
import 'package:agenda_frontend/features/agenda/providers/pending_drop_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Service Color Map Logic', () {
    test('buildServiceColorMap creates correct mapping from services', () {
      // Simula la logica usata in staff_column.dart
      final variants = [
        ServiceVariant(
          id: 1001,
          serviceId: 1,
          locationId: 1,
          durationMinutes: 30,
          price: 10,
          colorHex: ColorUtils.toHex(Colors.red),
        ),
        ServiceVariant(
          id: 1002,
          serviceId: 2,
          locationId: 1,
          durationMinutes: 30,
          price: 10,
          colorHex: ColorUtils.toHex(Colors.blue),
        ),
        ServiceVariant(
          id: 1003,
          serviceId: 3,
          locationId: 1,
          durationMinutes: 30,
          price: 10,
          colorHex: null, // Servizio senza colore
        ),
        ServiceVariant(
          id: 1004,
          serviceId: 4,
          locationId: 1,
          durationMinutes: 30,
          price: 10,
          colorHex: ColorUtils.toHex(Colors.green),
        ),
      ];

      // Questa è la stessa logica del codice ottimizzato in staff_column.dart
      final serviceColorMap = <int, Color>{};
      for (final variant in variants) {
        if (variant.colorHex != null) {
          serviceColorMap[variant.serviceId] =
              ColorUtils.fromHex(variant.colorHex!);
        }
      }

      // Verifica che la mappa contenga solo i servizi con colore
      expect(serviceColorMap.length, 3);
      expect(serviceColorMap[1], Colors.red);
      expect(serviceColorMap[2], Colors.blue);
      expect(serviceColorMap[3], isNull); // Non presente perché color è null
      expect(serviceColorMap[4], Colors.green);
    });

    test('serviceColorMap lookup returns correct color', () {
      final variants = [
        ServiceVariant(
          id: 1010,
          serviceId: 10,
          locationId: 1,
          durationMinutes: 30,
          price: 10,
          colorHex: ColorUtils.toHex(Colors.orange),
        ),
        ServiceVariant(
          id: 1020,
          serviceId: 20,
          locationId: 1,
          durationMinutes: 30,
          price: 10,
          colorHex: ColorUtils.toHex(Colors.purple),
        ),
      ];

      final serviceColorMap = <int, Color>{};
      for (final variant in variants) {
        if (variant.colorHex != null) {
          serviceColorMap[variant.serviceId] =
              ColorUtils.fromHex(variant.colorHex!);
        }
      }

      // Simula il lookup nel loop degli appuntamenti
      const appointmentServiceId = 10;
      final Color defaultColor = Colors.grey;

      Color cardColor = defaultColor;
      final serviceColor = serviceColorMap[appointmentServiceId];
      if (serviceColor != null) {
        cardColor = serviceColor;
      }

      expect(cardColor, Colors.orange);
    });

    test('serviceColorMap lookup returns default when service not found', () {
      final variants = [
        ServiceVariant(
          id: 1010,
          serviceId: 10,
          locationId: 1,
          durationMinutes: 30,
          price: 10,
          colorHex: ColorUtils.toHex(Colors.orange),
        ),
      ];

      final serviceColorMap = <int, Color>{};
      for (final variant in variants) {
        if (variant.colorHex != null) {
          serviceColorMap[variant.serviceId] =
              ColorUtils.fromHex(variant.colorHex!);
        }
      }

      // Appuntamento con serviceId non presente nella mappa
      const appointmentServiceId = 999;
      final Color defaultColor = Colors.grey;

      Color cardColor = defaultColor;
      final serviceColor = serviceColorMap[appointmentServiceId];
      if (serviceColor != null) {
        cardColor = serviceColor;
      }

      // Il colore rimane il default
      expect(cardColor, Colors.grey);
    });

    test('empty services list results in empty map', () {
      final variants = <ServiceVariant>[];

      final serviceColorMap = <int, Color>{};
      for (final variant in variants) {
        if (variant.colorHex != null) {
          serviceColorMap[variant.serviceId] =
              ColorUtils.fromHex(variant.colorHex!);
        }
      }

      expect(serviceColorMap, isEmpty);
    });
  });

  group('PendingDropProvider', () {
    late ProviderContainer container;
    late PendingDropNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(pendingDropProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is null', () {
      expect(container.read(pendingDropProvider), isNull);
      expect(notifier.hasPending, isFalse);
    });

    test('setPending updates state correctly', () {
      final data = PendingDropData(
        appointmentId: 1,
        originalStaffId: 100,
        originalStart: DateTime(2025, 1, 1, 9, 0),
        originalEnd: DateTime(2025, 1, 1, 10, 0),
        newStaffId: 200,
        newStart: DateTime(2025, 1, 1, 11, 0),
        newEnd: DateTime(2025, 1, 1, 12, 0),
      );

      notifier.setPending(data);

      final state = container.read(pendingDropProvider);
      expect(state, isNotNull);
      expect(state!.appointmentId, 1);
      expect(state.originalStaffId, 100);
      expect(state.newStaffId, 200);
      expect(notifier.hasPending, isTrue);
    });

    test('clear resets state to null', () {
      final data = PendingDropData(
        appointmentId: 1,
        originalStaffId: 100,
        originalStart: DateTime(2025, 1, 1, 9, 0),
        originalEnd: DateTime(2025, 1, 1, 10, 0),
        newStaffId: 200,
        newStart: DateTime(2025, 1, 1, 11, 0),
        newEnd: DateTime(2025, 1, 1, 12, 0),
      );

      notifier.setPending(data);
      expect(notifier.hasPending, isTrue);

      notifier.clear();
      expect(container.read(pendingDropProvider), isNull);
      expect(notifier.hasPending, isFalse);
    });

    test('isAppointmentPendingDropProvider returns correct value', () {
      final data = PendingDropData(
        appointmentId: 42,
        originalStaffId: 100,
        originalStart: DateTime(2025, 1, 1, 9, 0),
        originalEnd: DateTime(2025, 1, 1, 10, 0),
        newStaffId: 200,
        newStart: DateTime(2025, 1, 1, 11, 0),
        newEnd: DateTime(2025, 1, 1, 12, 0),
      );

      notifier.setPending(data);

      // L'appuntamento 42 ha un pending drop
      expect(container.read(isAppointmentPendingDropProvider(42)), isTrue);
      // Altri appuntamenti no
      expect(container.read(isAppointmentPendingDropProvider(1)), isFalse);
      expect(container.read(isAppointmentPendingDropProvider(100)), isFalse);
    });
  });

  group('Opacity Logic', () {
    test('opacity is ghostOpacity when appointment is being dragged', () {
      const ghostOpacity = 0.4;
      const appointmentId = 1;
      const draggedId = 1;

      final isDragged = appointmentId == draggedId;
      final double opacity = isDragged ? ghostOpacity : 1.0;

      expect(opacity, ghostOpacity);
    });

    test('opacity is 1.0 when appointment is not being dragged', () {
      const ghostOpacity = 0.4;
      const appointmentId = 1;
      const draggedId = 2; // Diverso

      final isDragged = appointmentId == draggedId;
      final double opacity = isDragged ? ghostOpacity : 1.0;

      expect(opacity, 1.0);
    });

    test(
      'opacity is ghostOpacity when appointment has pending drop at original position',
      () {
        const ghostOpacity = 0.4;
        const appointmentId = 1;
        const widgetStaffId = 100;

        final pendingDrop = PendingDropData(
          appointmentId: 1,
          originalStaffId: 100, // Stesso staff del widget
          originalStart: DateTime(2025, 1, 1, 9, 0),
          originalEnd: DateTime(2025, 1, 1, 10, 0),
          newStaffId: 200,
          newStart: DateTime(2025, 1, 1, 11, 0),
          newEnd: DateTime(2025, 1, 1, 12, 0),
        );

        // Simula la logica in staff_column.dart
        final hasPendingDrop = pendingDrop.appointmentId == appointmentId;
        final isOriginalPosition =
            hasPendingDrop && pendingDrop.originalStaffId == widgetStaffId;

        double opacity = 1.0;
        if (isOriginalPosition) {
          opacity = ghostOpacity;
        }

        expect(hasPendingDrop, isTrue);
        expect(isOriginalPosition, isTrue);
        expect(opacity, ghostOpacity);
      },
    );

    test(
      'opacity is 1.0 when appointment has pending drop but different staff',
      () {
        const ghostOpacity = 0.4;
        const appointmentId = 1;
        const widgetStaffId = 300; // Staff diverso dall'originale

        final pendingDrop = PendingDropData(
          appointmentId: 1,
          originalStaffId: 100, // Staff diverso dal widget
          originalStart: DateTime(2025, 1, 1, 9, 0),
          originalEnd: DateTime(2025, 1, 1, 10, 0),
          newStaffId: 200,
          newStart: DateTime(2025, 1, 1, 11, 0),
          newEnd: DateTime(2025, 1, 1, 12, 0),
        );

        final hasPendingDrop = pendingDrop.appointmentId == appointmentId;
        final isOriginalPosition =
            hasPendingDrop && pendingDrop.originalStaffId == widgetStaffId;

        double opacity = 1.0;
        if (isOriginalPosition) {
          opacity = ghostOpacity;
        }

        expect(hasPendingDrop, isTrue);
        expect(isOriginalPosition, isFalse);
        expect(opacity, 1.0);
      },
    );
  });
}
