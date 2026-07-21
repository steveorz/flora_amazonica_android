import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/session/app_preferences.dart';
import '../../core/session/connectivity_store.dart';
import '../../core/session/session_provider.dart';
import '../../data/repositories/auth_repository.dart';


final avatarProvider = StateNotifierProvider.family<AvatarNotifier, String?, String>((ref, userId) {
  return AvatarNotifier(userId);
});

class AvatarNotifier extends StateNotifier<String?> {
  final String userId;
  AvatarNotifier(this.userId) : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('avatar_$userId');
  }

  Future<void> setAvatar(String avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_$userId', avatar);
    state = avatar;
  }
}

/// Botón de avatar para la barra superior. Al tocarlo abre el perfil.
/// Espejo de `ProfileToolbarItem` (iOS), que en Android también es el punto de
/// entrada a Configuración y Cambiar contraseña.
class ProfileToolbarButton extends ConsumerWidget {
  const ProfileToolbarButton({super.key, this.hasShadow = false});
  final bool hasShadow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(sessionProvider).usuario;
    if (usuario == null) return const SizedBox.shrink();
    
    final avatar = ref.watch(avatarProvider(usuario.id));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: avatar != null 
              ? CircleAvatar(
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage(avatar),
                )
              : const Icon(Icons.account_circle, size: 48, color: AppColors.primary),
        ),
      ),
    );
  }
}

