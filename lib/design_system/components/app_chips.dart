import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppChips<T> extends StatelessWidget {
  final List<T> items;
  final Set<T> selection;
  final ValueChanged<Set<T>> onChanged;
  final String Function(T) labelFor;
  final bool scrollable;

  const AppChips({
    super.key,
    required this.items,
    required this.selection,
    required this.onChanged,
    required this.labelFor,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    final chips = items.map((item) {
      final isOn = selection.contains(item);
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(100), // Píldora perfecta
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isOn
                  ? (oscuro ? const Color(0xFF203B2E) : const Color(0xFFE2EFE7)) // Verde M3 activo
                  : Colors.transparent, // Fondo transparente para los inactivos
              border: Border.all(
                color: isOn
                    ? Colors.transparent
                    : (oscuro ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)), // Contorno sutil
                width: 0.8,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              labelFor(item),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isOn
                    ? (oscuro ? const Color(0xFF81C784) : AppColors.primary) // Verde de texto activo
                    : (oscuro ? Colors.white70 : Colors.grey.shade700), // Texto gris/blanco atenuado inactivo
              ),
            ),
          ),
        ),
      );
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: chips,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 0,
      runSpacing: 8.0,
      children: chips,
    );
  }
}
