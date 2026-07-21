import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

enum AppTextFieldKind { text, numeric, password, multiline }

class AppTextField extends StatefulWidget {
  final String title;
  final String placeholder;
  final AppTextFieldKind kind;
  final String? unit; // for numeric
  final TextEditingController? controller;
  final String? initialValue;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.title,
    this.placeholder = "",
    this.kind = AppTextFieldKind.text,
    this.unit,
    this.controller,
    this.initialValue,
    this.onChanged,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isSecure = true;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
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
          controller: _controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        );
      case AppTextFieldKind.numeric:
        return TextField(
          controller: _controller,
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
          controller: _controller,
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
          controller: _controller,
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