/// C-09: datos del usuario, avatar y acciones de cuenta.
/// Espejo de `ProfileView` (iOS).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showAvatarSelector(BuildContext context, WidgetRef ref, String userId) {
    final theme = Theme.of(context);
    final avatars = [
      'assets/images/avatars/avatar_jaguar.png',
      'assets/images/avatars/avatar_toucan.png',
      'assets/images/avatars/avatar_macaw.png',
      'assets/images/avatars/avatar_sloth.png',
      'assets/images/avatars/avatar_dolphin.png',
      'assets/images/avatars/avatar_monkey.png',
      'assets/images/avatars/avatar_piranha.png',
      'assets/images/avatars/avatar_capybara.png',
      'assets/images/avatars/avatar_tapir.png',
      'assets/images/avatars/avatar_anaconda.png',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.brightness == Brightness.dark 
          ? AppColors.backgroundDark 
          : AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Elige tu animalito', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: avatars.length,
                  itemBuilder: (context, index) {
                    final asset = avatars[index];
                    return InkWell(
                      onTap: () {
                        ref.read(avatarProvider(userId).notifier).setAvatar(asset);
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            asset,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _mostrarAcercaDe(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final activeGreen = isDark ? const Color(0xFF74C69D) : AppColors.primary;
        
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: activeGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/images/logo_floramaz.png', width: 56, height: 56),
                  ),
                  const SizedBox(height: 16),
                  Text('FlorAmaz', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: activeGreen)),
                  const Text('Versión Beta 1', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),
                  const Text(
                    'Universidad Nacional de la Amazonía Peruana\nFacultad de Ingeniería de Sistemas e Informática',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Hecho con profundo cariño para\nnuestra Amazonía por:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Alva Rengifo Anny Celeste\n'
                    '• Ordoñez Navarro Danny Steve\n'
                    '• Cobeñas Gonzales Jeysson Rafael\n'
                    '• Reátegui Tote Lucas Alejandro\n'
                    '• Grandez Sifuentes Jhor Anthony',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, height: 1.6),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: activeGreen.withOpacity(0.1),
                        foregroundColor: activeGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Genial', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final u = ref.watch(sessionProvider).usuario;

    if (u == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }

    final avatar = ref.watch(avatarProvider(u.id));

    final isDark = theme.brightness == Brightness.dark;

    Color roleBgColor;
    Color roleTextColor;
    switch (u.rol.label.toLowerCase()) {
      case 'validador':
        roleBgColor = isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.1);
        roleTextColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
        break;
      case 'administrador':
        roleBgColor = isDark ? Colors.purple.withValues(alpha: 0.2) : Colors.purple.withValues(alpha: 0.1);
        roleTextColor = isDark ? Colors.purple.shade300 : Colors.purple.shade700;
        break;
      case 'consultor':
        roleBgColor = isDark ? Colors.teal.withValues(alpha: 0.2) : Colors.teal.withValues(alpha: 0.1);
        roleTextColor = isDark ? Colors.teal.shade300 : Colors.teal.shade700;
        break;
      case 'registrador':
      default:
        roleBgColor = AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1);
        roleTextColor = isDark ? Colors.greenAccent.shade200 : AppColors.primary;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              
              // Avatar con badge de cámara
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: () => _showAvatarSelector(context, ref, u.id),
                    child: avatar != null
                        ? CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.transparent,
                            backgroundImage: AssetImage(avatar),
                          )
                        : u.avatarUrl != null
                            ? CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(u.avatarUrl!),
                              )
                            : const Icon(Icons.account_circle, size: 80, color: AppColors.primary),
                  ),
                  InkWell(
                    onTap: () => _showAvatarSelector(context, ref, u.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.surface, width: 2),
                      ),
                      child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Saludo
              Text(u.nombreCompleto, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(u.email, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              
              // Rol en lugar del botón "Administrar tu Cuenta"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: roleBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  u.rol.label.toUpperCase(),
                  style: TextStyle(
                    color: roleTextColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Tarjeta de Opciones
              _GoogleCard(
                child: Column(
                  children: [
                    ExpansionTile(
                      leading: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurfaceVariant),
                      title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.w500)),
                      iconColor: isDark ? const Color(0xFF74C69D) : AppColors.primary,
                      textColor: isDark ? const Color(0xFF74C69D) : AppColors.primary,
                      collapsedIconColor: theme.colorScheme.onSurfaceVariant,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      children: const [
                        _ConfiguracionPanel(),
                      ],
                    ),
                    Divider(
                      height: 1, 
                      thickness: 1, 
                      color: isDark ? Colors.white12 : Colors.grey.shade100, 
                      indent: 56,
                    ),
                    ExpansionTile(
                      leading: Icon(Icons.lock_reset, color: theme.colorScheme.onSurfaceVariant),
                      title: const Text('Cambiar contraseña', style: TextStyle(fontWeight: FontWeight.w500)),
                      iconColor: isDark ? const Color(0xFF74C69D) : AppColors.primary,
                      textColor: isDark ? const Color(0xFF74C69D) : AppColors.primary,
                      collapsedIconColor: theme.colorScheme.onSurfaceVariant,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      children: const [
                        _ChangePasswordPanel(),
                      ],
                    ),
                    Divider(
                      height: 1, 
                      thickness: 1, 
                      color: isDark ? Colors.white12 : Colors.grey.shade100, 
                      indent: 56,
                    ),
                    ListTile(
                      leading: Icon(Icons.logout, color: theme.colorScheme.error),
                      title: Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.error)),
                      onTap: () => ref.read(sessionProvider.notifier).logout(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _mostrarAcercaDe(context),
                icon: Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
                tooltip: 'Acerca de FlorAmaz',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeGreen = isDark ? const Color(0xFF74C69D) : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          color: activeGreen,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Nota extends StatelessWidget {
  const _Nota(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        texto,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ConfiguracionPanel extends ConsumerStatefulWidget {
  const _ConfiguracionPanel();

  @override
  ConsumerState<_ConfiguracionPanel> createState() => _ConfiguracionPanelState();
}

class _ConfiguracionPanelState extends ConsumerState<_ConfiguracionPanel> {
  bool _notifExpanded = false;
  bool _aparExpanded = false;

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caché limpia.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferenciasProvider);
    final notifier = ref.read(preferenciasProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeGreen = isDark ? const Color(0xFF74C69D) : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpansionTile(
            title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.w500)),
            iconColor: activeGreen,
            textColor: activeGreen,
            collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            onExpansionChanged: (v) => setState(() => _notifExpanded = v),
            trailing: AnimatedRotation(
              turns: _notifExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.arrow_drop_down),
            ),
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.only(left: 56, right: 24),
            children: [
              SwitchListTile(
                title: const Text('Recibir notificaciones'),
                value: prefs.notificacionesActivas,
                onChanged: notifier.setNotificaciones,
                activeColor: activeGreen,
                contentPadding: const EdgeInsets.only(left: 72, right: 24),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 72, right: 24, bottom: 16),
                child: Text(
                  'Te avisamos cuando cambie el estado de tus registros o tu cuenta.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Apariencia', style: TextStyle(fontWeight: FontWeight.w500)),
            iconColor: activeGreen,
            textColor: activeGreen,
            collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            onExpansionChanged: (v) => setState(() => _aparExpanded = v),
            trailing: AnimatedRotation(
              turns: _aparExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.arrow_drop_down),
            ),
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.only(left: 56, right: 24),
            children: [
              for (final t in Tema.values)
                RadioListTile<Tema>(
                  value: t,
                  groupValue: prefs.tema,
                  onChanged: (v) => notifier.setTema(v!),
                  title: Text(t.label),
                  activeColor: activeGreen,
                  contentPadding: const EdgeInsets.only(left: 72, right: 24),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordPanel extends ConsumerStatefulWidget {
  const _ChangePasswordPanel();

  @override
  ConsumerState<_ChangePasswordPanel> createState() => _ChangePasswordPanelState();
}

class _ChangePasswordPanelState extends ConsumerState<_ChangePasswordPanel> {
  static const _longitudMinima = 8;

  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  bool _enviando = false;
  String? _error;
  bool _success = false;

  bool get _puedeEnviar =>
      _actual.text.isNotEmpty &&
      _nueva.text.length >= _longitudMinima &&
      _nueva.text == _confirmar.text;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _error = null;
      _enviando = true;
    });
    try {
      await ref.read(sessionProvider.notifier).changePassword(_actual.text, _nueva.text);
      if (!mounted) return;
      setState(() {
        _success = true;
        _actual.clear();
        _nueva.clear();
        _confirmar.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada exitosamente.')),
      );
      // Opcional: Cerrar el panel de alguna forma, o dejar el éxito visible.
    } on AuthError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = AuthError.generico.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeGreen = isDark ? const Color(0xFF74C69D) : AppColors.primary;

    if (_success) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text(
              '¡Contraseña cambiada con éxito!',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(primary: activeGreen),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: activeGreen,
          selectionColor: activeGreen.withOpacity(0.3),
          selectionHandleColor: activeGreen,
        ),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
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
          floatingLabelStyle: TextStyle(color: activeGreen),
        ),
      ),
      child: ListenableBuilder(
        listenable: Listenable.merge([_actual, _nueva, _confirmar]),
        builder: (context, _) {
          final noCoinciden = _confirmar.text.isNotEmpty && _nueva.text != _confirmar.text;
          return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _actual,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nueva,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  helperText: 'Mínimo $_longitudMinima caracteres',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmar,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
              ),
              if (noCoinciden) ...[
                const SizedBox(height: 8),
                Text('Las contraseñas no coinciden', style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _enviando || !_puedeEnviar ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _enviando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ),
    );
  }
}

class _GoogleCard extends StatelessWidget {
  final Widget child;
  const _GoogleCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: oscuro
          ? Color.lerp(AppColors.backgroundDark, Colors.white, 0.08)
          : Color.lerp(AppColors.background, Colors.white, 0.50),
      borderRadius: BorderRadius.circular(24),
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
