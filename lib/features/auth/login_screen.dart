import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/session_provider.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_text_field.dart';
import 'video_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _mostrarPassword = false;
  bool _loading = false;
  String? _errorMensaje;

  final List<String> _palabras = [
    "DESCUBRE", "EXPLORA", "REGISTRA", "IDENTIFICA", "FOTOGRAFÍA",
    "DOCUMENTA", "CONSULTA", "CLASIFICA", "CONSERVA", "APRENDE"
  ];
  int _palabraIndex = 0;
  String _currentPalabra = "";
  bool _animatingWords = true;

  @override
  void initState() {
    super.initState();
    _animateWords();
  }

  @override
  void dispose() {
    _animatingWords = false;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _animateWords() async {
    while (_animatingWords) {
      final palabra = _palabras[_palabraIndex];
      for (int i = 1; i <= palabra.length; i++) {
        if (!_animatingWords) return;
        setState(() => _currentPalabra = palabra.substring(0, i));
        await Future.delayed(const Duration(milliseconds: 120));
      }
      
      await Future.delayed(const Duration(seconds: 2));
      if (!_animatingWords) return;

      for (int i = palabra.length; i >= 0; i--) {
        if (!_animatingWords) return;
        setState(() => _currentPalabra = palabra.substring(0, i));
        await Future.delayed(const Duration(milliseconds: 60));
      }

      await Future.delayed(const Duration(milliseconds: 350));
      _palabraIndex = (_palabraIndex + 1) % _palabras.length;
    }
  }

  bool _esEmailValido(String email) {
    final regex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return regex.hasMatch(email);
  }

  Future<void> _enviar() async {
    if (_loading) return;
    
    final email = _emailController.text.trim();
    if (!_esEmailValido(email)) {
      setState(() => _errorMensaje = "Ingresa un correo válido.");
      return;
    }

    if (!_mostrarPassword) {
      setState(() { _errorMensaje = null; _loading = true; });
      final exists = await ref.read(sessionProvider.notifier).emailExists(email);
      setState(() { _loading = false; });
      
      if (exists) {
        setState(() => _mostrarPassword = true);
      } else {
        context.push('/register', extra: email);
      }
      return;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorMensaje = "Ingresa tu contraseña.");
      return;
    }

    setState(() { _errorMensaje = null; _loading = true; });
    final error = await ref.read(sessionProvider.notifier).login(email, password);
    setState(() => _loading = false);
    
    if (error != null) {
      setState(() => _errorMensaje = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _emailController.text.trim();
    final puedeEnviar = _mostrarPassword ? (email.isNotEmpty && _passwordController.text.isNotEmpty) : email.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          const AuthBackground(blurred: false),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      _currentPalabra,
                      style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'serif'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "la flora amazónica",
                      style: TextStyle(fontSize: 26, fontStyle: FontStyle.italic, color: Colors.white, fontFamily: 'serif'),
                    ),
                    const SizedBox(height: 48),

                    Container(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Column(
                        children: [
                          AppTextField(
                            title: "",
                            placeholder: "Correo electrónico",
                            controller: _emailController,
                            onChanged: (v) {
                              if (_mostrarPassword) {
                                setState(() {
                                  _mostrarPassword = false;
                                  _passwordController.clear();
                                  _errorMensaje = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_mostrarPassword) ...[
                            AppTextField(
                              title: "",
                              placeholder: "Contraseña",
                              kind: AppTextFieldKind.password,
                              controller: _passwordController,
                            ),
                            const SizedBox(height: 12),
                          ],
                          
                          if (_errorMensaje != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_errorMensaje!, style: const TextStyle(color: Colors.white, fontSize: 12))),
                                ],
                              ),
                            ),
                          
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              title: _mostrarPassword ? (_loading ? "Iniciando sesión…" : "Iniciar sesión") : (_loading ? "Verificando…" : "Continuar"),
                              variant: AppButtonVariant.primario,
                              action: _enviar,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
