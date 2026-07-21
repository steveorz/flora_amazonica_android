import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/models/usuario.dart';

/// El rol Validador no tiene app nativa: trabaja sobre el frontend web.
/// Espejo de `ValidadorWebView` (iOS, que abre un WKWebView).
class ValidadorWebScreen extends StatefulWidget {
  const ValidadorWebScreen({super.key, required this.usuario, required this.onBack});

  final Usuario usuario;
  final VoidCallback onBack;

  @override
  State<ValidadorWebScreen> createState() => _ValidadorWebScreenState();
}

class _ValidadorWebScreenState extends State<ValidadorWebScreen> {
  static const _url = 'https://flora-amazonica.com/';

  late final WebViewController _controller;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _cargando = true),
          onPageFinished: (_) => setState(() => _cargando = false),
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del validador'),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: widget.onBack,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_cargando) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
