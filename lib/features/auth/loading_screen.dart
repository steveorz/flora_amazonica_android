import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // El logo debe estar EXACTAMENTE en el centro para hacer match con el splash nativo.
          Center(
            child: Image.asset(
              'assets/images/logo_floramaz_padded2.png',
              width: 288,
              height: 288,
              fit: BoxFit.contain,
            ),
          ),
          // El spinner se alinea al centro pero empujado hacia abajo con padding,
          // de esta manera no empuja el logo hacia arriba (como lo haría un Column).
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 320.0),
              child: CircularProgressIndicator(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF74C69D) 
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
