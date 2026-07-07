import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class AppChips<T> extends StatelessWidget {
  final List<T> items;
  final Set<T> selection;
  final ValueChanged<Set<T>> onChanged;
  final String Function(T) labelFor;

  const AppChips({
    super.key,
    required this.items,
    required this.selection,
    required this.onChanged,
    required this.labelFor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: items.map((item) {
        final isOn = selection.contains(item);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final newSelection = Set<T>.from(selection);
            if (isOn) {
              newSelection.remove(item);
            } else {
              newSelection.add(item);
            }
            onChanged(newSelection);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isOn 
                  ? BrandColors.brandPrimary 
                  : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              labelFor(item),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isOn ? BrandColors.onBrand : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
