import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/models/business_payment_method.dart';
import '../../../../core/models/booking_payment.dart';
import '../../../../core/models/booking_payment_computed.dart';
import '../../../../core/models/booking_payment_line.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/booking_payment_providers.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/bookings_repository_provider.dart';
import '../../providers/location_providers.dart';
import '../../../payments/providers/payment_methods_provider.dart';

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
  static const String _discountMethodCode = BookingPaymentLineType.discount;
  static const List<String> _defaultPaidMethodCodes = <String>[
    BookingPaymentLineType.cash,
    BookingPaymentLineType.card,
    BookingPaymentLineType.voucher,
    BookingPaymentLineType.other,
  ];

  static const List<double> _quickPercentages = <double>[10, 20, 30, 50, 100];

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  List<BusinessPaymentMethod> _businessPaymentMethods = const [];
  List<String> _paidMethodCodes = List<String>.from(_defaultPaidMethodCodes);
  late final TextEditingController _totalPriceController;
  late final FocusNode _totalPriceReadOnlyFocusNode;
  late final TextEditingController _noteController;
  bool _isPersisting = false;
  bool _isLoadingPersisted = false;
  int _loadedAutoDiscountCents = 0;

  @override
  void initState() {
    super.initState();
    for (final code in [..._defaultPaidMethodCodes, _discountMethodCode]) {
      _ensureMethodState(code);
    }
    _totalPriceController = TextEditingController(
      text: _formatAmountValue(widget.totalPrice),
    );
    _totalPriceReadOnlyFocusNode = FocusNode(skipTraversal: true);
    _noteController = TextEditingController();
    for (final node in _focusNodes.values) {
      node.addListener(() {
        if (!node.hasFocus) {
          _rebalanceOverflow();
          if (mounted) {
            setState(() {});
          }
        }
      });
    }
    _loadBusinessPaymentMethods();
    if (widget.initialPayment != null) {
      _applyBookingPayment(widget.initialPayment!);
    } else if (widget.bookingId != null) {
      _loadPersistedPayment();
    }
  }

  void _ensureMethodState(String methodCode) {
    _controllers.putIfAbsent(methodCode, () {
      final controller = TextEditingController(text: _formatAmountValue(0));
      return controller;
    });
    _focusNodes.putIfAbsent(methodCode, () {
      final node = FocusNode();
      node.addListener(() {
        if (!node.hasFocus) {
          _rebalanceOverflow();
          if (mounted) {
            setState(() {});
          }
        }
      });
      return node;
    });
  }

  Future<void> _loadBusinessPaymentMethods() async {
    try {
      final methods = await ref.read(paymentMethodsProvider.future);
      if (!mounted) return;
      final activeMethods = methods.where((m) => m.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final methodCodes = activeMethods
          .map((m) => m.code.trim())
          .where((code) => code.isNotEmpty && code != _discountMethodCode)
          .toList();

      final nextCodes = methodCodes.isEmpty
          ? List<String>.from(_defaultPaidMethodCodes)
          : methodCodes;

      for (final code in nextCodes) {
        _ensureMethodState(code);
      }

      setState(() {
        _businessPaymentMethods = activeMethods;
        _paidMethodCodes = nextCodes;
      });
    } catch (_) {
      // Fallback ai metodi default se il fetch fallisce.
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
    _totalPriceReadOnlyFocusNode.dispose();
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

  double get _totalPaidEntered {
    return _controllers.entries
        .where((entry) => entry.key != _discountMethodCode)
        .fold<double>(0, (sum, entry) {
          final amount = PriceFormatter.parse(entry.value.text) ?? 0;
          return sum + amount;
        });
  }

  double get _totalDueReductions {
    return _amountForMethod(_discountMethodCode) ?? 0;
  }

  double get _effectiveAmountDue {
    final due = _currentTotalPrice - _totalDueReductions;
    return due > 0 ? due : 0;
  }

  double get _remainingToPay {
    final remaining = _effectiveAmountDue - _totalPaidEntered;
    return remaining > 0 ? remaining : 0;
  }

  bool get _isValid => true;

  int get _currencyDecimalDigits =>
      PriceFormatter.decimalDigitsForCurrency(widget.currencyCode);

  bool _supportsQuickChips(String methodCode) => true;

  bool _isMethodEditable(String methodCode) =>
      methodCode != _discountMethodCode;

  List<String> _paymentPriorityOrder() => <String>[
    ..._paidMethodCodes,
    _discountMethodCode,
  ];

  List<String> _visiblePaymentMethods() {
    final methods = List<String>.from(_paidMethodCodes);
    final discountAmount = _amountForMethod(_discountMethodCode) ?? 0;
    if (discountAmount > 0) {
      methods.add(_discountMethodCode);
    }

    return methods;
  }

  String _formatAmountValue(double value) {
    return value.toStringAsFixed(_currencyDecimalDigits).replaceAll('.', ',');
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

  double? _amountForMethod(String methodCode) {
    final controller = _controllers[methodCode];
    if (controller == null) return null;
    return PriceFormatter.parse(controller.text);
  }

  double? _selectedPercentForMethod(String methodCode) {
    if (!_supportsQuickChips(methodCode) || _currentTotalPrice <= 0) {
      return null;
    }
    final amount = _amountForMethod(methodCode);
    if (amount == null || amount <= 0) return null;
    return (amount / _currentTotalPrice) * 100;
  }

  bool _samePercent(double a, double b) => (a - b).abs() < 0.01;

  List<double> _chipPercentagesForMethod(String methodCode) {
    final options = List<double>.from(_quickPercentages);
    final current = _selectedPercentForMethod(methodCode);
    if (current == null) return options;
    final hasMatch = options.any((value) => _samePercent(value, current));
    if (!hasMatch) {
      options.add(current);
      options.sort((a, b) => a.compareTo(b));
    }
    return options;
  }

  void _applyQuickPercentage(String methodCode, double percentage) {
    if (_currentTotalPrice <= 0) return;
    final amount = _currentTotalPrice * percentage / 100;
    _ensureMethodState(methodCode);
    _setControllerValue(_controllers[methodCode]!, _formatAmountValue(amount));
    _rebalanceOverflow(preservedMethod: methodCode);
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

  void _applyBookingPayment(BookingPayment payment) {
    _loadedAutoDiscountCents = payment.lines
        .where(
          (line) =>
              line.type == BookingPaymentLineType.discount &&
              line.meta?['source'] == 'appointment_amount_adjustment',
        )
        .fold<int>(0, (sum, line) => sum + line.amountCents);
    _setControllerValue(
      _totalPriceController,
      _formatAmountValue(_amountFromCents(payment.totalDueCents)),
    );
    final totalsByMethod = <String, int>{};
    for (final line in payment.lines) {
      final methodCode = line.type.trim().isNotEmpty
          ? line.type.trim()
          : BookingPaymentLineType.other;
      _ensureMethodState(methodCode);
      if (methodCode != _discountMethodCode &&
          !_paidMethodCodes.contains(methodCode)) {
        _paidMethodCodes = [..._paidMethodCodes, methodCode];
      }
      totalsByMethod[methodCode] =
          (totalsByMethod[methodCode] ?? 0) + line.amountCents;
    }
    for (final entry in _controllers.entries) {
      final amountCents = totalsByMethod[entry.key] ?? 0;
      _setControllerValue(
        entry.value,
        _formatAmountValue(_amountFromCents(amountCents)),
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
      if (entry.key == _discountMethodCode) {
        final autoDiscountCents = amountCents < _loadedAutoDiscountCents
            ? amountCents
            : _loadedAutoDiscountCents;
        final manualDiscountCents = amountCents - autoDiscountCents;
        if (autoDiscountCents > 0) {
          lines.add(
            BookingPaymentLine(
              type: BookingPaymentLineType.discount,
              amountCents: autoDiscountCents,
              meta: const {'source': 'appointment_amount_adjustment'},
            ),
          );
        }
        if (manualDiscountCents > 0) {
          lines.add(
            BookingPaymentLine(
              type: BookingPaymentLineType.discount,
              amountCents: manualDiscountCents,
              meta: const {'source': 'manual'},
            ),
          );
        }
        continue;
      }
      lines.add(BookingPaymentLine(type: entry.key, amountCents: amountCents));
    }

    return BookingPayment(
      bookingId: bookingId,
      clientId: null,
      isActive: false,
      currency: widget.currencyCode,
      totalDueCents: totalDueCents,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
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
      final loadedPayment = await ref.read(
        bookingPaymentProvider(bookingId).future,
      );
      final payment =
          loadedPayment == null || _shouldUseFormTotalFallback(loadedPayment)
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
    return payment.totalDueCents <= 0 && payment.lines.isEmpty && note.isEmpty;
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
      if (saved.computed.balanceCents <= 0) {
        await _setBookingCompleted(bookingId);
      }
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

  Future<void> _setBookingCompleted(int bookingId) async {
    final location = ref.read(currentLocationProvider);
    final repository = ref.read(bookingsRepositoryProvider);
    await repository.updateBooking(
      locationId: location.id,
      bookingId: bookingId,
      status: 'completed',
    );
    ref.read(bookingsProvider.notifier).setStatus(bookingId, 'completed');
    ref
        .read(appointmentsProvider.notifier)
        .setBookingStatusForBooking(bookingId: bookingId, status: 'completed');
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

  void _rebalanceOverflow({String? preservedMethod}) {
    final totalDue = _currentTotalPrice;
    if (totalDue < 0) return;

    final amounts = <String, double>{
      for (final method in _paymentPriorityOrder())
        method: (_amountForMethod(method) ?? 0).clamp(0, double.infinity),
    };

    final total = _manualEnteredTotal;
    double overflow = total - totalDue;
    if (overflow <= 0.01) return;

    // The edited method keeps its value as long as possible. The other methods
    // are reduced first, starting from the lowest-priority one.
    final reductionOrder = _paymentPriorityOrder().reversed.where(
      (method) => method != preservedMethod && _isMethodEditable(method),
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

    for (final method in _paymentPriorityOrder()) {
      if ((preservedMethod != null && method == preservedMethod) ||
          !_isMethodEditable(method)) {
        continue;
      }
      _ensureMethodState(method);
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

  String _methodLabel(BuildContext context, String methodCode) {
    final l10n = context.l10n;
    if (methodCode == _discountMethodCode) {
      return l10n.paymentMethodDiscount;
    }

    for (final method in _businessPaymentMethods) {
      if (method.code == methodCode && method.name.isNotEmpty) {
        return method.name;
      }
    }

    switch (methodCode) {
      case BookingPaymentLineType.cash:
        return l10n.paymentMethodCash;
      case BookingPaymentLineType.card:
        return l10n.paymentMethodCard;
      case BookingPaymentLineType.voucher:
        return l10n.paymentMethodVoucher;
      case BookingPaymentLineType.other:
        return l10n.paymentMethodOther;
      default:
        return methodCode;
    }
  }

  IconData _methodIcon(String methodCode) {
    switch (methodCode) {
      case BookingPaymentLineType.cash:
        return Icons.payments_outlined;
      case BookingPaymentLineType.card:
        return Icons.credit_card_outlined;
      case BookingPaymentLineType.discount:
        return Icons.discount_outlined;
      case BookingPaymentLineType.voucher:
        return Icons.card_giftcard_outlined;
      case BookingPaymentLineType.other:
        return Icons.more_horiz_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  Widget _buildQuickChips(BuildContext context, String methodCode) {
    final theme = Theme.of(context);
    final selectedPercent = _selectedPercentForMethod(methodCode);
    final options = _chipPercentagesForMethod(methodCode);
    final isEditable = _isMethodEditable(methodCode);

    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final percentage in options)
            Builder(
              builder: (context) {
                final isSelected =
                    selectedPercent != null &&
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
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 1,
                    vertical: 0,
                  ),
                  selected: isSelected,
                  onSelected: isEditable
                      ? (_) {
                          _applyQuickPercentage(methodCode, percentage);
                          setState(() {});
                        }
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAmountField(String methodCode) {
    _ensureMethodState(methodCode);
    final controller = _controllers[methodCode]!;
    final isEditable = _isMethodEditable(methodCode);

    return _buildReadOnlyAwareAmountField(
      controller: controller,
      focusNode: _focusNodes[methodCode]!,
      isReadOnly: !isEditable,
      onChanged: isEditable
          ? (value) {
              _normalizeNonNegativeAmount(controller, value);
              _rebalanceOverflow(preservedMethod: methodCode);
              setState(() {});
            }
          : null,
      onTap: isEditable ? () => _selectAll(controller) : null,
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _amountInputFormatters(),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: '0,00',
            isDense: true,
            filled: isReadOnly,
            fillColor: isReadOnly ? Colors.grey.withOpacity(0.10) : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
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
    return _buildReadOnlyAwareAmountField(
      controller: _totalPriceController,
      focusNode: _totalPriceReadOnlyFocusNode,
      isReadOnly: true,
      textStyle: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    TextStyle? titleStyle,
    Color accentColor,
  ) {
    final l10n = context.l10n;
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
                  l10n.paymentBookingAmount,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
    final amountDue = _effectiveAmountDue;
    final totalPaid = _totalPaidEntered;
    final remaining = _remainingToPay;
    final isValid = _isValid;
    final settlementColor = _settlementColor(context, remaining);

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
                l10n.paymentAmountDue,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                formatAmount(amountDue),
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
                l10n.paymentTotalPaid,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                formatAmount(totalPaid),
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
                formatAmount(remaining),
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
    final visibleMethods = _visiblePaymentMethods();

    final methodRows = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < visibleMethods.length; i++)
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
                                _methodIcon(visibleMethods[i]),
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _methodLabel(context, visibleMethods[i]),
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
                          if (_supportsQuickChips(visibleMethods[i]))
                            _buildQuickChips(context, visibleMethods[i]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildAmountField(visibleMethods[i]),
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
      final maxDialogBodyHeight = MediaQuery.sizeOf(context).height * 0.62;
      return DismissibleDialog(
        child: AppFormDialog(
          title: _buildHeaderRow(
            context,
            theme.textTheme.titleLarge,
            _settlementColor(context, _remainingToPay),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogBodyHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [content, const SizedBox(height: 18), summary],
              ),
            ),
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
              _settlementColor(context, _remainingToPay),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: content)),
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
