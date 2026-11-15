
import 'package:flutter/material.dart';
import '../app/app_scope.dart';
import '../app/app_state.dart';
import '../widgets/screen_parts.dart';
import '../widgets/soft_glass_card.dart';
import '../widgets/apple_grouped_fields.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key, this.openProfile});

  final VoidCallback? openProfile;

  static const _avatarColors = [
    Color(0xFF5CB6F0),
    Color(0xFF7BE0AE),
    Color(0xFFFFB45C),
    Color(0xFFB99BFF),
    Color(0xFFFF8FA3),
  ];

  // Add or edit emergency contact
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
      backgroundColor: const Color(0xFF173550),
      builder: (sheet) => Padding(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null
                        ? 'Add emergency contact'
                        : 'Edit contact',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 18),

                  AppleFormGroup(
                    children: [
                      AppleFormField(
                        label: 'Name',
                        controller: name,
                        hint: 'Full name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) =>
                            (v ?? '').trim().isEmpty
                                ? 'Enter a name'
                                : null,
                      ),

                      AppleFormField(
                        label: 'Relation',
                        controller: relationship,
                        hint: 'e.g. Sister',
                        icon: Icons.group_outlined,
                        validator: (v) =>
                            (v ?? '').trim().isEmpty
                                ? 'Enter relationship'
                                : null,
                      ),

                      AppleFormField(
                        label: 'Phone',
                        controller: phone,
                        hint: '+9665...',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        validator: (v) =>
                            RegExp(r'^\+?[0-9 ()-]{7,20}$')
                                    .hasMatch((v ?? '').trim())
                                ? null
                                : 'Enter a valid phone number',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () async {
                        if (!(key.currentState?.validate() ?? false)) {
                          return;
                        }

                        await state.upsertContact(
                          EmergencyContact(
                            id: existing?.id ??
                                DateTime.now()
                                    .microsecondsSinceEpoch
                                    .toString(),
                            name: name.text.trim(),
                            relationship: relationship.text.trim(),
                            phone: phone.text.trim(),
                          ),
                        );

                        if (sheet.mounted) {
                          Navigator.pop(sheet);
                        }
                      },
                      child: const Text('Save contact'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    name.dispose();
    phone.dispose();
    relationship.dispose();
  }

  // Delete emergency contact
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
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (remove == true) {
      await state.deleteContact(contact.id);
    }
  }

  // Edit and delete action buttons
  Widget _iconAction(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
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
  }

  // Emergency contact card
  Widget _contactCard(
    BuildContext context,
    EmergencyContact contact,
    int index,
  ) {
    final color = _avatarColors[index % _avatarColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: SoftGlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: .20),
                border: Border.all(
                  color: color.withValues(alpha: .6),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: inkWhite,
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
                      color: color.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(20),
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
                      const Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: softWhite,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          contact.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: softWhite,
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
                  actionBlue,
                  'Edit ${contact.name}',
                  () => editContact(
                    context,
                    existing: contact,
                  ),
                ),

                const SizedBox(height: 8),

                _iconAction(
                  Icons.delete_outline_rounded,
                  const Color(0xFFFF8F8F),
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

  // Main Emergency Screen
  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    final contacts = state.contacts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        115,
      ),
      children: [
        // Emergency Contacts heading
        SectionCaption(
          'Emergency contacts',
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: actionBlue.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${contacts.length} saved',
              style: const TextStyle(
                color: actionBlue,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // Empty contacts state
        if (contacts.isEmpty)
          SoftGlassCard(
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
                    color: actionBlue.withValues(alpha: .15),
                  ),
                  child: const Icon(
                    Icons.groups_2_outlined,
                    size: 32,
                    color: actionBlue,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'No contacts yet',
                  style: TextStyle(
                    color: inkWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Add a trusted person to your emergency list.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: softWhite,
                  ),
                ),
              ],
            ),
          ),

        // Display saved contacts
        for (var i = 0; i < contacts.length; i++)
          _contactCard(
            context,
            contacts[i],
            i,
          ),

        const SizedBox(height: 6),

        // Add contact button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.tonalIcon(
            onPressed: () => editContact(context),
            style: FilledButton.styleFrom(
              backgroundColor: actionBlue.withValues(alpha: .16),
              foregroundColor: actionBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
            ),
            label: const Text('Add contact'),
          ),
        ),
      ],
    );
  }
}
