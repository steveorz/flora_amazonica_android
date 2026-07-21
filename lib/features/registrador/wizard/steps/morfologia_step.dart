import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/habito.dart';
import '../../../../core/utils/dasometria.dart';
import '../../../../data/models/campo_morfologico.dart';
import '../../../../data/models/datos_dasometricos.dart';
import '../wizard_provider.dart';
import 'step_widgets.dart';

/// R-06 a R-10: morfología por hábito, con acordeones y el formulario dinámico
/// que define el backend. Espejo de `MorfologiaStep` (iOS).
class MorfologiaStep extends ConsumerStatefulWidget {
  const MorfologiaStep({super.key, required this.args});

  final WizardArgs args;

  @override
  ConsumerState<MorfologiaStep> createState() => _MorfologiaStepState();
}

class _MorfologiaStepState extends ConsumerState<MorfologiaStep> {
  /// Secciones abiertas. La dasometría arranca desplegada.
  final Set<String> _expandidas = {'dasometricos'};
  bool _inicializoPrimeraSeccion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarCampos());
  }

  Future<void> _cargarCampos() async {
    final habito = ref.read(wizardProvider(widget.args)).draft.habito;
    if (habito != null) {
      await ref.read(wizardProvider(widget.args).notifier).cargarCamposDinamicos(habito);
    }
  }

  /// Sólo árboles y palmeras llevan dasometría.
  bool _aplicaDasometria(Habito? h) => h == Habito.arbol || h == Habito.palmera;

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(wizardProvider(widget.args));
    final theme = Theme.of(context);
    final habito = estado.draft.habito;

    if (estado.cargandoCampos) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Cargando formulario…'),
          ],
        ),
      );
    }

    if (estado.errorCampos != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(estado.errorCampos!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _cargarCampos, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    // Agrupar los campos dinámicos por sección, en orden alfabético.
    final secciones = <String, List<CampoMorfologico>>{};
    for (final campo in estado.camposDinamicos) {
      secciones.putIfAbsent(campo.seccion, () => []).add(campo);
    }
    final nombresSecciones = secciones.keys.toList()..sort();

    // La primera sección aparece abierta la primera vez que hay campos.
    if (!_inicializoPrimeraSeccion && nombresSecciones.isNotEmpty) {
      _inicializoPrimeraSeccion = true;
      _expandidas.add(nombresSecciones.first);
    }

    return RefreshIndicator(
      onRefresh: _cargarCampos,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StepHeader(
            titulo: 'Morfología',
            detalle: habito != null ? 'Características de ${habito.label.toLowerCase()}.' : null,
          ),
          const SizedBox(height: 16),
          Text('Dasometría', style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),
          if (_aplicaDasometria(habito))
            Acordeon(
              titulo: 'Datos dasométricos',
              expandido: _expandidas.contains('dasometricos'),
              onToggle: (abierto) => setState(() =>
                  abierto ? _expandidas.add('dasometricos') : _expandidas.remove('dasometricos')),
              child: _FormularioDasometrico(args: widget.args),
            )
          else
            Text(
              'Los datos dasométricos no aplican para el hábito seleccionado.',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 16),
          if (nombresSecciones.isEmpty)
            Text('No se encontraron campos dinámicos para este hábito.',
                style: theme.textTheme.bodyMedium)
          else
            for (final seccion in nombresSecciones)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Acordeon(
                  titulo: _capitalizar(seccion),
                  expandido: _expandidas.contains(seccion),
                  onToggle: (abierto) => setState(() =>
                      abierto ? _expandidas.add(seccion) : _expandidas.remove(seccion)),
                  child: Column(
                    children: [
                      for (final campo in secciones[seccion]!)
                        _CampoDinamico(args: widget.args, campo: campo),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  static String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// MARK: - Dasométricos, con DAP en vivo

class _FormularioDasometrico extends ConsumerStatefulWidget {
  const _FormularioDasometrico({required this.args});

  final WizardArgs args;

  @override
  ConsumerState<_FormularioDasometrico> createState() => _FormularioDasometricoState();
}

class _FormularioDasometricoState extends ConsumerState<_FormularioDasometrico> {
  late final TextEditingController _altura;
  late final TextEditingController _cap;
  late final TextEditingController _copaParalelo;
  late final TextEditingController _copaPerp;
  late final TextEditingController _alturaCopa;

  @override
  void initState() {
    super.initState();
    final d = ref.read(wizardProvider(widget.args)).draft.datosDasometricos;
    _altura = TextEditingController(text: _fmt(d?.altura));
    _cap = TextEditingController(text: _fmt(d?.cap));
    _copaParalelo = TextEditingController(text: _fmt(d?.diamCopaParalelo));
    _copaPerp = TextEditingController(text: _fmt(d?.diamCopaPerpendicular));
    _alturaCopa = TextEditingController(text: _fmt(d?.alturaInicioCopa));
  }

  @override
  void dispose() {
    _altura.dispose();
    _cap.dispose();
    _copaParalelo.dispose();
    _copaPerp.dispose();
    _alturaCopa.dispose();
    super.dispose();
  }

  /// Un 0 se muestra como campo vacío: aún no fue medido.
  static String _fmt(double? v) => (v == null || v == 0) ? '' : Dasometria.formato(v);

  /// Acepta coma decimal, que es lo que teclea la gente en Perú.
  static double _parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  double get _capValor => _parse(_cap.text);

  void _actualizar() {
    ref.read(wizardProvider(widget.args).notifier).editar((d) {
      d.datosDasometricos = DatosDasometricos(
        altura: _parse(_altura.text),
        cap: _capValor,
        diamCopaParalelo: _parse(_copaParalelo.text),
        diamCopaPerpendicular: _parse(_copaPerp.text),
        alturaInicioCopa: _parse(_alturaCopa.text),
      );
    });
    setState(() {}); // Refresca el DAP calculado.
  }

  @override
  Widget build(BuildContext context) {
    final habito = ref.watch(wizardProvider(widget.args)).draft.habito;

    return Column(
      children: [
        CampoTexto(
          titulo: 'Altura total aproximada',
          hint: '0',
          unidad: 'm',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: _altura,
          onChanged: (_) => _actualizar(),
        ),
        const SizedBox(height: 10),
        CampoTexto(
          titulo: 'Circunferencia del tallo a 1.30 m (CAP)',
          hint: '0',
          unidad: 'cm',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: _cap,
          onChanged: (_) => _actualizar(),
        ),
        // El DAP sólo tiene sentido en árboles.
        if (habito == Habito.arbol) ...[
          const SizedBox(height: 10),
          _DapCalculado(cap: _capValor),
        ],
        const SizedBox(height: 10),
        CampoTexto(
          titulo: 'Diámetro de copa paralelo',
          hint: '0',
          unidad: 'm',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: _copaParalelo,
          onChanged: (_) => _actualizar(),
        ),
        const SizedBox(height: 10),
        CampoTexto(
          titulo: 'Diámetro de copa perpendicular',
          hint: '0',
          unidad: 'm',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: _copaPerp,
          onChanged: (_) => _actualizar(),
        ),
        const SizedBox(height: 10),
        CampoTexto(
          titulo: 'Altura de inicio de copa',
          hint: '0',
          unidad: 'm',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: _alturaCopa,
          onChanged: (_) => _actualizar(),
        ),
      ],
    );
  }
}

class _DapCalculado extends StatelessWidget {
  const _DapCalculado({required this.cap});

  final double cap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marca = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: marca.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAP calculado',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text('DAP = CAP / π',
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
              ],
            ),
          ),
          Text(
            '${Dasometria.dapFormateado(cap)} cm',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600, fontFeatures: const []),
          ),
        ],
      ),
    );
  }
}

