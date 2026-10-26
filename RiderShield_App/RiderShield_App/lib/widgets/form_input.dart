import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FormInput extends StatefulWidget {
  const FormInput({
    super.key,
    required this.title,
    required this.hint,
    required this.controller,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.autofillHints,
    this.password = false,
    this.compact = false,
    this.textInputAction = TextInputAction.next,
  });

  final String title;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool password;
  final bool compact;
  final TextInputAction textInputAction;

  @override
  State<FormInput> createState() => _FormInputState();
}

class _FormInputState extends State<FormInput> {
  bool hidden = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact) Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 9),
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Color(0xFFE4EDFA),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          obscureText: widget.password && hidden,
          enableSuggestions: !widget.password,
          autocorrect: !widget.password,
          style: const TextStyle(color: RSColors.white, fontSize: 14.5),
          decoration: InputDecoration(
            labelText: widget.compact ? widget.title : null,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            labelStyle: const TextStyle(color: Color(0xFFC9DBEB), fontSize: 13),
            hintText: widget.compact ? null : widget.hint,
            hintStyle: const TextStyle(color: Color(0xFF8299B0), fontSize: 13.5),
            filled: true,
            fillColor: const Color(0xCC192B44),
            isDense: widget.compact,
            contentPadding: widget.compact
                ? const EdgeInsets.symmetric(vertical: 11, horizontal: 12)
                : const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            prefixIcon: Icon(widget.icon, color: RSColors.muted, size: 19),
            suffixIcon: widget.password
                ? IconButton(
                    tooltip: hidden ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => hidden = !hidden),
                    icon: Icon(
                      hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: RSColors.muted,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0x336C93B3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0x336C93B3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: RSColors.accent, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFFFA7A7)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFFFA7A7), width: 1.4),
            ),
            errorStyle: const TextStyle(color: Color(0xFFFFB7B7)),
          ),
        ),
      ],
    );
  }
}
