import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/features/agenda/domain/config/layout_config.dart';
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

      final mobileResult =
          config.computeMaxVisibleStaff(500, formFactor: AppFormFactor.mobile);
      final desktopResult = config.computeMaxVisibleStaff(
        1600,
        formFactor: AppFormFactor.tabletOrDesktop,
      );

      expect(mobileResult, 3); // (500 - 60) / 140 = 3.14 -> floor = 3
      expect(desktopResult, LayoutConfig.maxVisibleStaff);
    });

    test('computeAdaptiveColumnWidth enforces minimum width per form factor',
        () {
      final config = LayoutConfig.initial;

      final narrowMobile = config.computeAdaptiveColumnWidth(
        screenWidth: 420,
        visibleStaffCount: 3,
        formFactor: AppFormFactor.mobile,
      );

      final spaciousDesktop = config.computeAdaptiveColumnWidth(
        screenWidth: 1920,
        visibleStaffCount: 4,
        formFactor: AppFormFactor.tabletOrDesktop,
      );

      expect(narrowMobile, LayoutConfig.minColumnWidthMobile);
      expect(spaciousDesktop,
          closeTo((1920 - config.hourColumnWidth) / 4, 0.0001));
    });

    test('headerHeightForWidth returns responsive breakpoints', () {
      expect(LayoutConfig.headerHeightForWidth(500), 48);
      expect(LayoutConfig.headerHeightForWidth(800), 52);
      expect(LayoutConfig.headerHeightForWidth(1300), 56);
    });

    test('validates allowed slot durations', () {
      expect(LayoutConfig.isValidSlotDuration(15), isTrue);
      expect(LayoutConfig.isValidSlotDuration(45), isFalse);
    });
  });
}
