import 'package:flutter/material.dart';

import '../../core/domain/app_models.dart';
import '../../core/theme/caregiver_theme.dart';

class FamilyMemoriesScreen extends StatefulWidget {
  final SmaranStore store;
  const FamilyMemoriesScreen({super.key, required this.store});

  @override
  State<FamilyMemoriesScreen> createState() =>
      _FamilyMemoriesScreenState();
}

class _FamilyMemoriesScreenState extends State<FamilyMemoriesScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final memories = widget.store.memories;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Memories',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: CG.primary)),
              const SizedBox(height: 4),
              const Text('Photos and moments that matter',
                  style: TextStyle(
                      fontSize: 12, color: CG.textMuted)),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('All'),
                    const SizedBox(width: 8),
                    _chip('Photos'),
                    const SizedBox(width: 8),
                    _chip('Videos'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (memories.isEmpty)
                _empty()
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                  children: memories
                      .map((m) => _MemoryCard(memory: m))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_memory_family',
        backgroundColor: CG.primary,
        foregroundColor: Colors.white,
        onPressed: _addMemory,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Memory',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _chip(String label) {
    final selected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CG.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? CG.primary : CG.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : CG.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CG.rCard),
        border: Border.all(color: CG.border),
      ),
      child: Column(
        children: const [
          Icon(Icons.photo_library_rounded,
              size: 54, color: CG.primary),
          SizedBox(height: 12),
          Text('No memories yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: CG.textPrimary)),
          SizedBox(height: 4),
          Text('Tap "Add Memory" to share a moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: CG.textMuted)),
        ],
      ),
    );
  }

  Future<void> _addMemory() async {
    final titleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Add a Memory',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: CG.primary)),
        content: TextField(
          controller: titleCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Memory title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: CG.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || titleCtrl.text.trim().isEmpty) return;
    widget.store.memories.add(Memory(
      title: titleCtrl.text.trim(),
      path: '',
    ));
    await widget.store.save();
    if (mounted) setState(() {});
  }
}

class _MemoryCard extends StatelessWidget {
  final Memory memory;
  const _MemoryCard({required this.memory});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CG.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: CG.primaryPale,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.image_rounded,
                  color: CG.primary, size: 42),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: CG.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.favorite_rounded,
                        color: CG.danger, size: 12),
                    SizedBox(width: 4),
                    Text('Loved',
                        style: TextStyle(
                            fontSize: 10, color: CG.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}