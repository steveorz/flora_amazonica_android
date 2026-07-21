import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/app_preferences.dart';
import '../../core/session/connectivity_store.dart';

/// C-12: configuración de la app (notificaciones, tema, idioma, caché, acerca de).
/// Espejo de `ConfiguracionView` (iOS).
class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  Future<void> _confirmarLimpiarCache(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Limpiar caché?'),
        content: const Text('Se borrarán tus borradores y favoritos guardados en el dispositivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    await ref.read(preferenciasProvider.notifier).limpiarCache();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Caché limpia.')));
    }
  }

  void _acercaDe(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FlorAmaz',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Catálogo de flora amazónica.\nUNAP — FISI',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(preferenciasProvider);
    final notifier = ref.read(preferenciasProvider.notifier);
    final conectividad = ref.watch(conectividadProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          _Encabezado('Notificaciones'),
          SwitchListTile(
            title: const Text('Recibir notificaciones'),
            value: prefs.notificacionesActivas,
            onChanged: notifier.setNotificaciones,
          ),
          _Nota('Te avisamos cuando cambie el estado de tus registros o tu cuenta.'),

          _Encabezado('Apariencia'),
          for (final t in Tema.values)
            RadioListTile<Tema>(
              value: t,
              groupValue: prefs.tema,
              onChanged: (v) => notifier.setTema(v!),
              title: Text(t.label),
            ),

          _Encabezado('Idioma'),
          for (final i in Idioma.values)
            RadioListTile<Idioma>(
              value: i,
              groupValue: prefs.idioma,
              onChanged: (v) => notifier.setIdioma(v!),
              title: Text(i.label),
            ),
          _Nota('La traducción completa al inglés llegará en una próxima versión.'),

          _Encabezado('Datos'),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Limpiar caché', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmarLimpiarCache(context, ref),
          ),

          // Sólo en debug: permite probar los estados offline de la UI.
          if (kDebugMode) ...[
            _Encabezado('Simulación de red'),
            SwitchListTile(
              title: const Text('Conexión a internet'),
              value: conectividad.online,
              onChanged: (activo) =>
                  ref.read(conectividadProvider.notifier).forzarOffline(!activo),
            ),
            if (!conectividad.online)
              _Nota('Las acciones quedarán en cola y se enviarán al volver la conexión.'),
          ],

          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de FlorAmaz'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _acercaDe(context),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('FlorAmaz 1.0.0', style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(texto.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          )),
    );
  }
}

class _Nota extends StatelessWidget {
  const _Nota(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Text(texto,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}
