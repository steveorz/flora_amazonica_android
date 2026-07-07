import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/session_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_text_field.dart';
import '../../design_system/glass/glass_card.dart';
import 'video_background.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String initialEmail;
  const RegisterScreen({super.key, required this.initialEmail});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _aceptaTerminos = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  bool _esEmailValido(String email) {
    final regex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return regex.hasMatch(email);
  }

  bool get _puedeEnviar {
    final pass = _passwordController.text;
    final conf = _confirmPasswordController.text;
    return _nombresController.text.isNotEmpty &&
           _apellidosController.text.isNotEmpty &&
           _esEmailValido(_emailController.text) &&
           pass.length >= 8 &&
           pass == conf &&
           _aceptaTerminos;
  }

  Future<void> _submit() async {
    setState(() { _error = null; _loading = true; });
    final form = RegistroForm()
      ..nombres = _nombresController.text
      ..apellidos = _apellidosController.text
      ..email = _emailController.text
      ..password = _passwordController.text;

    try {
      await ref.read(sessionProvider.notifier).register(form);
      setState(() => _loading = false);
      if (mounted) {
        // Go back to login or auto login (depends on backend, usually auto login or inactive)
        context.go('/');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear cuenta", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AuthBackground(blurred: true),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Crea tu cuenta", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 18),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(title: "Nombres", controller: _nombresController, onChanged: (v) => setState((){})),
                        const SizedBox(height: 14),
                        AppTextField(title: "Apellidos", controller: _apellidosController, onChanged: (v) => setState((){})),
                        const SizedBox(height: 14),
                        AppTextField(title: "Email", controller: _emailController, placeholder: "tu@correo.pe", onChanged: (v) => setState((){})),
                        const SizedBox(height: 14),
                        AppTextField(title: "Contraseña", controller: _passwordController, kind: AppTextFieldKind.password, onChanged: (v) => setState((){})),
                        const SizedBox(height: 14),
                        AppTextField(title: "Confirmar contraseña", controller: _confirmPasswordController, kind: AppTextFieldKind.password, onChanged: (v) => setState((){})),
                        const SizedBox(height: 14),
                        
                        InkWell(
                          onTap: () => setState(() => _aceptaTerminos = !_aceptaTerminos),
                          child: Row(
                            children: [
                              Icon(_aceptaTerminos ? Icons.check_box : Icons.check_box_outline_blank, color: _aceptaTerminos ? Colors.green : Colors.grey),
                              const SizedBox(width: 8),
                              const Text("Acepto los términos y condiciones", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ],

                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            title: _loading ? "Creando…" : "Crear cuenta",
                            variant: AppButtonVariant.primario,
                            action: _puedeEnviar ? _submit : () {},
                          ),
                        ),
                      ],
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
}
