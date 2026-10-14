import 'package:flutter/material.dart';

import '../../core/domain/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/caregiver_theme.dart';

class CaregiverMemoryBankScreen extends StatefulWidget {
  final SmaranStore store;
  const CaregiverMemoryBankScreen({super.key, required this.store});

  @override
  State<CaregiverMemoryBankScreen> createState() =>
      _CaregiverMemoryBankScreenState();
}

class _CaregiverMemoryBankScreenState
    extends State<CaregiverMemoryBankScreen> {
  @override
  Widget build(BuildContext context) {
    final people = widget.store.people;
    final memories = widget.store.memories;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Memory Bank',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: CG.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage familiar faces and important memories.',
                      style: TextStyle(
                          fontSize: 12, color: CG.textMuted),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _addPerson(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Person',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                style: FilledButton.styleFrom(
                  backgroundColor: CG.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (people.isEmpty)
            _emptyCard('No people added yet',
                'Add family photos, names, and voice notes.')
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: people
                  .map((p) => _PersonCard(person: p))
                  .toList(),
            ),

          const SizedBox(height: 20),

          const Text(
            'Recent Memories Used in Games',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: CG.primary,
            ),
          ),
          const SizedBox(height: 10),

          if (memories.isEmpty)
            _emptyCard('No memories yet',
                'Photos added here appear in memory games.')
          else
            ...memories.take(4).map((m) => _MemoryRow(memory: m)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _addPerson(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final relCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Person',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: CG.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: inputDec('Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: relCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: inputDec('Relation (e.g. Daughter)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: CG.primary),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (nameCtrl.text.trim().isEmpty) return;

    widget.store.people.add(Person(
      name: nameCtrl.text.trim(),
      relation: relCtrl.text.trim().isEmpty
          ? 'Family'
          : relCtrl.text.trim(),
    ));
    await widget.store.save();
    if (mounted) setState(() {});
  }

  Widget _emptyCard(String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CG.rCard),
        border: Border.all(color: CG.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.photo_library_rounded,
              size: 48, color: CG.primary),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: CG.textPrimary)),
          const SizedBox(height: 4),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: CG.textMuted)),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;
  const _PersonCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CG.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: CG.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              person.name.isNotEmpty
                  ? person.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: CG.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            person.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: CG.textPrimary,
            ),
          ),
          Text(
            person.relation,
            style: const TextStyle(fontSize: 11, color: CG.textMuted),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: CG.primaryPale,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'View',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: CG.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryRow extends StatelessWidget {
  final Memory memory;
  const _MemoryRow({required this.memory});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CG.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CG.primaryPale,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.image_rounded,
                color: CG.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              memory.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: CG.textPrimary,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: CG.primaryPale,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Correct',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: CG.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}