// MARK: - Campo del formulario dinámico

class _CampoDinamico extends ConsumerStatefulWidget {
  const _CampoDinamico({required this.args, required this.campo});

  final WizardArgs args;
  final CampoMorfologico campo;

  @override
  ConsumerState<_CampoDinamico> createState() => _CampoDinamicoState();
}

class _CampoDinamicoState extends ConsumerState<_CampoDinamico> {
  late final TextEditingController _libre;
  late final TextEditingController _detalle;
  final ExpansionTileController _expansionController = ExpansionTileController();

  String get _nombre => widget.campo.nombre;

  @override
  void initState() {
    super.initState();
    final caracteres = ref.read(wizardProvider(widget.args)).draft.caracteres;
    _libre = TextEditingController(text: caracteres[_nombre] ?? '');
    _detalle = TextEditingController(text: _limpiarUnidad(caracteres[_nombre] ?? ''));
  }

  @override
  void dispose() {
    _libre.dispose();
    _detalle.dispose();
    super.dispose();
  }

  void _set(String valor) {
    ref.read(wizardProvider(widget.args).notifier).editar((d) => d.caracteres[_nombre] = valor);
  }

  String get _valorActual => ref.watch(wizardProvider(widget.args)).draft.caracteres[_nombre] ?? '';

