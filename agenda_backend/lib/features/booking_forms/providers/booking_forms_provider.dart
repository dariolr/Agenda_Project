import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../data/booking_forms_repository.dart';
import '../domain/booking_form_models.dart';
import '../domain/customer_form_submission.dart';

final bookingFormsRepositoryProvider = Provider<BookingFormsRepository>((ref) {
  return BookingFormsRepository(ref.watch(apiClientProvider));
});

final bookingFormsProvider = FutureProvider<List<BookingForm>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return [];
  return ref.watch(bookingFormsRepositoryProvider).list(businessId);
});

/// Risposte ai moduli per-cliente di un cliente (sola lettura, scheda cliente).
final clientFormSubmissionsProvider =
    FutureProvider.family<List<CustomerFormSubmission>, int>((ref, clientId) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0 || clientId <= 0) return [];
  return ref.watch(bookingFormsRepositoryProvider).getClientForms(
        businessId,
        clientId,
      );
});
