import 'package:agenda_backend/core/widgets/app_form.dart';
import 'package:flutter/material.dart';

/// Legacy wrapper kept for backward compatibility.
class AppBottomSheet {
  AppBottomSheet._();

  static const double defaultHeightFactor =
      AppForm.defaultBottomSheetHeightFactor;

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    EdgeInsetsGeometry? padding,
    double? heightFactor = defaultHeightFactor,
  }) {
    return AppForm.show<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      padding: padding,
      heightFactor: heightFactor,
    );
  }
}

typedef AppBottomSheetContainer = AppBottomSheetFormContainer;
