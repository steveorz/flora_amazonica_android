import 'package:flutter/material.dart';

import '../../core/constants/rol.dart';
import '../../data/models/usuario.dart';
import '../../design_system/components/app_button.dart';

/// Qué puede hacer cada rol. Se muestra al asignarlo, para que el admin
/// entienda las consecuencias.
String descripcionRol(Rol r) => switch (r) {
      Rol.registrador => 'Podrá registrar nuevas especies desde la app móvil.',
      Rol.consultor => 'Solo podrá consultar el catálogo y guardar favoritos.',
      Rol.administrador => 'Tendrá control sobre cuentas y el catálogo base.',
      Rol.validador => 'Solo desde el panel web.',
    };

/// El validador no se asigna desde la app: trabaja únicamente en el panel web.
final rolesElegibles = Rol.values.where((r) => r != Rol.validador).toList();

/// AM-04: hoja modal para activar un usuario asignándole un rol.
/// Espejo de `ActivarUsuarioSheet` (iOS).
class ActivarUsuarioSheet extends StatefulWidget {
  const ActivarUsuarioSheet({super.key, required this.usuario, required this.onConfirmar});

  final Usuario usuario;
  final Future<void> Function(Rol) onConfirmar;

  @override
  State<ActivarUsuarioSheet> createState() => _ActivarUsuarioSheetState();
}

class _ActivarUsuarioSheetState extends State<ActivarUsuarioSheet> {
  late Rol _rol = widget.usuario.rol;
  bool _enviando = false;

  Future<void> _confirmar() async {
    setState(() => _enviando = true);
    try {
      await widget.onConfirmar(_rol);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Agarradera(),
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 32,
              child: Text(widget.usuario.iniciales,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Text(widget.usuario.nombreCompleto, style: theme.textTheme.titleLarge),
            Text(widget.usuario.email,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asignar rol', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Define qué podrá hacer esta persona en FlorAmaz.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final r in rolesElegibles)
              RadioListTile<Rol>(
                value: r,
                groupValue: _rol,
                onChanged: _enviando ? null : (v) => setState(() => _rol = v!),
                title: Text(r.label),
                subtitle: Text(descripcionRol(r), style: theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                title: _enviando ? 'Activando…' : 'Activar y notificar',
                systemImage: _enviando ? null : Icons.check_circle,
                variant: AppButtonVariant.atencion,
                enabled: !_enviando,
                action: _confirmar,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                title: 'Cancelar',
                variant: AppButtonVariant.terciario,
                action: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AM-05: hoja modal para cambiar el rol de un usuario ya activo.
/// Espejo de `CambiarRolSheet` (iOS).
class CambiarRolSheet extends StatefulWidget {
  const CambiarRolSheet({super.key, required this.usuario, required this.onConfirmar});

  final Usuario usuario;
  final Future<void> Function(Rol) onConfirmar;

  @override
  State<CambiarRolSheet> createState() => _CambiarRolSheetState();
}

class _CambiarRolSheetState extends State<CambiarRolSheet> {
  late Rol _rol = widget.usuario.rol;
  bool _enviando = false;

  Future<void> _confirmar() async {
    setState(() => _enviando = true);
    try {
      await widget.onConfirmar(_rol);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Agarradera(),
            const SizedBox(height: 18),
            Text('Cambiar rol', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Rol actual: ${widget.usuario.rol.label}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            SegmentedButton<Rol>(
              segments: [
                for (final r in rolesElegibles) ButtonSegment(value: r, label: Text(r.label)),
              ],
              selected: {_rol},
              showSelectedIcon: false,
              onSelectionChanged: _enviando ? null : (s) => setState(() => _rol = s.first),
            ),
            const SizedBox(height: 14),
            Text(descripcionRol(_rol),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                title: _enviando ? 'Guardando…' : 'Guardar y notificar',
                systemImage: _enviando ? null : Icons.check_circle,
                variant: AppButtonVariant.atencion,
                // No tiene sentido "cambiar" al mismo rol que ya tiene.
                enabled: !_enviando && _rol != widget.usuario.rol,
                action: _confirmar,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                title: 'Cancelar',
                variant: AppButtonVariant.terciario,
                action: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Agarradera extends StatelessWidget {
  const _Agarradera();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}
