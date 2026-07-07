import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class AppRadioGroup<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selection;
  final ValueChanged<T> onChanged;
  final String Function(T) labelFor;

  const AppRadioGroup({
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
          final isSelected = selection == item;
          return InkWell(
            onTap: () => onChanged(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? BrandColors.brandPrimary : Colors.grey,
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
