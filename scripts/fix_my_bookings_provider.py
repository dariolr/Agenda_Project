#!/usr/bin/env python3
"""
Script per fixare il bug critico in my_bookings_provider.dart
dove il business name viene preso dal provider URL invece che dalla response API.
"""

import os
import sys

FILE_PATH = '/Users/dariolarosa/Documents/Romeo_lab/Agenda_Project/agenda_frontend/lib/features/booking/providers/my_bookings_provider.dart'

def main():
    # Leggo il file
    with open(FILE_PATH, 'r') as f:
        content = f.read()

    # 1. Rimuovo l'import di business_provider che non serve più
    content = content.replace(
        "import '/features/booking/providers/business_provider.dart';\n", 
        ""
    )

    # 2. Rimuovo tutte le righe che leggono businessName dal provider
    old_line = "final businessName = ref.read(currentBusinessProvider).value?.name ?? '';"
    content = content.replace("      " + old_line + "\n", "")

    # 3. Rimuovo il parametro businessName dalla firma di _fromCustomerBooking
    content = content.replace("  required String businessName,\n", "")

    # 4. Rimuovo businessName: businessName, dalle chiamate a _fromCustomerBooking
    content = content.replace(
        "              businessName: businessName,\n",
        ""
    )
    content = content.replace(
        "        businessName: businessName,\n",
        ""
    )

    # 5. Nella funzione _fromCustomerBooking, modifico l'estrazione di locationName
    # e aggiungo l'estrazione di businessName dal JSON
    old_location = """  final locationName =
      locationNames[locationId] ?? (json['location_name'] as String? ?? '');"""

    new_location = """  // FIX BUG CRITICO: usa location_name dalla response API invece che dal provider
  // Il provider locationNames puo essere vuoto o riferirsi al business corrente dell'URL
  final locationName =
      json['location_name'] as String? ?? locationNames[locationId] ?? '';

  // FIX BUG CRITICO: usa business_name dalla response API invece che dal provider URL
  // Questo evita di mostrare il nome del business sbagliato quando l'utente
  // naviga su un business diverso da quello delle sue prenotazioni
  final businessName = json['business_name'] as String? ?? '';"""

    content = content.replace(old_location, new_location)

    # Scrivo il file
    with open(FILE_PATH, 'w') as f:
        f.write(content)

    print("File modificato con successo!")
    
    # Verifico
    print("\nPrime 15 righe:")
    with open(FILE_PATH, 'r') as f:
        for i, line in enumerate(f):
            if i < 15:
                print(f"{i+1}: {line.rstrip()}")

if __name__ == '__main__':
    main()
