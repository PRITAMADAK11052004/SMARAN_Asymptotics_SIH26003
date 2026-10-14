import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/theme/caregiver_theme.dart';

class FamilyCircleScreen extends StatelessWidget {
  final SmaranStore store;
  const FamilyCircleScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.currentUser;
    final people = store.people;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Family Circle',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: CG.primary)),
          const SizedBox(height: 4),
          const Text('Everyone who cares for your loved one',
              style: TextStyle(fontSize: 12, color: CG.textMuted)),
          const SizedBox(height: 18),

          if (user != null)
            _Member(
              name: user.fullName,
              role: 'You • Family Member',
              isYou: true,
            ),

          const SizedBox(height: 12),

          if (people.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(CG.rCard),
                border: Border.all(color: CG.border),
              ),
              child: const Text(
                'Invite other family members to contribute memories '
                'and stay updated.',
                style: TextStyle(
                    fontSize: 12.5,
                    color: CG.textMuted,
                    height: 1.5),
              ),
            )
          else
            ...people.map((p) => _Member(
                  name: p.name,
                  role: p.relation,
                )),

          const SizedBox(height: 18),

          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_alt_1_rounded,
                  color: CG.primary, size: 20),
              label: const Text(
                'Invite Family Member',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: CG.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CG.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Member extends StatelessWidget {
  final String name;
  final String role;
  final bool isYou;

  const _Member({
    required this.name,
    required this.role,
    this.isYou = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isYou ? CG.primary : CG.border,
          width: isYou ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: CG.primarySoft,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: CG.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: CG.textPrimary)),
                Text(role,
                    style: const TextStyle(
                        fontSize: 11.5, color: CG.textMuted)),
              ],
            ),
          ),
          if (isYou)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: CG.primaryPale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('You',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: CG.primary)),
            ),
        ],
      ),
    );
  }
}