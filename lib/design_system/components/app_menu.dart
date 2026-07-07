import 'package:flutter/material.dart';

class AppMenu<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selection;
  final ValueChanged<T?> onChanged;
  final String Function(T) labelFor;
  final String placeholder;

  const AppMenu({
    super.key,
    required this.title,
    required this.items,
    required this.selection,
    required this.onChanged,
    required this.labelFor,
    this.placeholder = "Selecciona…",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                   ? Colors.grey.shade900 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              hint: Text(placeholder),
              value: selection,
              icon: const Icon(Icons.unfold_more, size: 20, color: Colors.grey),
              onChanged: onChanged,
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelFor(item)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
