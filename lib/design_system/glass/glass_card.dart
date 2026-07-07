import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double cornerRadius;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.cornerRadius = 20,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTint = tint ?? (theme.brightness == Brightness.dark ? Colors.black : Colors.white);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: baseTint.withOpacity(0.2), // Adjust opacity for "regular" glass
            borderRadius: BorderRadius.circular(cornerRadius),
            border: Border.all(
              color: baseTint.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
