import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/models/booking_payment.dart';
import '../../../../core/models/booking_payment_computed.dart';
import '../../../../core/models/booking_payment_line.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../providers/booking_payment_providers.dart';

/// Mostra il dialog di pagamento per distribuire il totale di una prenotazione
/// tra diversi metodi di pagamento.
Future<BookingPayment?> showPaymentDialog(
  BuildContext context,
  WidgetRef ref, {
  required double totalPrice,
  required String currencyCode,
  int? bookingId,
  BookingPayment? initialPayment,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final isBottomSheet = formFactor != AppFormFactor.desktop;

  final content = _PaymentDialog(
    totalPrice: totalPrice,
    currencyCode: currencyCode,
    isBottomSheet: isBottomSheet,
    bookingId: bookingId,
    initialPayment: initialPayment,
  );

  if (!isBottomSheet) {
    final result = await showDialog<BookingPayment?>(
      context: context,
      builder: (_) => content,
    );
    return result;
  } else {
    final result = await AppBottomSheet.show<BookingPayment?>(
      context: context,
      useRootNavigator: true,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      builder: (_) => content,
    );
    return result;
  }
}

enum _PaymentMethod { cash, card, discount, voucher, other }

class _PaymentDialog extends ConsumerStatefulWidget {
  const _PaymentDialog({
    required this.totalPrice,
    required this.currencyCode,
    required this.isBottomSheet,
    this.bookingId,
    this.initialPayment,
  });

  final double totalPrice;
  final String currencyCode;
  final bool isBottomSheet;
  final int? bookingId;
  final BookingPayment? initialPayment;

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  static const String _paymentAmountLabel = 'Importo prenotazione';
  static const List<_PaymentMethod> _paymentPriorityOrder = _PaymentMethod.values;

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
  final Map<_PaymentMethod, FocusNode> _focusNodes = {
    for (final m in _PaymentMethod.values) m: FocusNode(),
  };
  late final TextEditingController _totalPriceController;
  late final FocusNode _totalPriceFocusNode;
  late final TextEditingController _noteController;
  bool _isPersisting = false;
  bool _isLoadingPersisted = false;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers.values) {
      controller.text = _formatAmountValue(0);
    }
    _totalPriceController = TextEditingController(
      text: _formatAmountValue(widget.totalPrice),
    );
    _totalPriceFocusNode = FocusNode()
      ..addListener(() {
        if (!_totalPriceFocusNode.hasFocus) {
          _rebalanceOverflow();
          if (mounted) {
            setState(() {});
          }
        }
      });
    _noteController = TextEditingController();
    for (final entry in _focusNodes.entries) {
      entry.value.addListener(() {
        if (!entry.value.hasFocus) {
          _rebalanceOverflow();
          if (mounted) {
            setState(() {});
          }
        }
      });
    }
    if (widget.bookingId != null) {
      _loadPersistedPayment();
    } else if (widget.initialPayment != null) {
      _applyBookingPayment(widget.initialPayment!);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _totalPriceController.dispose();
    _totalPriceFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _currentTotalPrice {
    final parsed = PriceFormatter.parse(_totalPriceController.text);
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  double get _manualEnteredTotal {
    double total = 0;
    for (final entry in _controllers.entries) {
      final value = PriceFormatter.parse(entry.value.text);
      if (value == null) continue;
      total += value;
    }
    return total;
  }

  bool get _isValid => true;

  int get _currencyDecimalDigits =>
      PriceFormatter.decimalDigitsForCurrency(widget.currencyCode);

  bool _supportsQuickChips(_PaymentMethod method) {
    return method == _PaymentMethod.cash ||
        method == _PaymentMethod.discount ||
        method == _PaymentMethod.card ||
        method == _PaymentMethod.voucher ||
        method == _PaymentMethod.other;
  }

  String _formatAmountValue(double value) {
    return value
        .toStringAsFixed(_currencyDecimalDigits)
        .replaceAll('.', ',');
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

  List<TextInputFormatter> _amountInputFormatters() {
    return [
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty) {
          return newValue;
        }

        final normalized = text.replaceAll(',', '.');
        final maxDecimals = _currencyDecimalDigits;
        final decimalPattern = maxDecimals > 0
            ? RegExp('^\\d*(?:\\.\\d{0,$maxDecimals})?\$')
            : RegExp(r'^\d*$');

        if (!decimalPattern.hasMatch(normalized)) {
          return oldValue;
        }

        final firstDot = normalized.indexOf('.');
        if (firstDot >= 0 && normalized.indexOf('.', firstDot + 1) >= 0) {
          return oldValue;
        }

        return newValue;
      }),
    ];
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
    _rebalanceOverflow(preservedMethod: method);
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

  int _centsFromAmount(double amount) => (amount * 100).round();

  double _amountFromCents(int cents) => cents / 100.0;

  BookingPaymentLineType _lineTypeForMethod(_PaymentMethod method) {
    switch (method) {
      case _PaymentMethod.cash:
        return BookingPaymentLineType.cash;
      case _PaymentMethod.card:
        return BookingPaymentLineType.card;
      case _PaymentMethod.discount:
        return BookingPaymentLineType.discount;
      case _PaymentMethod.voucher:
        return BookingPaymentLineType.voucher;
      case _PaymentMethod.other:
        return BookingPaymentLineType.other;
    }
  }

  _PaymentMethod _methodForLineType(BookingPaymentLineType type) {
    switch (type) {
      case BookingPaymentLineType.cash:
        return _PaymentMethod.cash;
      case BookingPaymentLineType.card:
        return _PaymentMethod.card;
      case BookingPaymentLineType.discount:
        return _PaymentMethod.discount;
      case BookingPaymentLineType.voucher:
        return _PaymentMethod.voucher;
      case BookingPaymentLineType.other:
        return _PaymentMethod.other;
    }
  }

  void _applyBookingPayment(BookingPayment payment) {
    _setControllerValue(
      _totalPriceController,
      _formatAmountValue(_amountFromCents(payment.totalDueCents)),
    );
    for (final entry in _controllers.entries) {
      _setControllerValue(entry.value, _formatAmountValue(0));
    }
    for (final line in payment.lines) {
      final method = _methodForLineType(line.type);
      _setControllerValue(
        _controllers[method]!,
        _formatAmountValue(_amountFromCents(line.amountCents)),
      );
    }
    _setControllerValue(_noteController, payment.note ?? '');
  }

  BookingPayment _buildBookingPayment() {
    final bookingId = widget.bookingId ?? 0;
    final totalDueCents = _centsFromAmount(_currentTotalPrice);
    final lines = <BookingPaymentLine>[];

    for (final entry in _controllers.entries) {
      final amount = PriceFormatter.parse(entry.value.text) ?? 0;
      final amountCents = _centsFromAmount(amount);
      if (amountCents <= 0) {
        continue;
      }
      lines.add(
        BookingPaymentLine(
          type: _lineTypeForMethod(entry.key),
          amountCents: amountCents,
        ),
      );
    }

    return BookingPayment(
      bookingId: bookingId,
      clientId: null,
      isActive: false,
      currency: widget.currencyCode,
      totalDueCents: totalDueCents,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      lines: lines,
      computed: BookingPaymentComputed(
        totalPaidCents: 0,
        totalDiscountCents: 0,
        balanceCents: 0,
      ),
    );
  }

  Future<void> _loadPersistedPayment() async {
    final bookingId = widget.bookingId;
    if (bookingId == null) return;

    setState(() => _isLoadingPersisted = true);
    try {
      final controller = ref.read(bookingPaymentControllerProvider(bookingId));
      final loadedPayment = await ref.read(bookingPaymentProvider(bookingId).future);
      final payment = loadedPayment == null || _shouldUseFormTotalFallback(loadedPayment)
          ? controller.defaultValue(
              totalDueCents: _centsFromAmount(widget.totalPrice),
              currency: widget.currencyCode,
            )
          : loadedPayment;
      if (!mounted) return;
      setState(() {
        _applyBookingPayment(payment);
        _isLoadingPersisted = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPersisted = false);
    }
  }

  bool _shouldUseFormTotalFallback(BookingPayment payment) {
    final note = payment.note?.trim() ?? '';
    return payment.totalDueCents <= 0 &&
        payment.lines.isEmpty &&
        note.isEmpty;
  }

  Future<void> _handleSave() async {
    _rebalanceOverflow();
    final draftPayment = _buildBookingPayment();
    final bookingId = widget.bookingId;
    if (bookingId == null) {
      Navigator.of(context).pop(draftPayment);
      return;
    }

    setState(() => _isPersisting = true);
    try {
      final controller = ref.read(bookingPaymentControllerProvider(bookingId));
      final saved = await controller.save(draftPayment);
      ref.invalidate(bookingPaymentProvider(bookingId));
      if (!mounted) return;
      _applyBookingPayment(saved);
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.actionPayment,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isPersisting = false);
      }
    }
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

  void _rebalanceOverflow({_PaymentMethod? preservedMethod}) {
    final totalDue = _currentTotalPrice;
    if (totalDue < 0) return;

    final amounts = <_PaymentMethod, double>{
      for (final method in _paymentPriorityOrder)
        method: (_amountForMethod(method) ?? 0).clamp(0, double.infinity),
    };

    final total = _manualEnteredTotal;
    double overflow = total - totalDue;
    if (overflow <= 0.01) return;

    // The edited method keeps its value as long as possible. The other methods
    // are reduced first, starting from the lowest-priority one.
    final reductionOrder = _paymentPriorityOrder.reversed.where(
      (method) => method != preservedMethod,
    );

    for (final method in reductionOrder) {
      if (overflow <= 0.01) break;
      final current = amounts[method] ?? 0;
      if (current <= 0) continue;

      final reduction = current >= overflow ? overflow : current;
      final nextValue = current - reduction;
      amounts[method] = nextValue;
      overflow -= reduction;
    }

    for (final method in _paymentPriorityOrder) {
      if (preservedMethod != null && method == preservedMethod) {
        continue;
      }
      _setControllerValue(
        _controllers[method]!,
        _formatAmountValue(amounts[method] ?? 0),
      );
    }
  }

  Color _settlementColor(BuildContext context, double remaining) {
    if (remaining > 0.01) {
      return Colors.red.shade700;
    }
    return Colors.green.shade700;
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
    final controller = _controllers[method]!;

    return _buildReadOnlyAwareAmountField(
      controller: controller,
      focusNode: _focusNodes[method]!,
      isReadOnly: false,
      onChanged: (value) {
        _normalizeNonNegativeAmount(controller, value);
        _rebalanceOverflow(preservedMethod: method);
        setState(() {});
      },
      onTap: () => _selectAll(controller),
    );
  }

  Widget _buildReadOnlyAwareAmountField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isReadOnly,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    TextStyle? textStyle,
  }) {
    return SizedBox(
      width: 92,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: isReadOnly,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          inputFormatters: _amountInputFormatters(),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: '0,00',
            isDense: true,
            filled: isReadOnly,
            fillColor: isReadOnly
                ? Colors.grey.withOpacity(0.10)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
            ),
            enabledBorder: null,
            focusedBorder: null,
          ),
          style: textStyle,
          onTap: onTap,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTotalPriceField(Color accentColor) {
    return SizedBox(
      width: 92,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _selectAll(_totalPriceController),
        child: TextField(
          controller: _totalPriceController,
          focusNode: _totalPriceFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _amountInputFormatters(),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: '0,00',
            isDense: true,
            hintStyle: TextStyle(color: accentColor.withOpacity(0.7)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(color: accentColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(color: accentColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(color: accentColor, width: 1.4),
            ),
          ),
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w700,
          ),
          onTap: () => _selectAll(_totalPriceController),
          onChanged: (value) {
            _normalizeNonNegativeAmount(_totalPriceController, value);
            _rebalanceOverflow();
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    TextStyle? titleStyle,
    Color accentColor,
  ) {
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
                  style: titleStyle?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildTotalPriceField(accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField(BuildContext context) {
    final l10n = context.l10n;

    return TextField(
      controller: _noteController,
      minLines: 2,
      maxLines: 3,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        labelText: l10n.paymentNotesLabel,
        hintText: l10n.paymentNotesPlaceholder,
        alignLabelWithHint: true,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final l10n = context.l10n;
    final isValid = _isValid;

    return [
      AppOutlinedActionButton(
        onPressed: _isPersisting ? null : () => Navigator.of(context).pop(),
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionCancel),
      ),
      AppFilledButton(
        onPressed: isValid && !_isPersisting && !_isLoadingPersisted
            ? _handleSave
            : null,
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(
          widget.bookingId == null ? l10n.actionConfirm : l10n.actionSave,
        ),
      ),
    ];
  }

  Widget _buildSummary(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final totalPrice = _currentTotalPrice;
    final totalEntered = _manualEnteredTotal;
    final remaining = totalPrice - totalEntered;
    final isValid = _isValid;
    final settlementColor = _settlementColor(context, remaining);
    final payableRemaining = remaining > 0 ? remaining : 0.0;

    String formatAmount(double amount) => PriceFormatter.format(
      context: context,
      amount: amount,
      currencyCode: widget.currencyCode,
    );

    return AnimatedContainer(
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
                l10n.paymentMethodPending,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: settlementColor,
                ),
              ),
              Text(
                formatAmount(payableRemaining),
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
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

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
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize:
                                        (theme.textTheme.bodySmall?.fontSize ??
                                            12) +
                                        1,
                                    fontWeight: FontWeight.w700,
                                  ),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        methodRows,
        const SizedBox(height: 14),
        _buildNoteField(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = _buildContent(context);
    final summary = _buildSummary(context);
    final actions = _buildActions(context);

    if (!widget.isBottomSheet) {
      return DismissibleDialog(
        child: AppFormDialog(
          title: _buildHeaderRow(
            context,
            theme.textTheme.titleLarge,
            _settlementColor(context, _currentTotalPrice - _manualEnteredTotal),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              const SizedBox(height: 18),
              summary,
            ],
          ),
          actions: actions,
          contentPadding: const EdgeInsets.only(top: 20),
        ),
      );
    }

    const horizontalPadding = 20.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildHeaderRow(
              context,
              theme.textTheme.titleMedium,
              _settlementColor(context, _currentTotalPrice - _manualEnteredTotal),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: content,
            ),
          ),
          const SizedBox(height: 16),
          summary,
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: actions[0]),
              const SizedBox(width: 8),
              Expanded(child: actions[1]),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
