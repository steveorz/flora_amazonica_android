import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/habito.dart';
import '../../../../core/utils/dasometria.dart';
import '../../../../data/models/foto.dart';
import '../wizard_provider.dart';
import 'step_widgets.dart' show StepHeader;

/// R-13: resumen previo al envío. "Editar" salta al paso correspondiente.
/// Espejo de `ResumenStep` (iOS).
class ResumenStep extends ConsumerWidget {
  const ResumenStep({super.key, required this.args});

  final WizardArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(wizardProvider(args));
    final wizard = ref.read(wizardProvider(args).notifier);
    final theme = Theme.of(context);
    final d = estado.draft;
    final daso = d.datosDasometricos;
    final ubicacion = d.ubicacion;

    // La dasometría sólo se resume si aplica al hábito y fue medida.
    final mostrarDaso =
        daso != null && (d.habito == Habito.arbol || d.habito == Habito.palmera);

    final caracteres = d.caracteres.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const StepHeader(
          titulo: 'Resumen',
          detalle: 'Revisa todo antes de enviar al validador.',
        ),
        const SizedBox(height: 14),
        _Seccion(
          titulo: 'Identificación',
          onEditar: () => wizard.irA(1),
          filas: [
            ('Nombre', d.nombreCientifico, true),
            ('Autor', d.autorNombre, false),
            ('Familia', d.familia, false),
            ('Nombre local', d.nombreLocal, false),
            ('Distribución', d.distribucionPaises.join(', '), false),
          ],
        ),
        _Seccion(
          titulo: 'Hábito',
          onEditar: () => wizard.irA(2),
          filas: [
            ('Hábito', d.habito?.label ?? '—', false),
            ('Tipo de vida', d.tipoVida?.label ?? '—', false),
          ],
        ),
        if (mostrarDaso)
          _Seccion(
            titulo: 'Dasométricos',
            onEditar: () => wizard.irA(3),
            filas: [
              ('Altura', '${Dasometria.formato(daso.altura)} m', false),
              ('CAP', '${Dasometria.formato(daso.cap)} cm', false),
              if (d.habito == Habito.arbol)
                ('DAP', '${Dasometria.formato(daso.dap)} cm', false),
            ],
          ),
        if (caracteres.isNotEmpty)
          _Seccion(
            titulo: 'Caracteres morfológicos',
            onEditar: () => wizard.irA(3),
            filas: [
              for (final e in caracteres) (_capitalizar(e.key), e.value, false),
            ],
          ),
        if (ubicacion != null)
          _Seccion(
            titulo: 'Ubicación',
            onEditar: () => wizard.irA(4),
            filas: [
              (
                'Coordenadas',
                '${ubicacion.lat.toStringAsFixed(4)}, ${ubicacion.long.toStringAsFixed(4)}',
                false
              ),
              ('Hábitat', ubicacion.tipoHabitat, false),
              if (ubicacion.referencia.isNotEmpty)
                ('Referencia', ubicacion.referencia, false),
            ],
          ),
        _Seccion(
          titulo: 'Fotos',
          onEditar: () => wizard.irA(5),
          filas: [
            ('Capturadas', '${d.fotosCapturadas.length} de ${TipoFoto.values.length}', false),
          ],
          child: d.fotosCapturadas.isNotEmpty
              ? SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: d.fotosCapturadas.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tipo = d.fotosCapturadas.elementAt(index);
                      final bytes = estado.fotoData[tipo];
                      if (bytes == null) return const SizedBox.shrink();
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          bytes,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (estado.errorEnvio != null) ...[
          const SizedBox(height: 8),
          Text(estado.errorEnvio!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }

  static String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.onEditar, this.filas = const [], this.child});

  final String titulo;
  final VoidCallback onEditar;
  final Widget? child;

  /// (etiqueta, valor, en cursiva)
  final List<(String, String, bool)> filas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                titulo,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 32,
                child: TextButton(
                  onPressed: onEditar,
                  style: TextButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Editar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final (etiqueta, valor, cursiva) in filas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      etiqueta,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      valor.isEmpty ? '—' : valor,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontStyle: cursiva ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (child != null) ...[
            if (filas.isNotEmpty) const SizedBox(height: 8),
            child!,
          ],
        ],
      ),
    );
  }
}
