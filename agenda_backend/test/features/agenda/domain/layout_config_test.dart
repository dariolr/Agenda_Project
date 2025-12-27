import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/features/agenda/domain/config/layout_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayoutConfig', () {
    test('computes total slots and height consistently', () {
      final config = LayoutConfig.initial;

      expect(config.totalSlots, 96); // 24h * 60 / 15
      expect(config.totalHeight, config.totalSlots * config.slotHeight);
    });

    test('computeMaxVisibleStaff adapts to width and form factor', () {
      final config = LayoutConfig.initial;

      final mobileResult = config.computeMaxVisibleStaff(
        500,
        formFactor: AppFormFactor.mobile,
      );
      final desktopResult = config.computeMaxVisibleStaff(
        1600,
        formFactor: AppFormFactor.desktop,
      );

      expect(mobileResult, 3); // 500 / 140 = 3.57 -> floor = 3
      expect(desktopResult, LayoutConfig.maxVisibleStaff);
    });

    test(
      'computeAdaptiveColumnWidth enforces minimum width per form factor',
      () {
        final config = LayoutConfig.initial;

        final narrowMobile = config.computeAdaptiveColumnWidth(
          contentWidth: 420,
          visibleStaffCount: 3,
          formFactor: AppFormFactor.mobile,
        );

        final spaciousDesktop = config.computeAdaptiveColumnWidth(
          contentWidth: 1920,
          visibleStaffCount: 4,
          formFactor: AppFormFactor.desktop,
        );

        expect(narrowMobile, LayoutConfig.minColumnWidthMobile);
        expect(spaciousDesktop, closeTo(1920 / 4, 0.0001));
      },
    );

    test('headerHeightForWidth returns responsive breakpoints', () {
      expect(LayoutConfig.headerHeightForWidth(500), 80); // Mobile
      expect(LayoutConfig.headerHeightForWidth(800), 95); // Tablet
      expect(LayoutConfig.headerHeightForWidth(1300), 110); // Desktop
    });

    test('validates allowed slot durations', () {
      expect(LayoutConfig.isValidSlotDuration(15), isTrue);
      expect(LayoutConfig.isValidSlotDuration(45), isFalse);
    });
  });
}
