import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

enum AppTextFieldKind { text, numericWithUnit, password, multiline }

class AppTextField extends StatefulWidget {
  final String title;
  final String placeholder;
  final AppTextFieldKind kind;
  final String? unit; // for numericWithUnit
  final TextEditingController controller;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.title,
    this.placeholder = "",
    this.kind = AppTextFieldKind.text,
    this.unit,
    required this.controller,
    this.onChanged,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isSecure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                   ? Colors.grey.shade900 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildField(),
        ),
      ],
    );
  }

  Widget _buildField() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: BrandColors.brandPrimary, width: 1.5),
    );

    switch (widget.kind) {
      case AppTextFieldKind.text:
        return TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        );
      case AppTextFieldKind.numericWithUnit:
        return TextField(
          controller: widget.controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            suffixText: widget.unit,
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        );
      case AppTextFieldKind.password:
        return TextField(
          controller: widget.controller,
          obscureText: _isSecure,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(_isSecure ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _isSecure = !_isSecure;
                });
              },
            ),
          ),
        );
      case AppTextFieldKind.multiline:
        return TextField(
          controller: widget.controller,
          minLines: 3,
          maxLines: 8,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        );
    }
  }
}
