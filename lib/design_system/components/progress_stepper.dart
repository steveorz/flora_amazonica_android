import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class ProgressStepper extends StatelessWidget {
  final int current;
  final int total;

  const ProgressStepper({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Paso $current de $total",
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: total > 0 ? current / total : 0,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(BrandColors.brandPrimary),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}
