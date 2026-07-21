import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'app_router.dart';
import 'core/session/app_preferences.dart';
import 'core/storage/app_prefs.dart';
import 'core/theme/app_theme.dart';

@pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   if (kDebugMode) {
//     print('Mensaje en background: ${message.messageId}');
//   }
// }

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // await Firebase.initializeApp();
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // await FirebaseMessaging.instance.requestPermission(
  //   alert: true,
  //   badge: true,
  //   sound: true,
  // );

  // Debe completarse antes de runApp: los stores leen las prefs de forma
  // síncrona, igual que `UserDefaults.standard` en iOS.
  await initPrefs();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const ProviderScope(child: FloraAmazonicaApp()));
}

class FloraAmazonicaApp extends ConsumerWidget {
  const FloraAmazonicaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final tema = ref.watch(preferenciasProvider).tema;

    return MaterialApp.router(
      title: 'Flora Amazónica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: tema.themeMode,
      routerConfig: router,
    );
  }
}
