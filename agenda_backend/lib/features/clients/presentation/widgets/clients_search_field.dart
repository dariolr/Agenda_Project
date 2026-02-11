import 'package:flutter/material.dart';

class ClientsSearchField extends StatefulWidget {
  final String hintText;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const ClientsSearchField({
    super.key,
    required this.hintText,
    this.initialValue = '',
    required this.onChanged,
  });

  @override
  State<ClientsSearchField> createState() => _ClientsSearchFieldState();
}

class _ClientsSearchFieldState extends State<ClientsSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant ClientsSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincronizza il controller se il valore iniziale cambia dall'esterno.
    // Evita di sovrascrivere mentre l'utente sta digitando (focus attivo),
    // altrimenti le risposte async della ricerca possono causare sfarfallio.
    if (_focusNode.hasFocus) return;
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (value) {
        widget.onChanged(value);
        setState(() {});
      },
    );
  }
}
