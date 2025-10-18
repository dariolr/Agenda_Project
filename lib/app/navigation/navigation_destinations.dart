import 'package:flutter/material.dart';

enum AppSection { agenda, clients, settings }

extension AppSectionData on AppSection {
  String get label {
    switch (this) {
      case AppSection.agenda:
        return 'Agenda';
      case AppSection.clients:
        return 'Clienti';
      case AppSection.settings:
        return 'Impostazioni';
    }
  }

  IconData get icon {
    switch (this) {
      case AppSection.agenda:
        return Icons.calendar_today_outlined;
      case AppSection.clients:
        return Icons.people_outline;
      case AppSection.settings:
        return Icons.settings_outlined;
    }
  }

  String get route {
    switch (this) {
      case AppSection.agenda:
        return '/agenda';
      case AppSection.clients:
        return '/clients';
      case AppSection.settings:
        return '/settings';
    }
  }
}
