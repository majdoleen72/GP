
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_scope.dart';
import '../app/app_state.dart';
import '../widgets/screen_parts.dart';
import 'welcome_screen.dart';

const _background = Color(0xFF09263D);
const _surface = Color(0xFF173A55);
const _surfaceLight = Color(0xFF214A68);
const _accent = Color(0xFF9DDCFF);
const _muted = Color(0xFFAFC5D6);
const _danger = Color(0xFFFF8585);

// Frosted Ice colors
const _iceBackground = Color(0xFFF4F9FF);
const _iceSurface = Color(0xFFFFFFFF);
const _iceInput = Color(0xFFE5F2FC);
const _iceAccent = Color(0xFF248BC7);
const _iceText = Color(0xFF16364D);
const _iceMuted = Color(0xFF58758C);

class _ProfileColors {
  static bool light(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static Color background(BuildContext context) =>
      light(context) ? _iceBackground : _background;

  static Color surface(BuildContext context) =>
      light(context) ? _iceSurface : _surface;

  static Color input(BuildContext context) =>
      light(context) ? _iceInput : _surfaceLight;

  static Color text(BuildContext context) =>
      light(context) ? _iceText : Colors.white;

  static Color muted(BuildContext context) =>
      light(context) ? _iceMuted : _muted;

  static Color accent(BuildContext context) =>
      light(context) ? _iceAccent : _accent;
}

// ======================================================
// PROFILE SCREEN
// ======================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.openProfile,
  });

  final VoidCallback openProfile;

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (picked == null || !mounted) return;

      await RiderScope.of(context).setProfileImage(
        await picked.readAsBytes(),
        cover: false,
      );
    } catch (_) {
      if (mounted) {
        showDemoNotice(
          context,
          'Could not open your photos on this device.',
        );
      }
    }
  }

  Future<void> logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            _ProfileColors.surface(dialogContext),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(
          'Log out?',
          style: TextStyle(
            color: _ProfileColors.text(dialogContext),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of RiderShield?',
          style: TextStyle(
            color: _ProfileColors.muted(dialogContext),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: _ProfileColors.accent(dialogContext),
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: _danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await RiderScope.of(context).signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  void openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = RiderScope.of(context);
    final isLight = s.isLightMode;

    return Container(
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          22, 18, 22, 115,
        ),
        children: [
          // PROFILE HEADER
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const RiderAvatar(diameter: 100),
                      Positioned(
                        bottom: 0,
                        right: -2,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _ProfileColors.accent(
                              context,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _ProfileColors.background(
                                context,
                              ),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color:
                                _ProfileColors.background(
                              context,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.fullName.isEmpty
                      ? 'Your name'
                      : s.fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ProfileColors.text(context),
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  s.email.isEmpty
                      ? 'Individual account'
                      : s.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ProfileColors.muted(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 35),

          // PERSONAL INFORMATION
          _ProfileMenuTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal information',
            onTap: () => openPage(
              const _PersonalInformationScreen(),
            ),
          ),

          const SizedBox(height: 14),

          // PRIVACY & PROTECTION
          _ProfileMenuTile(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy & Protection',
            onTap: () => openPage(
              const _PrivacyProtectionScreen(),
            ),
          ),

          const SizedBox(height: 14),

          // LIGHT / DARK APPEARANCE
          _ThemeCircleTile(
            isLight: isLight,
            onTap: () {
              s.setLightMode(!isLight);
            },
          ),

          const SizedBox(height: 14),

          // LOG OUT
          _ProfileMenuTile(
            icon: Icons.logout_rounded,
            title: 'Log Out',
            color: _danger,
            onTap: logOut,
          ),
        ],
      ),
    );
  }
}

// ======================================================
// ANIMATED SUN / MOON TILE
// ======================================================

class _ThemeCircleTile extends StatelessWidget {
  const _ThemeCircleTile({
    required this.isLight,
    required this.onTap,
  });

  final bool isLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent =
        isLight ? _iceAccent : _accent;

    return Material(
      color: isLight ? _iceSurface : _surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 15,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration:
                    const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFD9EFFD)
                      : const Color(0xFF254B66),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(
                      alpha: 0.45,
                    ),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(
                        alpha: 0.13,
                      ),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration:
                      const Duration(milliseconds: 300),
                  transitionBuilder:
                      (child, animation) {
                    return RotationTransition(
                      turns: Tween<double>(
                        begin: 0.5,
                        end: 1,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    isLight
                        ? Icons.wb_sunny_rounded
                        : Icons.dark_mode_rounded,
                    key: ValueKey(isLight),
                    color: accent,
                    size: 27,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        color: isLight
                            ? _iceText
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// PROFILE MENU TILE
// ======================================================

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? _ProfileColors.text(context);

    return Material(
      color: _ProfileColors.surface(context),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 19,
            vertical: 21,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: effectiveColor,
                size: 25,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _ProfileColors.muted(context),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// PERSONAL INFORMATION
// ======================================================

class _PersonalInformationScreen extends StatefulWidget {
  const _PersonalInformationScreen();

  @override
  State<_PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<_PersonalInformationScreen> {
  Future<void> editValue({
    required String title,
    required String current,
    required Future<void> Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String)? validate,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _FieldEditDialog(
        title: title,
        initial: current,
        keyboardType: keyboardType,
        validate: validate,
      ),
    );

    if (result == null || !mounted) return;

    await onSave(result);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = RiderScope.of(context);

    return _ProfileSubPage(
      title: 'Personal information',
      child: Column(
        children: [
          _InformationTile(
            label: 'Full Name',
            value: s.fullName,
            onTap: () => editValue(
              title: 'Full Name',
              current: s.fullName,
              validate: (v) => v.length < 2
                  ? 'Enter at least 2 characters'
                  : null,
              onSave: (v) => s.updateProfile(
                name: v,
                emailAddress: s.email,
                phoneNumber: s.phone,
                cityName: s.city,
                experience: s.ridingExperience,
              ),
            ),
          ),
          const _InfoDivider(),
          _InformationTile(
            label: 'Email address',
            value: s.email,
            showArrow: false,
          ),
          const _InfoDivider(),
          _InformationTile(
            label: 'Phone number',
            value: s.phone,
            onTap: () => editValue(
              title: 'Phone number',
              current: s.phone,
              keyboardType: TextInputType.phone,
              validate: (v) =>
                  v.isEmpty ||
                      RegExp(r'^\+?[0-9 ()-]{7,20}$')
                          .hasMatch(v)
                  ? null
                  : 'Enter a valid phone number',
              onSave: (v) => s.updateProfile(
                name: s.fullName,
                emailAddress: s.email,
                phoneNumber: v,
                cityName: s.city,
                experience: s.ridingExperience,
              ),
            ),
          ),
          const _InfoDivider(),
          _InformationTile(
            label: 'City',
            value: s.city,
            onTap: () => editValue(
              title: 'City',
              current: s.city,
              onSave: (v) => s.updateProfile(
                name: s.fullName,
                emailAddress: s.email,
                phoneNumber: s.phone,
                cityName: v,
                experience: s.ridingExperience,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// INFORMATION TILE
// ======================================================

class _InformationTile extends StatelessWidget {
  const _InformationTile({
    required this.label,
    required this.value,
    this.onTap,
    this.showArrow = true,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 19,
          vertical: 20,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: _ProfileColors.muted(
                        context,
                      ),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.isEmpty
                        ? 'Not added'
                        : value,
                    style: TextStyle(
                      color: _ProfileColors.text(
                        context,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: _ProfileColors.muted(context),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 19,
      endIndent: 19,
      color: _ProfileColors.light(context)
          ? const Color(0xFFD2E8F8)
          : const Color(0x335C829F),
    );
  }
}

// ======================================================
// PRIVACY & PROTECTION
// ======================================================

class _PrivacyProtectionScreen extends StatelessWidget {
  const _PrivacyProtectionScreen();

  @override
  Widget build(BuildContext context) {
    return _ProfileSubPage(
      title: 'Privacy & Protection',
      child: _ProfileMenuTile(
        icon: Icons.password_rounded,
        title: 'Change Password',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const _ChangePasswordScreen(),
            ),
          );
        },
      ),
      wrapChild: false,
    );
  }
}

// ======================================================
// CHANGE PASSWORD
// ======================================================

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<_ChangePasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  bool visible = false;

  @override
  void dispose() {
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  String? validatePassword(String? value) {
    final p = value ?? '';

    if (p.length < 8) {
      return 'Use at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(p)) {
      return 'Add an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(p)) {
      return 'Add a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(p)) {
      return 'Add a number';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(p)) {
      return 'Add a symbol';
    }

    return null;
  }

  void savePassword() {
    if (!(formKey.currentState?.validate() ??
        false)) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Password changes require authentication integration. '
          'No password has been changed.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileSubPage(
      title: 'Change Password',
      wrapChild: false,
      child: Form(
        key: formKey,
        autovalidateMode:
            AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create a new password',
              style: TextStyle(
                color: _ProfileColors.text(context),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use 8+ characters, uppercase, lowercase, '
              'a number and a symbol.',
              style: TextStyle(
                color: _ProfileColors.muted(context),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: newPassword,
              obscureText: !visible,
              style: TextStyle(
                color: _ProfileColors.text(context),
              ),
              validator: validatePassword,
              decoration: _inputDecoration(
                context,
                'New password',
                suffix: IconButton(
                  icon: Icon(
                    visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _ProfileColors.muted(
                      context,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      visible = !visible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: confirmPassword,
              obscureText: !visible,
              style: TextStyle(
                color: _ProfileColors.text(context),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) {
                  return 'Confirm your password';
                }
                if (v != newPassword.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              decoration: _inputDecoration(
                context,
                'Confirm new password',
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: savePassword,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _ProfileColors.accent(context),
                  foregroundColor:
                      _ProfileColors.background(
                    context,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Update Password',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// PROFILE SUBPAGE
// ======================================================

class _ProfileSubPage extends StatelessWidget {
  const _ProfileSubPage({
    required this.title,
    required this.child,
    this.wrapChild = true,
  });

  final String title;
  final Widget child;
  final bool wrapChild;

  @override
  Widget build(BuildContext context) {
    final bg = _ProfileColors.background(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _ProfileColors.text(context),
          ),
          onPressed: () =>
              Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: _ProfileColors.text(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20, 25, 20, 35,
        ),
        children: [
          if (wrapChild)
            Container(
              decoration: BoxDecoration(
                color: _ProfileColors.surface(context),
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            )
          else
            child,
        ],
      ),
    );
  }
}

// ======================================================
// EDIT FIELD DIALOG
// ======================================================

class _FieldEditDialog extends StatefulWidget {
  const _FieldEditDialog({
    required this.title,
    required this.initial,
    required this.keyboardType,
    this.validate,
  });

  final String title;
  final String initial;
  final TextInputType keyboardType;
  final String? Function(String)? validate;

  @override
  State<_FieldEditDialog> createState() =>
      _FieldEditDialogState();
}

class _FieldEditDialogState
    extends State<_FieldEditDialog> {
  final formKey = GlobalKey<FormState>();

  late final controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void save() {
    if (!(formKey.currentState?.validate() ??
        false)) {
      return;
    }

    Navigator.of(context).pop(
      controller.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor:
          _ProfileColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: Text(
        widget.title,
        style: TextStyle(
          color: _ProfileColors.text(context),
        ),
      ),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          keyboardType: widget.keyboardType,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => save(),
          style: TextStyle(
            color: _ProfileColors.text(context),
          ),
          decoration: _inputDecoration(
            context,
            widget.title,
          ),
          validator: (v) =>
              widget.validate?.call(
            (v ?? '').trim(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: _ProfileColors.accent(context),
            ),
          ),
        ),
        TextButton(
          onPressed: save,
          child: Text(
            'Save',
            style: TextStyle(
              color: _ProfileColors.accent(context),
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context,
  String hint, {
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: _ProfileColors.muted(context),
    ),
    filled: true,
    fillColor: _ProfileColors.input(context),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    errorStyle: const TextStyle(
      color: _danger,
    ),
  );
}
