import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/features/stickers/data/sticker_pack_data_source.dart';
import 'package:chat_app/src/features/stickers/domain/sticker_pack.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StickerPackPage extends StatefulWidget {
  const StickerPackPage({super.key});

  @override
  State<StickerPackPage> createState() => _StickerPackPageState();
}

class _StickerPackPageState extends State<StickerPackPage> {
  final _titleController = TextEditingController();
  final _picker = ImagePicker();
  bool _busy = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveTitle(String uid) async {
    setState(() => _busy = true);
    try {
      await sl<StickerPackDataSource>().upsertTitle(
        uid: uid,
        title: _titleController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.saved)));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _addSticker(String uid) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      await sl<StickerPackDataSource>().addSticker(uid: uid, file: picked);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.stickerPackTitle)),
        body: Center(child: Text(context.l10n.notSignedIn)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.stickerPackTitle)),
      body: StreamBuilder<StickerPack?>(
        stream: sl<StickerPackDataSource>().watchPack(uid),
        builder: (context, snapshot) {
          final pack = snapshot.data;
          if (_titleController.text.isEmpty && pack?.title != null) {
            _titleController.text = pack?.title ?? '';
          }

          final items = pack?.items ?? const <StickerItem>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: context.l10n.stickerPackTitle,
                  hintText: context.l10n.stickerPackHint,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : () => _saveTitle(uid),
                      child: Text(context.l10n.saveChanges),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _addSticker(uid),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(context.l10n.addSticker),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(child: Text(context.l10n.noStickersYet)),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const DecoratedBox(
                          decoration: BoxDecoration(color: Color(0x22111111)),
                          child: Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
