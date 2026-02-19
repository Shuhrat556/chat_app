import 'package:equatable/equatable.dart';

class StickerItem extends Equatable {
  const StickerItem({
    required this.id,
    required this.url,
    required this.createdAt,
  });

  final String id;
  final String url;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory StickerItem.fromMap(Map<String, dynamic> map) {
    return StickerItem(
      id: map['id'] as String? ?? '',
      url: map['url'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  List<Object?> get props => [id, url, createdAt];
}

class StickerPack extends Equatable {
  const StickerPack({
    required this.ownerId,
    required this.title,
    required this.createdAt,
    required this.items,
  });

  final String ownerId;
  final String title;
  final DateTime createdAt;
  final List<StickerItem> items;

  StickerPack copyWith({
    String? ownerId,
    String? title,
    DateTime? createdAt,
    List<StickerItem>? items,
  }) {
    return StickerPack(
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [ownerId, title, createdAt, items];
}
