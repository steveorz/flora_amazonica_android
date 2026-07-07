import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class AppSwitch extends StatelessWidget {
  final String title;
  final bool isOn;
  final ValueChanged<bool> onChanged;

  const AppSwitch({
    super.key,
    required this.title,
    required this.isOn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Switch(
          value: isOn,
          onChanged: onChanged,
          activeColor: BrandColors.brandPrimary,
        ),
      ],
    );
  }
}
