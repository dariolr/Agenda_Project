import 'package:flutter/material.dart';

void main() {
  runApp(const AgendaFrontendApp());
}

class AgendaFrontendApp extends StatelessWidget {
  const AgendaFrontendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda - Prenotazione Online',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B998B),
          brightness: Brightness.light,
        ),
      ),
      home: const BookingFlowScreen(),
    );
  }
}

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _isRegistered = true;
  bool _allowStaffSelection = true;

  int _currentStep = 0;
  StaffMember? _selectedStaff;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<ServiceCategory> _categories = const [
    ServiceCategory(
      id: 10,
      name: 'Trattamenti Corpo',
      description: 'Servizi dedicati al benessere del corpo',
      sortOrder: 0,
    ),
    ServiceCategory(
      id: 11,
      name: 'Trattamenti Sportivi',
      description: 'Percorsi pensati per atleti e persone attive',
      sortOrder: 1,
    ),
    ServiceCategory(
      id: 12,
      name: 'Trattamenti Viso',
      description: 'Cura estetica e rigenerante per il viso',
      sortOrder: 2,
    ),
  ];

  final List<ServiceItem> _services = const [
    ServiceItem(
      id: 1,
      categoryId: 10,
      name: 'Massaggio Relax',
      description: 'Trattamento rilassante da 30 minuti',
      durationMinutes: 30,
      price: 35,
      sortOrder: 0,
      eligibleStaffIds: [1, 2, 3],
    ),
    ServiceItem(
      id: 4,
      categoryId: 10,
      name: 'Trattamento Corpo Linfodrenante',
      description: 'Massaggio drenante da 50 minuti',
      durationMinutes: 50,
      price: 55,
      sortOrder: 1,
      eligibleStaffIds: [1, 2],
    ),
    ServiceItem(
      id: 2,
      categoryId: 11,
      name: 'Massaggio Sportivo',
      description: 'Trattamento decontratturante intensivo',
      durationMinutes: 45,
      price: 60,
      sortOrder: 0,
      eligibleStaffIds: [2, 3],
    ),
    ServiceItem(
      id: 5,
      categoryId: 11,
      name: 'Recupero Post Gara',
      description: 'Sessione mirata da 40 minuti',
      durationMinutes: 40,
      price: 50,
      sortOrder: 1,
      eligibleStaffIds: [2],
    ),
    ServiceItem(
      id: 3,
      categoryId: 12,
      name: 'Trattamento Viso',
      description: 'Pulizia e trattamento illuminante',
      durationMinutes: 35,
      price: 45,
      sortOrder: 0,
      eligibleStaffIds: [1, 3],
    ),
    ServiceItem(
      id: 6,
      categoryId: 12,
      name: 'Rituale Anti-Age',
      description: 'Trattamento completo da 55 minuti',
      durationMinutes: 55,
      price: 70,
      sortOrder: 1,
      eligibleStaffIds: [1],
    ),
  ];

  final List<StaffMember> _staff = const [
    StaffMember(id: 1, name: 'Giulia Rossi'),
    StaffMember(id: 2, name: 'Marco Bianchi'),
    StaffMember(id: 3, name: 'Elena Verdi'),
  ];

  final Set<int> _selectedServiceIds = <int>{};

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  List<ServiceCategory> get _sortedCategories {
    final items = [..._categories];
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  List<ServiceItem> _servicesForCategory(int categoryId) {
    final items = _services
        .where((service) => service.categoryId == categoryId)
        .toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  List<ServiceItem> get _selectedServices => _services
      .where((service) => _selectedServiceIds.contains(service.id))
      .toList();

  int get _totalDuration {
    return _selectedServices.fold(0, (sum, item) => sum + item.durationMinutes);
  }

  double get _totalPrice {
    return _selectedServices.fold(0, (sum, item) => sum + item.price);
  }

  bool get _isAuthValid {
    if (_isRegistered) {
      return _loginFormKey.currentState?.validate() ?? false;
    }
    return _registerFormKey.currentState?.validate() ?? false;
  }

  bool get _isServicesValid => _selectedServiceIds.isNotEmpty;

  bool get _isStaffValid => !_allowStaffSelection || _selectedStaff != null;

  bool get _isAvailabilityValid => _selectedDate != null && _selectedTime != null;

  DateTime? _firstAvailableSlot() {
    if (_selectedServiceIds.isEmpty) return null;
    final duration = _totalDuration;
    final startDate = DateTime.now();
    final staff = _allowStaffSelection ? _selectedStaff : null;

    for (int i = 0; i < 45; i++) {
      final date = DateTime(startDate.year, startDate.month, startDate.day)
          .add(Duration(days: i));
      final slots = _availableSlotsForDate(date, duration, staff);
      if (slots.isNotEmpty) {
        final first = slots.first;
        return DateTime(date.year, date.month, date.day, first.hour, first.minute);
      }
    }

    return null;
  }

  List<TimeOfDay> _availableSlotsForDate(
    DateTime date,
    int durationMinutes,
    StaffMember? staff,
  ) {
    if (durationMinutes == 0) return const [];

    final weekday = date.weekday; // 1..7
    if (staff != null && !_staffWorksOnDay(staff, weekday)) {
      return const [];
    }

    final startHour = 9;
    final endHour = 18;
    final lunchStart = const TimeOfDay(hour: 13, minute: 0);
    final lunchEnd = const TimeOfDay(hour: 14, minute: 0);

    final slots = <TimeOfDay>[];
    final totalMinutes = (endHour - startHour) * 60;

    for (int offset = 0; offset <= totalMinutes; offset += 30) {
      final startMinutes = startHour * 60 + offset;
      final endMinutes = startMinutes + durationMinutes;
      if (endMinutes > endHour * 60) continue;

      final slot = TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60);
      final slotEnd = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);

      if (_overlapsLunch(slot, slotEnd, lunchStart, lunchEnd)) continue;
      if (_isBlockedSlot(date, slot, staff)) continue;

      slots.add(slot);
    }

    return slots;
  }

  bool _staffWorksOnDay(StaffMember staff, int weekday) {
    switch (staff.id) {
      case 1:
        return weekday >= DateTime.monday && weekday <= DateTime.friday;
      case 2:
        return weekday >= DateTime.tuesday && weekday <= DateTime.saturday;
      case 3:
        return weekday >= DateTime.wednesday && weekday <= DateTime.sunday;
      default:
        return true;
    }
  }

  bool _overlapsLunch(
    TimeOfDay slotStart,
    TimeOfDay slotEnd,
    TimeOfDay lunchStart,
    TimeOfDay lunchEnd,
  ) {
    final slotStartMin = slotStart.hour * 60 + slotStart.minute;
    final slotEndMin = slotEnd.hour * 60 + slotEnd.minute;
    final lunchStartMin = lunchStart.hour * 60 + lunchStart.minute;
    final lunchEndMin = lunchEnd.hour * 60 + lunchEnd.minute;

    return slotStartMin < lunchEndMin && slotEndMin > lunchStartMin;
  }

  bool _isBlockedSlot(DateTime date, TimeOfDay slot, StaffMember? staff) {
    if (staff == null) return false;

    if (staff.id == 2 && date.weekday == DateTime.friday && slot.hour >= 16) {
      return true;
    }
    if (staff.id == 1 && date.weekday == DateTime.monday && slot.hour < 11) {
      return true;
    }
    return false;
  }

  void _resetAvailability() {
    _selectedDate = null;
    _selectedTime = null;
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _handleContinue() {
    if (_currentStep == 0) {
      if (_isAuthValid) {
        _goToStep(1);
      } else {
        setState(() {});
      }
      return;
    }

    if (_currentStep == 1) {
      if (_isServicesValid) {
        _goToStep(2);
      } else {
        setState(() {});
      }
      return;
    }

    if (_currentStep == 2) {
      if (_isStaffValid) {
        _goToStep(3);
      } else {
        setState(() {});
      }
      return;
    }

    if (_currentStep == 3) {
      if (_isAvailabilityValid) {
        _goToStep(4);
      } else {
        setState(() {});
      }
      return;
    }

    if (_currentStep == 4) {
      _confirmBooking();
    }
  }

  void _handleBack() {
    if (_currentStep == 0) return;
    _goToStep(_currentStep - 1);
  }

  void _confirmBooking() {
    if (!_isAvailabilityValid) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prenotazione confermata!'),
      ),
    );
  }

  void _updateStaffSelection(StaffMember? staff) {
    setState(() {
      _selectedStaff = staff;
      _resetAvailability();
    });
  }

  void _toggleServiceSelection(ServiceItem service, bool selected) {
    setState(() {
      if (selected) {
        _selectedServiceIds.add(service.id);
      } else {
        _selectedServiceIds.remove(service.id);
      }
      _resetAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstSlot = _firstAvailableSlot();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prenotazione Online'),
        actions: [
          Row(
            children: [
              const Text('Scelta operatore'),
              Switch(
                value: _allowStaffSelection,
                onChanged: (value) {
                  setState(() {
                    _allowStaffSelection = value;
                    if (!value) {
                      _selectedStaff = null;
                    }
                    _resetAvailability();
                  });
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _handleContinue,
        onStepCancel: _handleBack,
        onStepTapped: (index) {
          if (index <= _currentStep) {
            _goToStep(index);
          }
        },
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 4;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(isLast ? 'Conferma' : 'Avanti'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Indietro'),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Accesso o Registrazione'),
            isActive: _currentStep >= 0,
            state: _isAuthValid ? StepState.complete : StepState.indexed,
            content: _buildAuthStep(),
          ),
          Step(
            title: const Text('Seleziona servizi'),
            isActive: _currentStep >= 1,
            state: _isServicesValid ? StepState.complete : StepState.indexed,
            content: _buildServicesStep(),
          ),
          Step(
            title: const Text('Operatore'),
            isActive: _currentStep >= 2,
            state: _isStaffValid ? StepState.complete : StepState.indexed,
            content: _buildStaffStep(),
          ),
          Step(
            title: const Text('Disponibilità'),
            isActive: _currentStep >= 3,
            state: _isAvailabilityValid ? StepState.complete : StepState.indexed,
            content: _buildAvailabilityStep(firstSlot),
          ),
          Step(
            title: const Text('Riepilogo'),
            isActive: _currentStep >= 4,
            state: StepState.indexed,
            content: _buildSummaryStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToggleButtons(
          isSelected: [_isRegistered, !_isRegistered],
          onPressed: (index) {
            setState(() {
              _isRegistered = index == 0;
            });
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Sono già registrato'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Nuova registrazione'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isRegistered) _buildLoginForm() else _buildRegisterForm(),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _loginEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci la tua email';
              }
              if (!value.contains('@')) {
                return 'Email non valida';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _loginPasswordController,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci la password';
              }
              if (value.length < 6) {
                return 'Password troppo corta';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _registerNameController,
            decoration: const InputDecoration(
              labelText: 'Nome e cognome',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci il tuo nome';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _registerEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci la tua email';
              }
              if (!value.contains('@')) {
                return 'Email non valida';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _registerPhoneController,
            decoration: const InputDecoration(
              labelText: 'Telefono',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci il numero di telefono';
              }
              if (value.length < 7) {
                return 'Numero di telefono non valido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _registerPasswordController,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci una password';
              }
              if (value.length < 6) {
                return 'Password troppo corta';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServicesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isServicesValid)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Seleziona almeno un servizio per proseguire.',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        for (final category in _sortedCategories) ...[
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (category.description != null)
                    Text(
                      category.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  for (final service in _servicesForCategory(category.id))
                    CheckboxListTile(
                      value: _selectedServiceIds.contains(service.id),
                      onChanged: (value) {
                        _toggleServiceSelection(service, value ?? false);
                      },
                      title: Text(service.name),
                      subtitle: Text(
                        '${service.description} · ${service.durationMinutes} min · €${service.price.toStringAsFixed(0)}',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildStaffStep() {
    if (!_allowStaffSelection) {
      return const Text(
        'La scelta dell’operatore non è prevista. La prenotazione verrà assegnata automaticamente.',
      );
    }

    final eligibleStaff = _eligibleStaffForSelection();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isStaffValid)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Seleziona un operatore per proseguire.',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final staff in eligibleStaff)
              ChoiceChip(
                label: Text(staff.name),
                selected: _selectedStaff?.id == staff.id,
                onSelected: (_) => _updateStaffSelection(staff),
              ),
          ],
        ),
      ],
    );
  }

  List<StaffMember> _eligibleStaffForSelection() {
    if (_selectedServiceIds.isEmpty) return _staff;
    final requiredServiceIds = _selectedServiceIds;

    return _staff.where((staff) {
      final eligibleServices = _services
          .where((service) => service.eligibleStaffIds.contains(staff.id))
          .map((service) => service.id)
          .toSet();
      return requiredServiceIds.every(eligibleServices.contains);
    }).toList();
  }

  Widget _buildAvailabilityStep(DateTime? firstSlot) {
    if (!_isServicesValid) {
      return const Text('Seleziona prima i servizi.');
    }

    if (_allowStaffSelection && _selectedStaff == null) {
      return const Text('Seleziona prima un operatore.');
    }

    final selectedDate = _selectedDate;
    final duration = _totalDuration;
    final slots = selectedDate == null
        ? const <TimeOfDay>[]
        : _availableSlotsForDate(
            selectedDate,
            duration,
            _allowStaffSelection ? _selectedStaff : null,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (firstSlot != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Prima disponibilità: ${_formatDate(firstSlot)} alle ${_formatTime(TimeOfDay.fromDateTime(firstSlot))}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        Card(
          elevation: 0,
          child: CalendarDatePicker(
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 90)),
            initialDate: _selectedDate ?? DateTime.now(),
            onDateChanged: (date) {
              setState(() {
                _selectedDate = DateTime(date.year, date.month, date.day);
                _selectedTime = null;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Orari disponibili',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (selectedDate == null)
          const Text('Seleziona una data dal calendario.')
        else if (slots.isEmpty)
          const Text('Nessuna disponibilità per questa data.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in slots)
                ChoiceChip(
                  label: Text(_formatTime(slot)),
                  selected: _selectedTime == slot,
                  onSelected: (_) {
                    setState(() {
                      _selectedTime = slot;
                    });
                  },
                ),
            ],
          ),
        if (!_isAvailabilityValid)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Seleziona data e orario per proseguire.',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryStep() {
    final date = _selectedDate;
    final time = _selectedTime;
    final formattedDate = date != null ? _formatDate(date) : '-';
    final formattedTime = time != null ? _formatTime(time) : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cliente',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Text(_isRegistered
            ? _loginEmailController.text.trim()
            : _registerNameController.text.trim()),
        const SizedBox(height: 16),
        Text(
          'Servizi selezionati',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        for (final service in _selectedServices)
          Text('${service.name} · ${service.durationMinutes} min · €${service.price.toStringAsFixed(0)}'),
        const SizedBox(height: 12),
        Text('Durata totale: $_totalDuration min'),
        Text('Totale: €${_totalPrice.toStringAsFixed(0)}'),
        const SizedBox(height: 16),
        Text(
          'Operatore',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Text(_allowStaffSelection
            ? (_selectedStaff?.name ?? 'Non selezionato')
            : 'Assegnazione automatica'),
        const SizedBox(height: 16),
        Text(
          'Data e orario',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Text('$formattedDate alle $formattedTime'),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class ServiceCategory {
  final int id;
  final String name;
  final String? description;
  final int sortOrder;

  const ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
  });
}

class ServiceItem {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final int sortOrder;
  final List<int> eligibleStaffIds;

  const ServiceItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    this.sortOrder = 0,
    required this.eligibleStaffIds,
  });
}

class StaffMember {
  final int id;
  final String name;

  const StaffMember({
    required this.id,
    required this.name,
  });
}
