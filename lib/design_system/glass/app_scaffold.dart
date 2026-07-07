import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? avatar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
        backgroundColor: Colors.transparent, // Making it transparent to show body if under it
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
              BlendMode.srcOver,
            ),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        actions: [
          if (actions != null) ...actions!,
          if (avatar != null) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: avatar!,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: child,
    );
  }
}
