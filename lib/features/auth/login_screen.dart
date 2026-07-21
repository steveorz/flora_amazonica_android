import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/session_provider.dart';
import '../../data/repositories/auth_repository.dart';
import 'video_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _mostrarPassword = false;
  bool _mostrarRegistro = false;
  bool _aceptaTerminos = false;
  bool _loading = false;
  bool _obscurePassword = true;
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
    _nombresController.dispose();
    _apellidosController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _animateWords() async {
    while (_animatingWords) {
      final palabra = _palabras[_palabraIndex];
      for (int i = 1; i <= palabra.length; i++) {
        if (!_animatingWords) return;
        if (mounted) setState(() => _currentPalabra = palabra.substring(0, i));
        await Future.delayed(const Duration(milliseconds: 120));
      }
      
      await Future.delayed(const Duration(seconds: 2));
      if (!_animatingWords) return;

      for (int i = palabra.length; i >= 0; i--) {
        if (!_animatingWords) return;
        if (mounted) setState(() => _currentPalabra = palabra.substring(0, i));
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

    if (!_mostrarPassword && !_mostrarRegistro) {
      setState(() { _errorMensaje = null; _loading = true; });
      
      try {
        final exists = await ref.read(sessionProvider.notifier).emailExists(email);
        setState(() { _loading = false; });
        
        if (exists) {
          setState(() => _mostrarPassword = true);
        } else {
          setState(() => _mostrarRegistro = true);
        }
      } catch (e) {
        setState(() {
          _loading = false;
          _errorMensaje = "No se pudo conectar al servidor. Inténtalo más tarde.";
        });
      }
      return;
    }

    if (_mostrarPassword) {
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
      return;
    }

    if (_mostrarRegistro) {
      final nombres = _nombresController.text.trim();
      final apellidos = _apellidosController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (nombres.isEmpty || apellidos.isEmpty) {
        setState(() => _errorMensaje = "Completa tu nombre y apellido.");
        return;
      }
      if (password.length < 8) {
        setState(() => _errorMensaje = "La contraseña debe tener al menos 8 caracteres.");
        return;
      }
      if (password != confirmPassword) {
        setState(() => _errorMensaje = "Las contraseñas no coinciden.");
        return;
      }
      if (!_aceptaTerminos) {
        setState(() => _errorMensaje = "Debes aceptar los términos y condiciones.");
        return;
      }

      setState(() { _errorMensaje = null; _loading = true; });
      final form = RegistroForm()
        ..nombres = nombres
        ..apellidos = apellidos
        ..email = email
        ..password = password;

      try {
        await ref.read(sessionProvider.notifier).register(form);
        setState(() => _loading = false);
        if (mounted) {
          context.go('/account-created');
        }
      } catch (e) {
        setState(() {
          _loading = false;
          _errorMensaje = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  Widget _buildUnderlineInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool readOnly = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      readOnly: readOnly,
      onChanged: onChanged,
      style: TextStyle(
        color: readOnly ? Colors.white.withOpacity(0.6) : Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        filled: false,
        fillColor: Colors.transparent,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 24),
        suffixIcon: suffixIcon ?? (isPassword 
            ? IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: child.key == const ValueKey('icon1') 
                        ? Tween<double>(begin: 0.5, end: 1).animate(anim) 
                        : Tween<double>(begin: 1, end: 0.5).animate(anim),
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: _obscurePassword
                      ? const Icon(Icons.visibility_off, key: ValueKey('icon1'), color: Colors.white70, size: 20)
                      : const Icon(Icons.visibility, key: ValueKey('icon2'), color: Colors.white, size: 20),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null),
        suffixIconConstraints: const BoxConstraints(minHeight: 24, minWidth: 24),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: readOnly ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const FondoAuthNitido(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const Spacer(flex: 3), // Empuja los textos hacia abajo para centrarlos
                        
                        Text(
                          _currentPalabra,
                          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'serif'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "la flora amazónica",
                          style: TextStyle(
                            fontSize: 32, 
                            fontStyle: FontStyle.italic, 
                            color: Colors.white, 
                            fontFamily: 'serif',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const Spacer(flex: 2), // Empuja el recuadro hacia abajo para que quede al fondo
                        
                        Container(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08), // Más oscuro como al inicio
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Header
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 22),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12), // Cabecera un poco menos clara
                                        border: Border(
                                          bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
                                        ),
                                      ),
                                      child: const Text(
                                        "INICIA SESIÓN O REGÍSTRATE",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    
                                    // Body
                                    Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _buildUnderlineInput(
                                            controller: _emailController,
                                            hint: "Correo electrónico",
                                            icon: Icons.email_outlined,
                                            readOnly: _mostrarPassword || _mostrarRegistro,
                                            suffixIcon: (_mostrarPassword || _mostrarRegistro)
                                                ? GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _mostrarPassword = false;
                                                        _mostrarRegistro = false;
                                                        _passwordController.clear();
                                                        _confirmPasswordController.clear();
                                                        _errorMensaje = null;
                                                      });
                                                    },
                                                    child: Text(
                                                      "Cambiar",
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.8),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(height: 20),
                                          
                                          AnimatedSize(
                                            duration: const Duration(milliseconds: 350),
                                            curve: Curves.easeInOut,
                                            alignment: Alignment.topCenter,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                if (_mostrarPassword) ...[
                                                  _buildUnderlineInput(
                                                    controller: _passwordController,
                                                    hint: "Contraseña",
                                                    icon: Icons.lock_outline,
                                                    isPassword: true,
                                                  ),
                                                  const SizedBox(height: 24),
                                                ] else if (_mostrarRegistro) ...[
                                                  _buildUnderlineInput(
                                                    controller: _nombresController,
                                                    hint: "Nombres",
                                                    icon: Icons.person_outline,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  _buildUnderlineInput(
                                                    controller: _apellidosController,
                                                    hint: "Apellidos",
                                                    icon: Icons.person_outline,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  _buildUnderlineInput(
                                                    controller: _passwordController,
                                                    hint: "Contraseña (mín. 8 caracteres)",
                                                    icon: Icons.lock_outline,
                                                    isPassword: true,
                                                    onChanged: (v) => setState(() {}),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  _buildUnderlineInput(
                                                    controller: _confirmPasswordController,
                                                    hint: "Confirmar contraseña",
                                                    icon: Icons.lock_outline,
                                                    isPassword: true,
                                                    onChanged: (v) => setState(() {}),
                                                  ),
                                                  
                                                  // Mensajes de validación en tiempo real
                                                  Builder(
                                                    builder: (context) {
                                                      final pass = _passwordController.text;
                                                      final conf = _confirmPasswordController.text;
                                                      
                                                      String? warning;
                                                      if (pass.isNotEmpty && pass.length < 8) {
                                                        warning = "La contraseña debe tener al menos 8 caracteres.";
                                                      } else if (conf.isNotEmpty && pass != conf) {
                                                        warning = "Las contraseñas no coinciden.";
                                                      }

                                                      if (warning != null) {
                                                        return Padding(
                                                          padding: const EdgeInsets.only(top: 8.0),
                                                          child: Text(
                                                            warning,
                                                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                                          ),
                                                        );
                                                      }
                                                      return const SizedBox.shrink();
                                                    },
                                                  ),
                                                  const SizedBox(height: 20),
                                                  
                                                  // Aceptar Términos Checkbox
                                                  Row(
                                                    children: [
                                                      Theme(
                                                        data: ThemeData(
                                                          unselectedWidgetColor: Colors.white.withOpacity(0.5),
                                                        ),
                                                        child: SizedBox(
                                                          width: 18,
                                                          height: 18,
                                                          child: Checkbox(
                                                            value: _aceptaTerminos,
                                                            onChanged: (v) {
                                                              setState(() {
                                                                _aceptaTerminos = v ?? false;
                                                              });
                                                            },
                                                            activeColor: Colors.white.withOpacity(0.2),
                                                            checkColor: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          "Acepto los términos y condiciones",
                                                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 24),
                                                ],
                                              ],
                                            ),
                                          ),
                                          
                                          if (_errorMensaje != null) ...[
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              margin: const EdgeInsets.only(bottom: 16),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.error, color: Colors.white, size: 16),
                                                  const SizedBox(width: 8),
                                                  Expanded(child: Text(_errorMensaje!, style: const TextStyle(color: Colors.white, fontSize: 12))),
                                                ],
                                              ),
                                            ),
                                          ],
                                          
                                          // Central Glassmorphism Darker Button
                                          Center(
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.10), // Misma claridad que la cabecera
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: _enviar,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.transparent,
                                                        shadowColor: Colors.transparent,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        elevation: 0,
                                                      ),
                                                      child: Text(
                                                        _mostrarPassword 
                                                            ? (_loading ? "INICIANDO SESIÓN…" : "CONTINUAR") 
                                                            : (_mostrarRegistro
                                                                ? (_loading ? "REGISTRANDO…" : "CONTINUAR")
                                                                : (_loading ? "VERIFICANDO…" : "CONTINUAR")),
                                                        style: const TextStyle(
                                                          fontSize: 16, 
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: 1.2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
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
                        ),
                        const SizedBox(height: 24), // Margen inferior en el fondo
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
