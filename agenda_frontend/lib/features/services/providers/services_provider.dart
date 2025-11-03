import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/utils/color_utils.dart';

class ServicesNotifier extends Notifier<List<Service>> {
  bool _initialized = false;

  @override
  List<Service> build() {
    if (!_initialized) {
      _initialized = true;
      state = _mockServices();
    }
    return state;
  }

  List<Service> _mockServices() {
    return [
      Service(
        id: 1,
        name: 'service name',
        duration: 25,
        price: 45,
        color: ColorUtils.fromHex('#6EC5A6'),
      ),
      Service(
        id: 2,
        name: 'second service',
        duration: 30,
        price: 35,
        color: ColorUtils.fromHex('#57A0D3'),
      ),
      Service(
        id: 3,
        name: 'third service',
        duration: 45,
        price: 60,
        color: ColorUtils.fromHex('#F4B942'),
      ),
    ];
  }

  void setServices(List<Service> services) {
    state = services;
  }
}

final servicesProvider =
    NotifierProvider<ServicesNotifier, List<Service>>(ServicesNotifier.new);

final serviceColorByNameProvider =
    Provider.family<Color?, String>((ref, serviceName) {
  if (serviceName.isEmpty) return null;
  final services = ref.watch(servicesProvider);
  for (final service in services) {
    if (service.name == serviceName) {
      return service.color;
    }
  }
  return null;
});
