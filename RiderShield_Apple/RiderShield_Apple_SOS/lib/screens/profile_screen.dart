
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app/app_scope.dart';
import '../app/app_state.dart';
import '../widgets/screen_parts.dart';
import '../widgets/soft_glass_card.dart';
import '../widgets/apple_grouped_fields.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.openProfile});

  final VoidCallback openProfile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> pickImage({required bool cover}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (picked == null || !mounted) return;

      await RiderScope.of(context).setProfileImage(
        await picked.readAsBytes(),
        cover: cover,
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

  Future<void> editProfile(RiderState state) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: state.fullName);
    final email = TextEditingController(text: state.email);
    final phone = TextEditingController(text: state.phone);
    final city = TextEditingController(text: state.city);
    var experience = state.ridingExperience;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF173550),
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    AppleFormGroup(
                      children: [
                        AppleFormField(
                          label: 'Name',
                          controller: name,
                          hint: 'Full name',
                          icon: Icons.person_outline_rounded,
                          validator: (s) =>
                              (s ?? '').trim().isEmpty
                                  ? 'Enter your name'
                                  : null,
                        ),
                        AppleFormField(
                          label: 'Email',
                          controller: email,
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.mail_outline_rounded,
                        ),
                        AppleFormField(
                          label: 'Phone',
                          controller: phone,
                          hint: '+9665...',
                          keyboardType: TextInputType.phone,
                          icon: Icons.phone_outlined,
                        ),
                        AppleFormField(
                          label: 'City',
                          controller: city,
                          hint: 'City',
                          icon: Icons.location_on_outlined,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: experience,
                      decoration: const InputDecoration(
                        labelText: 'Riding experience',
                      ),
                      items: [
                        'Beginner',
                        'Under 1 year',
                        '1–3 years',
                        '3+ years'
                      ].map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      ).toList(),
                      onChanged: (v) => update(
                        () => experience = v ?? experience,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          await state.updateProfile(
                            name: name.text,
                            emailAddress: email.text,
                            phoneNumber: phone.text,
                            cityName: city.text,
                            experience: experience,
                          );

                          if (sheet.mounted) {
                            Navigator.of(sheet).pop();
                          }
                        },
                        child: const Text('Save changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    name.dispose();
    email.dispose();
    phone.dispose();
    city.dispose();
  }

  Future<void> logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF173550),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of RiderShield?',
          style: TextStyle(
            color: Color(0xFFD1DFEF),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFFBDE5FF),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: Color(0xFFFF8585),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = RiderScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 115),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 6, 2, 14),
          child: Text(
            'Your personal details and preferences.',
            style: TextStyle(
              color: softWhite,
              fontSize: 12.5,
            ),
          ),
        ),
        SoftGlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 112,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF466D91),
                          Color(0xFF0E283E),
                        ],
                      ),
                      image: s.coverBytes == null
                          ? null
                          : DecorationImage(
                              image: MemoryImage(s.coverBytes!),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _smallAction(
                      Icons.wallpaper_rounded,
                      'Cover',
                      () => pickImage(cover: true),
                    ),
                  ),
                  Positioned(
                    bottom: 11,
                    left: 17,
                    child: Stack(
                      children: [
                        RiderAvatar(diameter: 67),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => pickImage(cover: false),
                            child: const CircleAvatar(
                              radius: 15,
                              backgroundColor: Color(0xFFBDE5FF),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                color: Color(0xFF153149),
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName.isEmpty ? 'Your name' : s.fullName,
                      style: const TextStyle(
                        color: inkWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      s.city.isEmpty
                          ? 'Complete your profile to get started'
                          : s.city,
                      style: const TextStyle(color: softWhite),
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      onPressed: () => editProfile(s),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                      ),
                      label: const Text('Edit profile'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionCaption('Personal information'),

        InfoTile(
          icon: Icons.person_outline_rounded,
          title: 'Full name',
          value: s.fullName.isEmpty ? 'Not added' : s.fullName,
          onTap: () => editProfile(s),
        ),
        const SizedBox(height: 9),

        InfoTile(
          icon: Icons.phone_outlined,
          title: 'Phone number',
          value: s.phone.isEmpty ? 'Not added' : s.phone,
          onTap: () => editProfile(s),
        ),
        const SizedBox(height: 9),

        InfoTile(
          icon: Icons.mail_outline_rounded,
          title: 'Email',
          value: s.email.isEmpty ? 'Not added' : s.email,
          onTap: () => editProfile(s),
        ),
        const SizedBox(height: 9),

        InfoTile(
          icon: Icons.location_on_outlined,
          title: 'City',
          value: s.city.isEmpty ? 'Not added' : s.city,
          onTap: () => editProfile(s),
        ),
        const SizedBox(height: 9),

        InfoTile(
          icon: Icons.two_wheeler_rounded,
          title: 'Riding experience',
          value: s.ridingExperience,
          onTap: () => editProfile(s),
        ),

        const SizedBox(height: 20),

        SoftGlassCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 3,
            ),
            leading: const Icon(
              Icons.logout_rounded,
              color: Color(0xFFFF8585),
              size: 23,
            ),
            title: const Text(
              'Log Out',
              style: TextStyle(
                color: Color(0xFFFF8585),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFFF8585),
              size: 20,
            ),
            onTap: logOut,
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Profile details are saved on this device for the prototype.',
          style: TextStyle(
            color: softWhite,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _smallAction(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) =>
      Material(
        color: const Color(0xAA0A2740),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
}
