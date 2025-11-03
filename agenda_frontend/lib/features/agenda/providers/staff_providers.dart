import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff.dart';

final staffProvider = Provider<List<Staff>>((ref) {
  return [
    Staff(id: 1, name: 'Dario', surname: 'La Rosa', color: Colors.green),
    Staff(id: 2, name: 'Luca', surname: 'Bianchi', color: Colors.cyan),
    Staff(id: 3, name: 'Sara', surname: 'Verdi', color: Colors.orange),
    Staff(id: 4, name: 'Alessia', surname: 'Neri', color: Colors.pinkAccent),
    Staff(id: 5, name: 'Luisa', surname: 'Gialli', color: Colors.purpleAccent),
  ];
});
