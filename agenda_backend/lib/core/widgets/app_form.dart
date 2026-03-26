import 'dart:math' as math;

import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/widgets/app_dividers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppFormPresentation { dialog, bottomSheet }

class AppForm {
  AppForm._();

  static const double defaultBottomSheetHeightFactor = 0.95;

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    EdgeInsetsGeometry? padding,
    double? heightFactor = defaultBottomSheetHeightFactor,
    double? maxHeightFactor,
    AppFormFactor? formFactor,
  }) {
    final effectiveFormFactor =
        formFactor ??
        ProviderScope.containerOf(
          context,
          listen: false,
        ).read(formFactorProvider);

    if (effectiveFormFactor == AppFormFactor.desktop) {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        useRootNavigator: useRootNavigator,
        builder: builder,
      );
    }

    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.white,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AppBottomSheetFormContainer(
        padding: effectivePadding,
        heightFactor: heightFactor,
        maxHeightFactor: maxHeightFactor,
        child: builder(ctx),
      ),
    );
  }
}

class AppBottomSheetFormContainer extends StatelessWidget {
  const AppBottomSheetFormContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.showHandle = true,
    this.heightFactor,
    this.maxHeightFactor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showHandle;
  final double? heightFactor;
  final double? maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    Widget content;

    if (heightFactor != null) {
      final resolved = padding.resolve(Directionality.of(context));
      final effectivePadding = resolved.copyWith(
        bottom: math.max(resolved.bottom, 50.0),
      );
      final screenHeight = MediaQuery.of(context).size.height;
      final height = screenHeight * heightFactor!;
      content = SizedBox(
        height: height,
        child: Padding(padding: effectivePadding, child: child),
      );
    } else {
      final paddedChild = Padding(padding: padding, child: child);
      if (maxHeightFactor != null) {
        final screenHeight = MediaQuery.of(context).size.height;
        content = ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * maxHeightFactor!,
          ),
          child: paddedChild,
        );
      } else {
        content = paddedChild;
      }
    }

    final body = showHandle
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(fit: FlexFit.loose, child: content),
            ],
          )
        : content;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: body,
    );
  }
}

class AppFormScaffold extends StatelessWidget {
  const AppFormScaffold({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.isLoading = false,
    this.presentation,
    this.dialogMinWidth = 600,
    this.dialogMaxWidth = 720,
    this.dialogInsetPadding = const EdgeInsets.symmetric(
      horizontal: 32,
      vertical: 24,
    ),
    this.dialogPadding = const EdgeInsets.all(20),
    this.mobileContentPadding = const EdgeInsets.fromLTRB(16, 12, 16, 0),
    this.mobileActionsPadding = const EdgeInsets.fromLTRB(16, 12, 16, 0),
    this.mobileBottomSpacing = 0,
    this.barrierDismissible = true,
    this.mobileExpandToAvailableHeight = false,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final bool isLoading;
  final AppFormPresentation? presentation;
  final double dialogMinWidth;
  final double dialogMaxWidth;
  final EdgeInsets dialogInsetPadding;
  final EdgeInsets dialogPadding;
  final EdgeInsets mobileContentPadding;
  final EdgeInsets mobileActionsPadding;
  final double mobileBottomSpacing;
  final bool barrierDismissible;
  final bool mobileExpandToAvailableHeight;

  bool _resolveDesktop(BuildContext context) {
    if (presentation != null) {
      return presentation == AppFormPresentation.dialog;
    }
    final formFactor = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(formFactorProvider);
    return formFactor == AppFormFactor.desktop;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = _resolveDesktop(context);
    final theme = Theme.of(context);

    if (isDesktop) {
      return DismissibleDialog(
        barrierDismissible: barrierDismissible,
        child: Dialog(
          insetPadding: dialogInsetPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: dialogMinWidth,
              maxWidth: dialogMaxWidth,
            ),
            child: _AppFormBody(
              isLoading: isLoading,
              child: Padding(
                padding: dialogPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DefaultTextStyle(
                      style:
                          theme.textTheme.headlineSmall ??
                          const TextStyle(fontSize: 24),
                      child: title,
                    ),
                    const SizedBox(height: 16),
                    Flexible(child: SingleChildScrollView(child: content)),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 12,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentSection = SingleChildScrollView(
            child: Padding(
              padding: mobileContentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle(
                    style:
                        theme.textTheme.titleLarge ??
                        const TextStyle(fontSize: 22),
                    child: title,
                  ),
                  const SizedBox(height: 12),
                  content,
                  SizedBox(height: mobileBottomSpacing),
                ],
              ),
            ),
          );

          Widget mobileBody;
          if (mobileExpandToAvailableHeight) {
            mobileBody = SizedBox(
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: contentSection),
                  if (actions.isNotEmpty && !isKeyboardOpen) ...[
                    const AppDivider(height: 1),
                    Padding(
                      padding: mobileActionsPadding,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 12,
                          children: actions,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
                ],
              ),
            );
          } else {
            final maxHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.of(context).size.height * 0.9;
            mobileBody = ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(fit: FlexFit.loose, child: contentSection),
                  if (actions.isNotEmpty && !isKeyboardOpen) ...[
                    const AppDivider(height: 1),
                    Padding(
                      padding: mobileActionsPadding,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 12,
                          children: actions,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
                ],
              ),
            );
          }

          return _AppFormBody(isLoading: isLoading, child: mobileBody);
        },
      ),
    );
  }
}

class _AppFormBody extends StatelessWidget {
  const _AppFormBody({required this.child, required this.isLoading});

  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }

    return Stack(
      children: [
        AbsorbPointer(child: child),
        const Positioned.fill(
          child: ColoredBox(
            color: Color(0x66000000),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}

class DismissibleDialog extends StatelessWidget {
  const DismissibleDialog({
    super.key,
    required this.child,
    this.barrierDismissible = true,
  });

  final Widget child;
  final bool barrierDismissible;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.escape): () {
          if (barrierDismissible) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
