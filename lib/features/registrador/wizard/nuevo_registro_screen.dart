import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/especie_service.dart';
import '../../../core/services/notificacion_service.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/models/especie.dart';
import '../../../data/models/especie_draft.dart';
import '../../../design_system/components/app_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../../design_system/components/progress_stepper.dart';
import 'steps/confirmacion_step.dart';
import 'steps/fotos_step.dart';
import 'steps/habito_step.dart';
import 'steps/identificacion_step.dart';
import 'steps/morfologia_step.dart';
import 'steps/resumen_step.dart';
import 'steps/ubicacion_step.dart';
import 'wizard_provider.dart';

/// Contenedor a pantalla completa del wizard de 7 pasos.
/// Espejo de `NuevoRegistroView` (iOS).
class NuevoRegistroScreen extends ConsumerStatefulWidget {
  const NuevoRegistroScreen({super.key, this.draft, this.especieAEditar});

  /// Borrador a retomar.
  final EspecieDraft? draft;

  /// Registro existente a editar.
  final Especie? especieAEditar;

  @override
  ConsumerState<NuevoRegistroScreen> createState() => _NuevoRegistroScreenState();
}

class _NuevoRegistroScreenState extends ConsumerState<NuevoRegistroScreen> {
  late final WizardArgs _args =
      WizardArgs(draft: widget.draft, especie: widget.especieAEditar);

  @override
  void initState() {
    super.initState();
    // Recarga silenciosa: el wizard debe reflejar lo que el validador cambió.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(especieServiceProvider.notifier).cargar();
    });
  }

  Future<void> _guardarYSalir() async {
    await ref.read(wizardProvider(_args).notifier).guardarBorradorLocal();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmarCerrar() async {
    final theme = Theme.of(context);
    final oscuro = theme.brightness == Brightness.dark;
    final activeGreen = oscuro ? const Color(0xFF74C69D) : AppColors.primary;

    final accion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: oscuro ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: oscuro ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('¿Salir del wizard?', style: TextStyle(fontWeight: FontWeight.w600, color: activeGreen, fontSize: 16)),
              ),
              ListTile(
                leading: Icon(Icons.save_outlined, color: activeGreen),
                title: Text('Guardar borrador y salir', style: TextStyle(color: activeGreen, fontWeight: FontWeight.w500)),
                onTap: () => Navigator.of(ctx).pop('guardar'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text('Descartar borrador', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w500)),
                onTap: () => Navigator.of(ctx).pop('descartar'),
              ),
              ListTile(
                leading: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
                title: Text('Cancelar', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || accion == null) return;
    if (accion == 'guardar') {
      await _guardarYSalir();
    } else if (accion == 'descartar') {
      await ref.read(wizardProvider(_args).notifier).descartarBorrador();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _enviar() async {
    final wizard = ref.read(wizardProvider(_args).notifier);
    final registradorId = ref.read(sessionProvider).usuario?.id;
    if (registradorId == null) return;

    await wizard.enviar(registradorId);

    if (!mounted) return;
    if (ref.read(wizardProvider(_args)).resultado != null) {
      // Refresca el badge de avisos: el backend crea una notificación al recibir.
      ref.read(notificacionServiceProvider.notifier).cargar(registradorId);
      wizard.irA(7);
    }
  }

  Widget _paso(int paso) {
    switch (paso) {
      case 1:
        return IdentificacionStep(args: _args);
      case 2:
        return HabitoStep(args: _args);
      case 3:
        return MorfologiaStep(args: _args);
      case 4:
        return UbicacionStep(args: _args);
      case 5:
        return FotosStep(args: _args);
      case 6:
        return ResumenStep(args: _args);
      case 7:
        return ConfirmacionStep(args: _args, onCerrar: () => Navigator.of(context).pop());
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(wizardProvider(_args));
    final wizard = ref.read(wizardProvider(_args).notifier);
    final paso = estado.pasoActual;
    final esUltimoPaso = paso == 7;

    final baseTheme = Theme.of(context);
    final isDark = baseTheme.brightness == Brightness.dark;
    final activeGreen = isDark ? const Color(0xFF74C69D) : AppColors.primary;

    return Theme(
      data: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(primary: activeGreen),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: activeGreen,
          selectionColor: activeGreen.withOpacity(0.3),
          selectionHandleColor: activeGreen,
        ),
        inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: activeGreen, width: 2),
          ),
          floatingLabelStyle: TextStyle(color: activeGreen, fontWeight: FontWeight.w600),
          labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        ),
      ),
      child: PopScope(
        // El wizard sólo se cierra por la X, para no perder el borrador sin avisar.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !esUltimoPaso) {
            if (estado.draft.isEmpty) {
              Navigator.of(context).pop();
            } else {
              _confirmarCerrar();
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
          title: Text(estado.editandoId != null ? 'Editar registro' : 'Nuevo registro'),
          leading: esUltimoPaso
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (estado.draft.isEmpty) {
                      Navigator.of(context).pop();
                    } else {
                      _confirmarCerrar();
                    }
                  },
                ),
        ),
        body: Column(
          children: [
            if (paso <= 6)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: ProgressStepper(current: paso, total: WizardState.totalPasos),
              ),
            Expanded(child: _paso(paso)),
            if (!esUltimoPaso)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      if (paso > 1) ...[
                        Expanded(
                          child: AppButton(
                            title: 'Anterior',
                            variant: AppButtonVariant.terciario,
                            action: wizard.retroceder,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (paso < 6)
                        Expanded(
                          child: AppButton(
                            title: 'Siguiente',
                            enabled: wizard.pasoCompleto(paso),
                            action: wizard.avanzar,
                          ),
                        )
                      else
                        Expanded(
                          child: AppButton(
                            title: estado.enviando ? 'Enviando…' : 'Enviar registro',
                            variant: AppButtonVariant.atencion,
                            enabled: !estado.enviando,
                            action: _enviar,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ));
  }
}
