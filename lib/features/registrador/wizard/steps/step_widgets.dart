import 'package:flutter/material.dart';

/// Cabecera de un paso del wizard: título grande y una línea de ayuda.
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.titulo, this.detalle});

  final String titulo;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        if (detalle != null) ...[
          const SizedBox(height: 4),
          Text(detalle!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

/// Fila de formulario: etiqueta pequeña arriba, campo debajo
/// (el estilo de los formularios agrupados de iOS).
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.titulo,
    required this.controller,
    required this.onChanged,
    this.hint = '',
    this.enabled = true,
    this.lineas = 1,
    this.capitalization = TextCapitalization.sentences,
    this.keyboardType,
    this.sufijo,
    this.unidad,
  });

  final String titulo;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final int lineas;
  final TextCapitalization capitalization;
  final TextInputType? keyboardType;
  final Widget? sufijo;

  /// Unidad mostrada al final del campo (m, cm…), como `kind: .numericWithUnit`.
  final String? unidad;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      maxLines: lineas,
      minLines: 1,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      decoration: InputDecoration(
        labelText: titulo.isNotEmpty ? titulo : null,
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
        suffixIcon: sufijo,
        suffixText: unidad,
      ),
    );
  }
}

/// Acordeón con el estilo de `DisclosureGroup` sobre `secondarySystemBackground`.
class Acordeon extends StatelessWidget {
  const Acordeon({
    super.key,
    required this.titulo,
    required this.expandido,
    required this.onToggle,
    required this.child,
  });

  final String titulo;
  final bool expandido;
  final ValueChanged<bool> onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        // Quita las líneas divisorias por defecto del ExpansionTile.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expandido,
          onExpansionChanged: onToggle,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(titulo, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [child],
        ),
      ),
    );
  }
}
