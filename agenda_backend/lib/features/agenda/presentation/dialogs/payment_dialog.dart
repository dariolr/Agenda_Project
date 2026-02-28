import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';

/// Mostra il dialog di pagamento per distribuire il totale di una prenotazione
/// tra diversi metodi di pagamento.
Future<bool> showPaymentDialog(
  BuildContext context,
  WidgetRef ref, {
  required double totalPrice,
  required String currencyCode,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final isBottomSheet = formFactor != AppFormFactor.desktop;

  final content = _PaymentDialog(
    totalPrice: totalPrice,
    currencyCode: currencyCode,
    isBottomSheet: isBottomSheet,
  );

  if (!isBottomSheet) {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => content,
    );
    return result ?? false;
  } else {
    final result = await AppBottomSheet.show<bool>(
      context: context,
      useRootNavigator: true,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      builder: (_) => content,
      heightFactor: null,
    );
    return result ?? false;
  }
}

enum _PaymentMethod { cash, card, discount, voucher, other, previousCredit }

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({
    required this.totalPrice,
    required this.currencyCode,
    required this.isBottomSheet,
  });

  final double totalPrice;
  final String currencyCode;
  final bool isBottomSheet;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  static const String _paymentAmountLabel = 'Importo da pagare';

  static const List<double> _quickPercentages = <double>[
    10,
    20,
    30,
    50,
    100,
  ];

  final Map<_PaymentMethod, TextEditingController> _controllers = {
    for (final m in _PaymentMethod.values) m: TextEditingController(),
  };
  late final TextEditingController _totalPriceController;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers.values) {
      controller.text = _formatAmountValue(0);
    }
    _totalPriceController = TextEditingController(
      text: _formatAmountValue(widget.totalPrice),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _totalPriceController.dispose();
    super.dispose();
  }

  double get _currentTotalPrice {
    final parsed = PriceFormatter.parse(_totalPriceController.text);
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  double get _manualEnteredTotal {
    double total = 0;
    for (final controller in _controllers.values) {
      final value = PriceFormatter.parse(controller.text);
      if (value != null) total += value;
    }
    return total;
  }

  bool get _hasCustomerCredit => _manualEnteredTotal > _currentTotalPrice + 0.01;

  bool get _isValid => true;

  bool _supportsQuickChips(_PaymentMethod method) {
    return method == _PaymentMethod.cash ||
        method == _PaymentMethod.discount ||
        method == _PaymentMethod.card ||
        method == _PaymentMethod.voucher ||
        method == _PaymentMethod.other;
  }

  String _formatAmountValue(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatPercentValue(double value) {
    final normalized = _formatAmountValue(value);
    if (normalized.endsWith(',00')) {
      return normalized.substring(0, normalized.length - 3);
    }
    if (normalized.endsWith('0')) {
      return normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  double? _amountForMethod(_PaymentMethod method) {
    return PriceFormatter.parse(_controllers[method]!.text);
  }

  double? _selectedPercentForMethod(_PaymentMethod method) {
    if (!_supportsQuickChips(method) || _currentTotalPrice <= 0) return null;
    final amount = _amountForMethod(method);
    if (amount == null || amount <= 0) return null;
    return (amount / _currentTotalPrice) * 100;
  }

  bool _samePercent(double a, double b) => (a - b).abs() < 0.01;

  List<double> _chipPercentagesForMethod(_PaymentMethod method) {
    final options = List<double>.from(_quickPercentages);
    final current = _selectedPercentForMethod(method);
    if (current == null) return options;
    final hasMatch = options.any((value) => _samePercent(value, current));
    if (!hasMatch) {
      options.add(current);
      options.sort((a, b) => a.compareTo(b));
    }
    return options;
  }

  void _applyQuickPercentage(_PaymentMethod method, double percentage) {
    if (_currentTotalPrice <= 0) return;
    final amount = _currentTotalPrice * percentage / 100;
    _setControllerValue(_controllers[method]!, _formatAmountValue(amount));
  }

  void _setControllerValue(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _selectAll(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  void _normalizeNonNegativeAmount(
    TextEditingController controller,
    String rawValue,
  ) {
    final parsed = PriceFormatter.parse(rawValue);
    if (parsed != null && parsed < 0) {
      _setControllerValue(controller, '0,00');
    }
  }

  String _methodLabel(BuildContext context, _PaymentMethod method) {
    final l10n = context.l10n;
    switch (method) {
      case _PaymentMethod.cash:
        return l10n.paymentMethodCash;
      case _PaymentMethod.card:
        return l10n.paymentMethodCard;
      case _PaymentMethod.discount:
        return l10n.paymentMethodDiscount;
      case _PaymentMethod.voucher:
        return l10n.paymentMethodVoucher;
      case _PaymentMethod.previousCredit:
        return l10n.paymentMethodPreviousCredit;
      case _PaymentMethod.other:
        return l10n.paymentMethodOther;
    }
  }

  IconData _methodIcon(_PaymentMethod method) {
    switch (method) {
      case _PaymentMethod.cash:
        return Icons.payments_outlined;
      case _PaymentMethod.card:
        return Icons.credit_card_outlined;
      case _PaymentMethod.discount:
        return Icons.discount_outlined;
      case _PaymentMethod.voucher:
        return Icons.card_giftcard_outlined;
      case _PaymentMethod.previousCredit:
        return Icons.history_outlined;
      case _PaymentMethod.other:
        return Icons.more_horiz_outlined;
    }
  }

  Widget _buildQuickChips(BuildContext context, _PaymentMethod method) {
    final theme = Theme.of(context);
    final selectedPercent = _selectedPercentForMethod(method);
    final options = _chipPercentagesForMethod(method);

    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final percentage in options)
            Builder(
              builder: (context) {
                final isSelected = selectedPercent != null &&
                    _samePercent(selectedPercent, percentage);
                return ChoiceChip(
                  label: Text(
                    '${_formatPercentValue(percentage)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  showCheckmark: false,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.55),
                  selectedColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.18),
                  ),
                  visualDensity: VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 1,
                    vertical: 0,
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    _applyQuickPercentage(method, percentage);
                    setState(() {});
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAmountField(_PaymentMethod method) {
    return SizedBox(
      width: 92,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _selectAll(_controllers[method]!),
        child: TextField(
          controller: _controllers[method],
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[\d.,]'),
            ),
          ],
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: '0,00',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          onTap: () => _selectAll(_controllers[method]!),
          onChanged: (value) {
            _normalizeNonNegativeAmount(_controllers[method]!, value);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildTotalPriceField() {
    return SizedBox(
      width: 92,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _selectAll(_totalPriceController),
        child: TextField(
          controller: _totalPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: '0,00',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          onTap: () => _selectAll(_totalPriceController),
          onChanged: (value) {
            _normalizeNonNegativeAmount(_totalPriceController, value);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, TextStyle? titleStyle) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        height: 40,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _paymentAmountLabel,
                  style: titleStyle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildTotalPriceField(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final totalPrice = _currentTotalPrice;
    final totalEntered = _manualEnteredTotal;
    final remaining = totalPrice - totalEntered;
    final hasCustomerCredit = _hasCustomerCredit;
    final isValid = _isValid;
    final hasOutstandingAmount = remaining > 0.01;
    final settlementColor = hasOutstandingAmount
        ? Colors.red.shade700
        : Colors.green.shade700;

    String formatAmount(double amount) => PriceFormatter.format(
      context: context,
      amount: amount,
      currencyCode: widget.currencyCode,
    );

    final methodRows = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _PaymentMethod.values.length; i++)
          Padding(
            padding: EdgeInsets.zero,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: i.isEven
                    ? Color.alphaBlend(
                        theme.colorScheme.outlineVariant.withOpacity(0.02),
                        theme.colorScheme.surfaceContainerHighest.withOpacity(
                          0.1,
                        ),
                      )
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _methodIcon(_PaymentMethod.values[i]),
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _methodLabel(
                                    context,
                                    _PaymentMethod.values[i],
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                          if (_supportsQuickChips(_PaymentMethod.values[i]))
                            _buildQuickChips(
                              context,
                              _PaymentMethod.values[i],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildAmountField(_PaymentMethod.values[i]),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    final summary = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isValid
            ? theme.colorScheme.primaryContainer.withOpacity(0.08)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isValid
              ? theme.colorScheme.primary.withOpacity(0.14)
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _paymentAmountLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                formatAmount(totalPrice),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.paymentEntered,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                formatAmount(totalEntered),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Divider(
            height: 16,
            color: theme.colorScheme.outline.withOpacity(0.4),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasCustomerCredit
                    ? l10n.paymentCustomerCredit
                    : l10n.paymentMethodPending,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: settlementColor,
                ),
              ),
              Text(
                formatAmount(remaining.abs()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: settlementColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final actionRow = Row(
      children: [
        Expanded(
          child: AppOutlinedActionButton(
            onPressed: () => Navigator.of(context).pop(),
            padding: AppButtonStyles.dialogButtonPadding,
            child: Text(l10n.actionCancel),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppFilledButton(
            onPressed: isValid ? () => Navigator.of(context).pop(true) : null,
            padding: AppButtonStyles.dialogButtonPadding,
            child: Text(l10n.actionSave),
          ),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        methodRows,
        const SizedBox(height: 18),
        summary,
        const SizedBox(height: 20),
        actionRow,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = _buildContent(context);

    if (!widget.isBottomSheet) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 360, maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderRow(context, theme.textTheme.titleLarge),
                  const SizedBox(height: 28),
                  content,
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Bottom sheet presentation
    const horizontalPadding = 20.0;
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                4,
              ),
              child: _buildHeaderRow(context, theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: content,
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }
}
