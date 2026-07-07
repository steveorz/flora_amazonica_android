import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistroWizardScreen extends ConsumerStatefulWidget {
  const RegistroWizardScreen({super.key});

  @override
  ConsumerState<RegistroWizardScreen> createState() => _RegistroWizardScreenState();
}

class _RegistroWizardScreenState extends ConsumerState<RegistroWizardScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Controladores y estados locales
  final TextEditingController _cientificoController = TextEditingController();
  final TextEditingController _familiaController = TextEditingController();
  final TextEditingController _capController = TextEditingController();
  
  String? _habitoSeleccionado;
  double? _dapCalculado;
  
  // Simulación de fotos adjuntas (mínimo 5 requeridas)
  final List<String> _fotosSubidas = [];

  void _calcularDap(String value) {
    if (value.isNotEmpty) {
      final cap = double.tryParse(value);
      if (cap != null) {
        setState(() {
          _dapCalculado = cap / 3.1416;
        });
      }
    } else {
      setState(() => _dapCalculado = null);
    }
  }

  void _simularSubidaFoto(String tipo) {
    setState(() {
      if (!_fotosSubidas.contains(tipo)) {
        _fotosSubidas.add(tipo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Registro de Flora')),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            // Validación de paso de fotos
            if (_currentStep == 3 && _fotosSubidas.length < 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debe subir las 5 fotografías obligatorias.')),
              );
              return;
            }

            if (_currentStep < 4) {
              setState(() => _currentStep += 1);
            } else {
              // Submit
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enviando registro al servidor...')),
              );
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep -= 1);
          },
          steps: [
            // PASO 1: Taxonomía
            Step(
              title: const Text('Taxonomía'),
              isActive: _currentStep >= 0,
              content: Column(
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      // Aquí se conectaría al catálogo base real
                      const opciones = ['Cedrela odorata', 'Swietenia macrophylla'];
                      return opciones.where((opt) => opt.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _cientificoController.text = selection;
                      // Lógica de autocompletar familia
                      if (selection == 'Cedrela odorata') {
                        _familiaController.text = 'Meliaceae';
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _familiaController,
                    decoration: const InputDecoration(labelText: 'Familia (Autocompletado)'),
                    readOnly: true,
                  ),
                ],
              ),
            ),

            // PASO 2: Morfología y Dasometría
            Step(
              title: const Text('Morfología y Dasometría'),
              isActive: _currentStep >= 1,
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _habitoSeleccionado,
                    decoration: const InputDecoration(labelText: 'Hábito'),
                    items: ['Árbol', 'Arbusto', 'Hierba', 'Liana']
                        .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                        .toList(),
                    onChanged: (val) => setState(() {
                      _habitoSeleccionado = val;
                      _capController.clear();
                      _dapCalculado = null;
                    }),
                  ),
                  if (_habitoSeleccionado == 'Árbol') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capController,
                      decoration: const InputDecoration(labelText: 'CAP (Circunferencia a la Altura del Pecho) en cm'),
                      keyboardType: TextInputType.number,
                      onChanged: _calcularDap,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _dapCalculado != null 
                        ? 'DAP Calculado: ${_dapCalculado!.toStringAsFixed(2)} cm' 
                        : 'DAP Calculado: -',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ]
                ],
              ),
            ),

            // PASO 3: Ubicación (Mock UI Mapa)
            Step(
              title: const Text('Ubicación (GPS)'),
              isActive: _currentStep >= 2,
              content: Container(
                height: 200,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Text('AQUÍ VA EL WIDGET DE GOOGLE MAPS\nCON PIN ARRASTRABLE', textAlign: TextAlign.center),
              ),
            ),

            // PASO 4: Fotografías
            Step(
              title: const Text('Fotografías Obligatorias'),
              isActive: _currentStep >= 3,
              content: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _BotonFoto(tipo: 'Hoja', subidas: _fotosSubidas, onTap: () => _simularSubidaFoto('Hoja')),
                  _BotonFoto(tipo: 'Flor', subidas: _fotosSubidas, onTap: () => _simularSubidaFoto('Flor')),
                  _BotonFoto(tipo: 'Fruto', subidas: _fotosSubidas, onTap: () => _simularSubidaFoto('Fruto')),
                  _BotonFoto(tipo: 'Planta Completa', subidas: _fotosSubidas, onTap: () => _simularSubidaFoto('Planta Completa')),
                  _BotonFoto(tipo: 'Tallo/Corteza', subidas: _fotosSubidas, onTap: () => _simularSubidaFoto('Tallo/Corteza')),
                ],
              ),
            ),

            // PASO 5: Resumen
            Step(
              title: const Text('Resumen Final'),
              isActive: _currentStep >= 4,
              content: const Text('Revise que los datos ingresados sean correctos antes de guardar.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonFoto extends StatelessWidget {
  final String tipo;
  final List<String> subidas;
  final VoidCallback onTap;

  const _BotonFoto({required this.tipo, required this.subidas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isSubida = subidas.contains(tipo);
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSubida ? Colors.green : Colors.grey[200],
        foregroundColor: isSubida ? Colors.white : Colors.black,
      ),
      onPressed: onTap,
      icon: Icon(isSubida ? Icons.check : Icons.camera_alt),
      label: Text(tipo),
    );
  }
}
