import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/estado_registro.dart';
import '../../../../core/services/especie_service.dart';
import '../../../../core/session/session_provider.dart';
import '../../../../data/models/especie.dart';
import '../../../../design_system/components/app_chips.dart';
import '../wizard_provider.dart';
import 'step_widgets.dart';

/// R-04: identificación. Autocompleta contra el catálogo validado y rellena
/// el autor con el usuario actual. Espejo de `IdentificacionStep` (iOS).
class IdentificacionStep extends ConsumerStatefulWidget {
  const IdentificacionStep({super.key, required this.args});

  final WizardArgs args;

  @override
  ConsumerState<IdentificacionStep> createState() => _IdentificacionStepState();
}

class _IdentificacionStepState extends ConsumerState<IdentificacionStep> {
  static const _paises = [
    'Perú', 'Brasil', 'Bolivia', 'Ecuador', 'Colombia',
    'Venezuela', 'Guyana', 'Surinam',
  ];

  /// Espera antes de recargar el catálogo desde el backend al teclear.
  static const _debounce = Duration(milliseconds: 500);

  late final TextEditingController _nombre;
  late final TextEditingController _autor;
  late final TextEditingController _familia;
  late final TextEditingController _nombreLocal;

  List<Especie> _sugerencias = [];
  List<String> _sugerenciasFamilia = [];

  /// Cuando el nombre científico viene del catálogo, la familia se autocompleta
  /// y queda bloqueada.
  bool _familiaBloqueada = false;

  Timer? _debounceTimer;

  WizardNotifier get _wizard => ref.read(wizardProvider(widget.args).notifier);

  @override
  void initState() {
    super.initState();
    final draft = ref.read(wizardProvider(widget.args)).draft;
    _nombre = TextEditingController(text: draft.nombreCientifico);
    _autor = TextEditingController(text: draft.autorNombre);
    _familia = TextEditingController(text: draft.familia);
    _nombreLocal = TextEditingController(text: draft.nombreLocal);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final especies = ref.read(especieServiceProvider).especies;
      final bloqueada = draft.nombreCientifico.isNotEmpty &&
          especies.any((e) => e.nombreCientifico == draft.nombreCientifico);

      // Autor por defecto: el usuario con el que se creó la cuenta.
      if (draft.autorNombre.isEmpty) {
        final nombre = ref.read(sessionProvider).usuario?.nombreCompleto ?? '';
        _autor.text = nombre;
        _wizard.editar((d) => d.autorNombre = nombre);
      }
      setState(() => _familiaBloqueada = bloqueada);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nombre.dispose();
    _autor.dispose();
    _familia.dispose();
    _nombreLocal.dispose();
    super.dispose();
  }

  /// Filtra el catálogo ya cargado y, tras el debounce, lo refresca del backend
  /// por si el validador aprobó especies nuevas.
  void _actualizarSugerencias(String q) {
    _wizard.editar((d) => d.nombreCientifico = q);

    // Al escribir a mano se pierde la familia autocompletada.
    if (_familiaBloqueada) setState(() => _familiaBloqueada = false);

    if (q.length < 2) {
      setState(() => _sugerencias = []);
      return;
    }
    setState(() => _sugerencias = _buscarEspecies(q));

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () async {
      await ref.read(especieServiceProvider.notifier).cargar();
      if (mounted) setState(() => _sugerencias = _buscarEspecies(q));
    });
  }

  List<Especie> _buscarEspecies(String q) {
    final lower = q.toLowerCase();
    return ref
        .read(especieServiceProvider)
        .especies
        .where((e) =>
            e.estado == EstadoRegistro.validado &&
            e.nombreCientifico.toLowerCase().contains(lower))
        .take(5)
        .toList();
  }

  void _actualizarSugerenciasFamilia(String q) {
    _wizard.editar((d) => d.familia = q);
    if (q.length < 2) {
      setState(() => _sugerenciasFamilia = []);
      return;
    }
    setState(() => _sugerenciasFamilia = _buscarFamilias(q));

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () async {
      await ref.read(especieServiceProvider.notifier).cargar();
      if (mounted) setState(() => _sugerenciasFamilia = _buscarFamilias(q));
    });
  }

  List<String> _buscarFamilias(String q) {
    final lower = q.toLowerCase();
    final familias = ref
        .read(especieServiceProvider)
        .especies
        .where((e) => e.estado == EstadoRegistro.validado)
        .map((e) => e.familia)
        .toSet()
        .where((f) => f.toLowerCase().contains(lower))
        .toList()
      ..sort();
    return familias.take(5).toList();
  }

  void _seleccionar(Especie e) {
    _debounceTimer?.cancel(); // Previene que el timer re-muestre las sugerencias.
    
    _nombre.text = e.nombreCientifico;
    _familia.text = e.familia;
    
    _wizard.editar((d) {
      d.catalogId = e.id;
      d.nombreCientifico = e.nombreCientifico;
      // No tocamos d.autorNombre para que conserve el nombre del usuario
      d.familia = e.familia;
    });
    setState(() {
      _familiaBloqueada = true;
      _sugerencias = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(wizardProvider(widget.args)).draft;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(20),
      children: [
        const StepHeader(
          titulo: 'Taxonomía',
          detalle: 'Si el nombre científico está en el catálogo, la familia se '
              'autocompleta y queda bloqueada.',
        ),
        const SizedBox(height: 16),
        CampoTexto(
          titulo: 'Nombre científico *',
          hint: 'Ej.: Cedrela odorata',
          controller: _nombre,
          capitalization: TextCapitalization.words,
          onChanged: _actualizarSugerencias,
        ),
        for (final e in _sugerencias)
          ListTile(
            dense: true,
            leading: const Icon(Icons.eco_outlined),
            title: Text(e.nombreCientifico,
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
            subtitle: Text(e.familia, style: theme.textTheme.bodySmall),
            trailing: const Icon(Icons.north_west, size: 14),
            onTap: () => _seleccionar(e),
          ),
        const SizedBox(height: 12),
        CampoTexto(
          titulo: 'Autor',
          hint: 'Tu nombre',
          controller: _autor,
          onChanged: (v) => _wizard.editar((d) => d.autorNombre = v),
        ),
        const SizedBox(height: 12),
        CampoTexto(
          titulo: _familiaBloqueada ? 'Familia (auto)' : 'Familia *',
          hint: 'Ej.: Meliaceae',
          controller: _familia,
          enabled: !_familiaBloqueada,
          sufijo: _familiaBloqueada ? const Icon(Icons.lock, size: 16) : null,
          onChanged: _actualizarSugerenciasFamilia,
        ),
        for (final f in _sugerenciasFamilia)
          ListTile(
            dense: true,
            title: Text(f, style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.north_west, size: 14),
            onTap: () {
              _familia.text = f;
              _wizard.editar((d) => d.familia = f);
              setState(() => _sugerenciasFamilia = []);
            },
          ),
        const SizedBox(height: 24),
        Text('Detalle', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        CampoTexto(
          titulo: 'Nombre local *',
          hint: 'Ej.: Cedro',
          controller: _nombreLocal,
          onChanged: (v) => _wizard.editar((d) => d.nombreLocal = v),
        ),
        const SizedBox(height: 24),
        Text('Distribución por países *', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text('Marca todos los países donde se ha reportado la especie.',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        AppChips<String>(
          items: _paises,
          selection: draft.distribucionPaises.toSet(),
          labelFor: (p) => p,
          onChanged: (nuevos) =>
              _wizard.editar((d) => d.distribucionPaises = nuevos.toList()),
        ),
      ],
    );
  }
}
