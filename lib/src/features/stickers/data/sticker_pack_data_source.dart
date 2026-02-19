import 'package:chat_app/src/features/stickers/domain/sticker_pack.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StickerPackDataSource {
  StickerPackDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  static const _collection = 'stickers';

  Stream<StickerPack?> watchPack(String uid) {
    return _firestore.collection(_collection).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return _toPack(uid, data);
    });
  }

  Future<StickerPack?> fetchPack(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return _toPack(uid, data);
  }

  Future<void> upsertTitle({required String uid, required String title}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _firestore.collection(_collection).doc(uid).set({
      'title': title.trim().isEmpty ? 'My Stickers' : title.trim(),
      'createdAt': now,
      'itemsCount': FieldValue.increment(0),
    }, SetOptions(merge: true));
  }

  Future<StickerItem> addSticker({
    required String uid,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = _extensionFromName(file.name);
    final itemId = _uuid.v4();
    final storageRef = _storage.ref('stickers/$uid/$itemId.$ext');
    await storageRef.putData(
      bytes,
      SettableMetadata(contentType: _mimeFromExtension(ext)),
    );
    final url = await storageRef.getDownloadURL();
    final item = StickerItem(id: itemId, url: url, createdAt: DateTime.now());

    final packRef = _firestore.collection(_collection).doc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(packRef);
      final data = snap.data();
      final currentItemsRaw = data?['items'];
      final currentItems = <Map<String, dynamic>>[];
      if (currentItemsRaw is List) {
        for (final value in currentItemsRaw) {
          if (value is Map) {
            currentItems.add(Map<String, dynamic>.from(value));
          }
        }
      }
      currentItems.add(item.toMap());
      final existingTitle = (data?['title'] as String?)?.trim();
      tx.set(packRef, {
        'title': (existingTitle != null && existingTitle.isNotEmpty)
            ? existingTitle
            : 'My Stickers',
        'createdAt':
            (data?['createdAt'] as int?) ??
            DateTime.now().millisecondsSinceEpoch,
        'items': currentItems,
        'itemsCount': currentItems.length,
      }, SetOptions(merge: true));
    });

    return item;
  }

  StickerPack _toPack(String uid, Map<String, dynamic> data) {
    final items = <StickerItem>[];
    final raw = data['items'];
    if (raw is List) {
      for (final value in raw) {
        if (value is Map) {
          final item = StickerItem.fromMap(Map<String, dynamic>.from(value));
          if (item.url.isNotEmpty) {
            items.add(item);
          }
        }
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final title = (data['title'] as String?)?.trim();

    return StickerPack(
      ownerId: uid,
      title: (title != null && title.isNotEmpty) ? title : 'My Stickers',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      items: items,
    );
  }

  String _extensionFromName(String fileName) {
    final normalized = fileName.toLowerCase();
    if (normalized.endsWith('.png')) return 'png';
    if (normalized.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  String _mimeFromExtension(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
