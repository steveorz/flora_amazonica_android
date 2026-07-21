import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/rol.dart';
import '../../core/services/usuario_service.dart';
import '../../data/models/usuario.dart';
import '../../design_system/components/app_button.dart';
import 'rol_sheets.dart';

/// AM-03: detalle de un usuario y acciones del administrador.
/// Espejo de `UsuarioDetalleView` (iOS).
class UsuarioDetalleScreen extends ConsumerWidget {
  const UsuarioDetalleScreen({super.key, required this.usuarioId});

  final String usuarioId;

  void _aviso(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Activar implica dos llamadas: asignar el rol y poner la cuenta activa.
  Future<void> _activar(BuildContext context, WidgetRef ref, Usuario u, Rol rol) async {
    final servicio = ref.read(usuarioServiceProvider.notifier);
    try {
      if (rol != u.rol) await servicio.actualizarRol(u.id, rol);
      await servicio.actualizarEstado(u.id, EstadoUsuario.activo);
      if (context.mounted) {
        Navigator.of(context).pop();
        _aviso(context, 'Cuenta activada como ${rol.label}.');
      }
    } catch (e) {
      if (context.mounted) _aviso(context, 'No se pudo activar la cuenta.');
    }
  }

  Future<void> _cambiarRol(BuildContext context, WidgetRef ref, Usuario u, Rol rol) async {
    try {
      await ref.read(usuarioServiceProvider.notifier).actualizarRol(u.id, rol);
      if (context.mounted) {
        Navigator.of(context).pop();
        _aviso(context, 'Rol actualizado a ${rol.label}.');
      }
    } catch (e) {
      if (context.mounted) _aviso(context, 'No se pudo cambiar el rol.');
    }
  }

  Future<void> _cambiarEstado(
    BuildContext context,
    WidgetRef ref,
    Usuario u,
    EstadoUsuario nuevo,
  ) async {
    try {
      await ref.read(usuarioServiceProvider.notifier).actualizarEstado(u.id, nuevo);
      if (context.mounted) _aviso(context, 'Cuenta ${nuevo.name}.');
    } catch (e) {
      if (context.mounted) _aviso(context, 'No se pudo actualizar la cuenta.');
    }
  }

  Future<bool> _confirmar(BuildContext context, String titulo, String accion) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(accion, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  void _abrirHoja(BuildContext context, Widget hoja) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => hoja,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Se lee del estado global para que la pantalla reaccione a los cambios.
    final u = ref.watch(usuarioServiceProvider.select(
      (s) => s.usuarios.where((x) => x.id == usuarioId).firstOrNull,
    ));

    if (u == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Usuario no encontrado.')),
      );
    }

    final f = u.fechaRegistro;

    return Scaffold(
      appBar: AppBar(title: Text('Detalle de usuario', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(u.iniciales,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(u.nombreCompleto, style: theme.textTheme.headlineSmall),
                Text(u.email,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Ficha(filas: [
            ('Rol', u.rol.label),
            ('Estado', u.estado.name),
            ('DNI', u.dni),
            ('Institución', u.institucion),
            ('Cargo', u.cargo),
            ('Registro', '${f.day}/${f.month}/${f.year}'),
          ]),
          const SizedBox(height: 24),
          ..._acciones(context, ref, u),
        ],
      ),
    );
  }

  List<Widget> _acciones(BuildContext context, WidgetRef ref, Usuario u) {
    switch (u.estado) {
      case EstadoUsuario.pendiente:
        return [
          SizedBox(
            width: double.infinity,
            child: AppButton(
              title: 'Activar y asignar rol',
              systemImage: Icons.check_circle,
              variant: AppButtonVariant.atencion,
              action: () => _abrirHoja(
                context,
                ActivarUsuarioSheet(
                  usuario: u,
                  onConfirmar: (rol) => _activar(context, ref, u, rol),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              title: 'Rechazar cuenta',
              systemImage: Icons.cancel_outlined,
              variant: AppButtonVariant.destructivo,
              action: () async {
                if (await _confirmar(context, '¿Rechazar esta cuenta?', 'Rechazar') &&
                    context.mounted) {
                  await _cambiarEstado(context, ref, u, EstadoUsuario.inactivo);
                }
              },
            ),
          ),
        ];

      case EstadoUsuario.activo:
        return [
          SizedBox(
            width: double.infinity,
            child: AppButton(
              title: 'Cambiar rol',
              systemImage: Icons.manage_accounts,
              variant: AppButtonVariant.secundario,
              action: () => _abrirHoja(
                context,
                CambiarRolSheet(
                  usuario: u,
                  onConfirmar: (rol) => _cambiarRol(context, ref, u, rol),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              title: 'Desactivar',
              systemImage: Icons.person_off,
              variant: AppButtonVariant.destructivo,
              action: () async {
                if (await _confirmar(context, '¿Desactivar a este usuario?', 'Desactivar') &&
                    context.mounted) {
                  await _cambiarEstado(context, ref, u, EstadoUsuario.inactivo);
                }
              },
            ),
          ),
        ];

      case EstadoUsuario.inactivo:
        return [
          SizedBox(
            width: double.infinity,
            child: AppButton(
              title: 'Reactivar cuenta',
              systemImage: Icons.restart_alt,
              variant: AppButtonVariant.atencion,
              action: () => _cambiarEstado(context, ref, u, EstadoUsuario.activo),
            ),
          ),
        ];
    }
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({required this.filas});
  final List<(String, String)> filas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (final (etiqueta, valor) in filas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(etiqueta,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  Expanded(
                    child: Text(valor.isEmpty ? '—' : valor,
                        textAlign: TextAlign.right, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
