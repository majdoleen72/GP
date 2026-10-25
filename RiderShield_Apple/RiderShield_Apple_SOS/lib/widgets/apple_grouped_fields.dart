import 'package:flutter/material.dart';

/// Compact iOS-inspired inset grouped form. It intentionally keeps
/// visible field labels even after users enter a value.
class AppleFormGroup extends StatelessWidget {
  const AppleFormGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(17),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FA),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFCDD9E6), width: .8),
      ),
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1)
            const Padding(
              padding: EdgeInsets.only(left: 14),
              child: Divider(height: 1, thickness: .7, color: Color(0xFFD0DAE5)),
            ),
        ],
      ]),
    ),
  );
}

class AppleFormField extends StatefulWidget {
  const AppleFormField({
    super.key, required this.label, required this.controller,
    this.hint = '', this.icon, this.validator, this.keyboardType,
    this.autofillHints, this.password = false,
    this.textInputAction = TextInputAction.next,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool password;
  final TextInputAction textInputAction;

  @override
  State<AppleFormField> createState() => _AppleFormFieldState();
}

class _AppleFormFieldState extends State<AppleFormField> {
  bool hidden = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: const Color(0xFF56718E), size: 18),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: widget.icon == null ? 105 : 94,
          child: Text(widget.label, maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.3, color: Color(0xFF294560),
              fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 4),
        Expanded(child: TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          obscureText: widget.password && hidden,
          enableSuggestions: !widget.password,
          autocorrect: !widget.password,
          style: const TextStyle(fontSize: 14, color: Color(0xFF102D47)),
          cursorColor: const Color(0xFF2461A9),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(fontSize: 12.7, color: Color(0xFF8193A7)),
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            errorStyle: const TextStyle(fontSize: 10, color: Color(0xFFBD2C36)),
            suffixIconConstraints: const BoxConstraints(minHeight: 44, minWidth: 36),
            suffixIcon: widget.password
              ? IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: hidden ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => hidden = !hidden),
                  icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF56718E), size: 19),
                ) : null,
          ),
        )),
      ]),
    );
  }
}
