import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/session/session_provider.dart';
import '../../../design_system/components/progress_stepper.dart';
import '../../../design_system/components/app_button.dart';
import 'wizard_provider.dart';
import 'steps/identificacion_step.dart';
import 'steps/habito_step.dart';
import 'steps/morfologia_step.dart';
import 'steps/ubicacion_step.dart';
import 'steps/fotos_step.dart';
import 'steps/resumen_step.dart';
import 'steps/confirmacion_step.dart';

class NuevoRegistroScreen extends ConsumerWidget {
  const NuevoRegistroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardProvider);
    final notifier = ref.read(wizardProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo registro"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onTap: () {
            _confirmExit(context, ref);
          },
        ),
        actions: [
          if (state.pasoActual <= 6)
            TextButton(
              onPressed: () {
                // Guardar borrador y salir
                Navigator.of(context).pop();
              },
              child: const Text("Guardar borrador", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (state.pasoActual <= 6)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: ProgressStepper(
                currentStep: state.pasoActual,
                totalSteps: state.totalPasos,
              ),
            ),
            
          Expanded(
            child: _buildPasoActual(state.pasoActual),
          ),
          
          if (state.pasoActual < 7)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (state.pasoActual > 1)
                      Expanded(
                        child: AppButton(
                          title: "Anterior",
                          variant: AppButtonVariant.secundario,
                          action: () => notifier.retroceder(),
                        ),
                      ),
                    if (state.pasoActual > 1) const SizedBox(width: 10),
                    
                    if (state.pasoActual < 6)
                      Expanded(
                        child: AppButton(
                          title: "Siguiente",
                          variant: AppButtonVariant.primario,
                          action: notifier.pasoCompleto(state.pasoActual) ? () => notifier.avanzar() : () {},
                        ),
                      )
                    else if (state.pasoActual == 6)
                      Expanded(
                        child: AppButton(
                          title: state.enviando ? "Enviando…" : "Enviar registro",
                          variant: AppButtonVariant.atencion,
                          action: () {
                            final userId = ref.read(sessionProvider)?.id ?? '';
                            notifier.enviar(userId);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasoActual(int paso) {
    switch (paso) {
      case 1: return const IdentificacionStep();
      case 2: return const HabitoStep();
      case 3: return const MorfologiaStep();
      case 4: return const UbicacionStep();
      case 5: return const FotosStep();
      case 6: return const ResumenStep();
      case 7: return const ConfirmacionStep();
      default: return const SizedBox.shrink();
    }
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Salir del wizard?"),
        content: const Text("Puedes guardar tus avances como borrador."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Descartar", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              // Guardar borrador local
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}
