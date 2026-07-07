import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainMobileLayout extends StatelessWidget {
  final Widget child;
  
  const MainMobileLayout({
    super.key,
    required this.child,
  });

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/registro'); break;
      case 1: context.go('/catalogo'); break;
      case 2: context.go('/perfil'); break;
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/registro')) return 0;
    if (location.startsWith('/catalogo')) return 1;
    if (location.startsWith('/perfil')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'Registrar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
