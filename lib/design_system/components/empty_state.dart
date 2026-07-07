import 'package:flutter/material.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  final IconData systemImage;
  final String title;
  final String message;
  final String? actionTitle;
  final VoidCallback? action;

  const EmptyState({
    super.key,
    required this.systemImage,
    required this.title,
    required this.message,
    this.actionTitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              systemImage,
              size: 44,
              color: Colors.grey,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (actionTitle != null && action != null) ...[
              const SizedBox(height: 18),
              AppButton(
                title: actionTitle!,
                variant: AppButtonVariant.primario,
                action: action!,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
