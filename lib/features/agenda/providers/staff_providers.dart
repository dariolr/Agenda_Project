import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff.dart';

final staffProvider = Provider<List<Staff>>((ref) {
  return [
    Staff(id: 1, name: 'Mario', color: Colors.green),
    Staff(id: 2, name: 'Luca', color: Colors.cyan),
    Staff(id: 3, name: 'Sara', color: Colors.orange),
    Staff(id: 4, name: 'Alessia', color: Colors.pinkAccent),
    Staff(id: 5, name: 'Luisa', color: Colors.purpleAccent),
  ];
});
