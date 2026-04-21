import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/appointment_type_filter_option.dart';

class ServicesAppointmentTypeFilterNotifier
    extends Notifier<AppointmentTypeFilterOption> {
  @override
  AppointmentTypeFilterOption build() => AppointmentTypeFilterOption.all;

  void set(AppointmentTypeFilterOption option) => state = option;
}

final servicesAppointmentTypeFilterProvider =
    NotifierProvider<
      ServicesAppointmentTypeFilterNotifier,
      AppointmentTypeFilterOption
    >(ServicesAppointmentTypeFilterNotifier.new);
