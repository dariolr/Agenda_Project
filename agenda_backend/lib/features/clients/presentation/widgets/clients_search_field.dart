import 'package:flutter/material.dart';

class ClientsSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const ClientsSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}
