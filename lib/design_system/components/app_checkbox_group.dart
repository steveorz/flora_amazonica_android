import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class AppCheckboxGroup<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final Set<T> selection;
  final ValueChanged<Set<T>> onChanged;
  final String Function(T) labelFor;

  const AppCheckboxGroup({
    super.key,
    required this.title,
    required this.items,
    required this.selection,
    required this.onChanged,
    required this.labelFor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
        ...items.map((item) {
          final isOn = selection.contains(item);
          return InkWell(
            onTap: () {
              final newSelection = Set<T>.from(selection);
              if (isOn) {
                newSelection.remove(item);
              } else {
                newSelection.add(item);
              }
              onChanged(newSelection);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    isOn ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isOn ? BrandColors.brandPrimary : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    labelFor(item),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