  bool _esPersonalizado(String v) {
    if (v.isEmpty) return false;
    return !widget.campo.opciones.any((o) => o.valor == v);
  }

  String _getGroupValue(String v) {
    if (_esPersonalizado(v)) {
      if (v.contains('cm')) {
        final matches = widget.campo.opciones.where((o) => o.valor.contains('cm'));
        if (matches.isNotEmpty) return matches.first.valor;
      }
      if (v.contains(' m')) {
        final matches = widget.campo.opciones.where((o) => o.valor.contains(' m'));
        if (matches.isNotEmpty) return matches.first.valor;
      }
      final matches = widget.campo.opciones.where((o) => o.valor.toLowerCase().contains('otr'));
      if (matches.isNotEmpty) return matches.first.valor;
    }
    return v;
  }

  String get _groupValue => _getGroupValue(_valorActual);

  bool get _necesitaDetalle => _groupValue.toLowerCase().contains('otr') || _groupValue.contains('cm') || _groupValue.contains(' m');
  bool get _esNumerico => _groupValue.contains('cm') || _groupValue.contains(' m');

  String get _unidad {
    if (_groupValue.contains('cm')) return 'cm';
    if (_groupValue.contains(' m')) return 'm';
    return '';
  }

  String _limpiarUnidad(String v) {
    return v.replaceAll('cm', '').replaceAll(' m', '').trim();
  }

  List<String> _seleccionMultiple(String? raw) =>
      (raw ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final campo = widget.campo;
    final valor = _valorActual;
    final groupVal = _groupValue;

    final esOpcion = campo.tipoCampo == 'option' || campo.opciones.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(campo.nombre,
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              if (campo.requerido)
                Text(' *', style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
          const SizedBox(height: 8),
          if (esOpcion) ...[
            if (campo.tipoSeleccion == 'multiple')
              for (final opcion in campo.opciones)
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(opcion.valor, style: theme.textTheme.bodyMedium),
                  value: _seleccionMultiple(valor).contains(opcion.valor),
                  onChanged: (activo) {
                    final actuales = _seleccionMultiple(valor);
                    if (activo) {
                      if (!actuales.contains(opcion.valor)) actuales.add(opcion.valor);
                    } else {
                      actuales.remove(opcion.valor);
                    }
                    _set(actuales.join(', '));
                  },
                )
            else
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    controller: _expansionController,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    title: Text(
                      valor.isEmpty ? 'Seleccionar…' : valor,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: valor.isEmpty ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    children: [
                      for (final opcion in campo.opciones)
                        RadioListTile<String>(
                          dense: true,
                          title: Text(opcion.valor),
                          value: opcion.valor,
                          groupValue: groupVal,
                          onChanged: (v) {
                            if (v == null) return;
                            _set(v);
                            _detalle.text = '';
                            _expansionController.collapse();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            if (_necesitaDetalle) ...[
              const SizedBox(height: 16),
              CampoTexto(
                titulo: _esNumerico ? 'Valor numérico ($_unidad)' : 'Especificar (Otros)',
                hint: _esNumerico ? '0' : 'Escribe aquí…',
                unidad: _esNumerico ? _unidad : null,
                lineas: _esNumerico ? 1 : 3,
                keyboardType:
                    _esNumerico ? const TextInputType.numberWithOptions(decimal: true) : null,
                controller: _detalle,
                onChanged: (v) {
                   if (_esNumerico) {
                     _set(v.isEmpty ? groupVal : '$v $_unidad'.trim());
                   } else {
                     _set(v.isEmpty ? groupVal : v);
                   }
                },
              ),
            ],
          ] else if (campo.tipoCampo == 'number')
            CampoTexto(
              titulo: '',
              hint: '0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: _libre,
              onChanged: (v) => _set(v),
            )
          else
            CampoTexto(
              titulo: '',
              hint: 'Describe…',
              lineas: 3,
              controller: _libre,
              onChanged: (v) => _set(v),
            ),
        ],
      ),
    );
  }
}
