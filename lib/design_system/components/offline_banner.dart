import 'dart:ui';
import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOnline; // This would normally come from a provider
  final int pendientes;

  const OfflineBanner({
    super.key,
    required this.isOnline,
    this.pendientes = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6.0, left: 12.0, right: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, size: 16),
                const SizedBox(width: 10),
                const Text(
                  "Sin conexión",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (pendientes > 0) ...[
                  const SizedBox(width: 8),
                  const Text("·", style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  Text(
                    "$pendientes en cola",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
