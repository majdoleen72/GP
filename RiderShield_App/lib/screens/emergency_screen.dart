
import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_state.dart';
import '../widgets/screen_parts.dart';
import '../widgets/soft_glass_card.dart';

// ======================================================
// EMERGENCY THEME
// ======================================================

class _EmergencyTheme {
  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static Color text(BuildContext context) =>
      isLight(context)
          ? const Color(0xFF16364D)
          : inkWhite;

  static Color muted(BuildContext context) =>
      isLight(context)
          ? const Color(0xFF58758C)
          : softWhite;

  static Color accent(BuildContext context) =>
      isLight(context)
          ? const Color(0xFF248BC7)
          : actionBlue;

  static Color surface(BuildContext context) =>
      isLight(context)
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF173550);

  static Color border(BuildContext context) =>
      isLight(context)
          ? const Color(0xFFD2E8F8)
          : Colors.white.withValues(alpha: 0.12);

  static Color danger(BuildContext context) =>
      isLight(context)
          ? const Color(0xFFC74752)
          : const Color(0xFFFF8F8F);
}

// ======================================================
// EMERGENCY SCREEN
// ======================================================

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({
    super.key,
    this.openProfile,
  });

  final VoidCallback? openProfile;

  static const _avatarColors = [
    Color(0xFF5CB6F0),
    Color(0xFF7BE0AE),
    Color(0xFFFFB45C),
    Color(0xFFB99BFF),
    Color(0xFFFF8FA3),
  ];

  Color _avatarColor(
    BuildContext context,
    int index,
  ) {
    final color =
        _avatarColors[index % _avatarColors.length];

    if (!_EmergencyTheme.isLight(context)) {
      return color;
    }

    const lightColors = [
      Color(0xFF248BC7),
      Color(0xFF17835D),
      Color(0xFFB76A11),
      Color(0xFF8663BB),
      Color(0xFFC74766),
    ];

    return lightColors[index % lightColors.length];
  }

  // Consistent, readable fields in both light and dark themes.
  Widget _contactField(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    final isLight = _EmergencyTheme.isLight(context);
    final accent = _EmergencyTheme.accent(context);
    final text = _EmergencyTheme.text(context);
    final muted = _EmergencyTheme.muted(context);

    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isLight
            ? const Color(0xFFC9DDEB)
            : const Color(0xFF4A7089),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 3, bottom: 7),
          child: Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          cursorColor: accent,
          style: TextStyle(
            color: text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: muted.withValues(alpha: 0.82),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: accent, size: 21),
            filled: true,
            fillColor: isLight
                ? const Color(0xFFF1F7FC)
                : const Color(0xFF20435E),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 17,
            ),
            border: normalBorder,
            enabledBorder: normalBorder,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accent, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _EmergencyTheme.danger(context),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _EmergencyTheme.danger(context),
                width: 1.6,
              ),
            ),
            errorStyle: TextStyle(
              color: _EmergencyTheme.danger(context),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ====================================================
  // ADD / EDIT EMERGENCY CONTACT
  // ====================================================

  Future<void> editContact(
    BuildContext context, {
    EmergencyContact? existing,
  }) async {
    final state = RiderScope.of(context);

    final key = GlobalKey<FormState>();

    final name = TextEditingController(
      text: existing?.name ?? '',
    );

    final phone = TextEditingController(
      text: existing?.phone ?? '',
    );

    final relationship = TextEditingController(
      text: existing?.relationship ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor:
          _EmergencyTheme.surface(context),
      builder: (sheet) {
        final isLight =
            _EmergencyTheme.isLight(sheet);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(sheet).bottom + 22,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null
                          ? 'Add emergency contact'
                          : 'Edit contact',
                      style: TextStyle(
                        color: _EmergencyTheme.text(
                          sheet,
                        ),
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _contactField(
                      sheet,
                      label: 'Name',
                      hint: 'Full name',
                      icon: Icons.person_outline_rounded,
                      controller: name,
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Enter a name'
                          : null,
                    ),

                    const SizedBox(height: 14),

                    _contactField(
                      sheet,
                      label: 'Relation',
                      hint: 'e.g. Sister',
                      icon: Icons.group_outlined,
                      controller: relationship,
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Enter relationship'
                          : null,
                    ),

                    const SizedBox(height: 14),

                    _contactField(
                      sheet,
                      label: 'Phone',
                      hint: '+9665...',
                      icon: Icons.phone_outlined,
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      validator: (v) => RegExp(
                        r'^\+?[0-9 ()-]{7,20}$',
                      ).hasMatch((v ?? '').trim())
                          ? null
                          : 'Enter a valid phone number',
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: isLight
                              ? const Color(0xFF248BC7)
                              : Theme.of(sheet)
                                  .colorScheme
                                  .primary,
                          foregroundColor: isLight
                              ? Colors.white
                              : Theme.of(sheet)
                                  .colorScheme
                                  .onPrimary,
                        ),
                        onPressed: () async {
                          if (!(key.currentState
                                  ?.validate() ??
                              false)) {
                            return;
                          }

                          final saving =
                              state.upsertContact(
                            EmergencyContact(
                              id: existing?.id ??
                                  DateTime.now()
                                      .microsecondsSinceEpoch
                                      .toString(),
                              name: name.text.trim(),
                              relationship:
                                  relationship.text.trim(),
                              phone: phone.text.trim(),
                            ),
                          );

                          if (sheet.mounted) {
                            Navigator.pop(sheet);
                          }

                          await saving;
                        },
                        child: const Text(
                          'Save contact',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Preserve original controller disposal.
    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        name.dispose();
        phone.dispose();
        relationship.dispose();
      },
    );
  }

  // ====================================================
  // DELETE EMERGENCY CONTACT
  // ====================================================

  Future<void> deleteContact(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final state = RiderScope.of(context);

    final remove = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text(
          'Remove ${contact.name} from your emergency contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialog, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  _EmergencyTheme.danger(dialog),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (remove == true) {
      await state.deleteContact(contact.id);
    }
  }

  // ====================================================
  // CONTACT ACTION BUTTON
  // ====================================================

  Widget _iconAction(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onTap,
  ) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 19,
              color: color,
            ),
          ),
        ),
      );

  // ====================================================
  // EMERGENCY CONTACT CARD
  // ====================================================

  Widget _contactCard(
    BuildContext context,
    EmergencyContact contact,
    int index,
  ) {
    final isLight =
        _EmergencyTheme.isLight(context);

    final color = _avatarColor(context, index);

    final text = _EmergencyTheme.text(context);
    final muted = _EmergencyTheme.muted(context);
    final accent = _EmergencyTheme.accent(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: SoftGlassCard(
        light: isLight,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.20),
                border: Border.all(
                  color: color.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                contact.name.isEmpty
                    ? '?'
                    : contact.name[0].toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: 0.16,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      contact.relationship,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: muted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          contact.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconAction(
                  Icons.edit_outlined,
                  accent,
                  'Edit ${contact.name}',
                  () => editContact(
                    context,
                    existing: contact,
                  ),
                ),

                const SizedBox(height: 8),

                _iconAction(
                  Icons.delete_outline_rounded,
                  _EmergencyTheme.danger(context),
                  'Delete ${contact.name}',
                  () => deleteContact(
                    context,
                    contact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // MAIN SCREEN
  // ====================================================

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    final contacts = state.contacts;

    final isLight =
        _EmergencyTheme.isLight(context);

    final text = _EmergencyTheme.text(context);
    final muted = _EmergencyTheme.muted(context);
    final accent = _EmergencyTheme.accent(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        135,
      ),
      children: [
        // EMERGENCY CONTACTS HEADER + ADD BUTTON
        SectionCaption(
          'Emergency contacts',
          trailing: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => editContact(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      color: accent,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Add contact',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // EMPTY CONTACTS STATE
        if (contacts.isEmpty)
          SoftGlassCard(
            light: isLight,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 28,
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(
                      alpha: 0.15,
                    ),
                  ),
                  child: Icon(
                    Icons.groups_2_outlined,
                    size: 32,
                    color: accent,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'No contacts yet',
                  style: TextStyle(
                    color: text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Add a trusted person to your emergency list.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
                  ),
                ),
              ],
            ),
          ),

        // SAVED CONTACTS
        for (var i = 0; i < contacts.length; i++)
          _contactCard(
            context,
            contacts[i],
            i,
          ),


      ],
    );
  }
}
