import 'dart:async';

import 'package:chat_app/src/features/chat/data/models/chat_message_model.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_conversation_preview.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  static const _conversationCollection = 'conversations';
  static const defaultPageSize = 40;

  Stream<List<ChatMessageModel>> watchMessages({
    required String conversationId,
    int limit = defaultPageSize,
  }) {
    return Stream.multi((controller) {
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
      var switchedToFallback = false;

      void listenToQuery({required bool withIdOrder}) {
        sub =
            _recentMessagesQuery(
              conversationId: conversationId,
              limit: limit,
              withIdOrder: withIdOrder,
            ).snapshots().listen(
              (snapshot) =>
                  controller.add(_sortAscending(_fromDocs(snapshot.docs))),
              onError: (error, stackTrace) {
                if (withIdOrder && !switchedToFallback) {
                  switchedToFallback = true;
                  unawaited(sub?.cancel());
                  listenToQuery(withIdOrder: false);
                  return;
                }
                controller.addError(error, stackTrace);
              },
            );
      }

      listenToQuery(withIdOrder: true);
      controller.onCancel = () async => sub?.cancel();
    });
  }

  Future<List<ChatMessageModel>> loadOlderMessages({
    required String conversationId,
    required DateTime beforeCreatedAt,
    required String beforeMessageId,
    int limit = defaultPageSize,
  }) async {
    try {
      final snapshot = await _messagesCollection(conversationId)
          .orderBy('createdAt', descending: true)
          .orderBy('id', descending: true)
          .startAfter([Timestamp.fromDate(beforeCreatedAt), beforeMessageId])
          .limit(limit)
          .get();

      return _sortAscending(_fromDocs(snapshot.docs));
    } catch (_) {
      // Fallback when composite index for createdAt+id is not available.
      final snapshot = await _messagesCollection(conversationId)
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(beforeCreatedAt),
          )
          .orderBy('createdAt', descending: true)
          .limit(limit * 2)
          .get();

      final older = _fromDocs(snapshot.docs)
          .where((message) {
            final olderByTime = message.createdAt.isBefore(beforeCreatedAt);
            final sameTimeButOlderId =
                message.createdAt.isAtSameMomentAs(beforeCreatedAt) &&
                message.id.compareTo(beforeMessageId) < 0;
            return olderByTime || sameTimeButOlderId;
          })
          .toList(growable: false);

      return _takeLast(_sortAscending(older), limit);
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required ChatMessageModel message,
  }) async {
    final conversationRef = _firestore
        .collection(_conversationCollection)
        .doc(conversationId);
    final messagesRef = conversationRef.collection('messages');
    final docRef = messagesRef.doc(message.id);

    // Ensure conversation metadata exists for rules/queries.
    final hasText = message.text.trim().isNotEmpty;
    final hasImage = message.imageUrl?.trim().isNotEmpty == true;
    final preview = hasText
        ? message.text
        : hasImage
        ? '📷 Photo'
        : '';

    await conversationRef.set({
      'participants': [message.senderId, message.receiverId]..sort(),
      'lastMessage': preview,
      'lastMessageType': hasImage ? 'image' : 'text',
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
      'lastMessageSenderId': message.senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await conversationRef.update({
      'unreadCounts.${message.senderId}': 0,
      'unreadCounts.${message.receiverId}': FieldValue.increment(1),
    });

    // Use client timestamp for createdAt so the new message appears instantly
    // in the current query; updatedAt still uses server time on conversation.
    await docRef.set(message.toMap(), SetOptions(merge: true));
  }

  Future<void> updateMessageStatus({
    required String conversationId,
    required String messageId,
    required MessageStatus status,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) async {
    final docRef = _firestore
        .collection(_conversationCollection)
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    final updateData = <String, dynamic>{'status': status.name};

    if (deliveredAt != null) {
      updateData['deliveredAt'] = Timestamp.fromDate(deliveredAt);
    }
    if (readAt != null) {
      updateData['readAt'] = Timestamp.fromDate(readAt);
    }

    await docRef.update(updateData);
  }

  Future<void> markMessagesAsDelivered({
    required String conversationId,
    required String receiverId,
  }) async {
    final messagesRef = _firestore
        .collection(_conversationCollection)
        .doc(conversationId)
        .collection('messages');

    final snapshot = await messagesRef
        .where('receiverId', isEqualTo: receiverId)
        .where('status', whereIn: ['sent', 'sending'])
        .get();

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': 'delivered',
        'deliveredAt': Timestamp.fromDate(now),
      });
    }

    await batch.commit();
  }

  Future<void> markMessagesAsRead({
    required String conversationId,
    required String receiverId,
  }) async {
    final messagesRef = _firestore
        .collection(_conversationCollection)
        .doc(conversationId)
        .collection('messages');

    final snapshot = await messagesRef
        .where('receiverId', isEqualTo: receiverId)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': 'read',
        'readAt': Timestamp.fromDate(now),
      });
    }

    await batch.commit();
  }

  Future<void> markConversationRead({
    required String conversationId,
    required String userId,
  }) async {
    final ref = _firestore
        .collection(_conversationCollection)
        .doc(conversationId);
    try {
      await ref.update({
        'unreadCounts.$userId': 0,
        'lastReadAt.$userId': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await ref.set({
        'unreadCounts': {userId: 0},
        'lastReadAt': {userId: FieldValue.serverTimestamp()},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Stream<Map<String, int>> watchUnreadCountsByPeer({required String userId}) {
    return _firestore
        .collection(_conversationCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final byPeer = <String, int>{};

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final participantsRaw = data['participants'];
            if (participantsRaw is! List) continue;

            String? peerId;
            for (final part in participantsRaw) {
              final id = part.toString();
              if (id != userId) {
                peerId = id;
                break;
              }
            }
            if (peerId == null || peerId.isEmpty) continue;

            var unread = 0;
            final unreadRaw = data['unreadCounts'];
            if (unreadRaw is Map) {
              final value = unreadRaw[userId];
              if (value is num) {
                unread = value.toInt();
              } else if (value is String) {
                unread = int.tryParse(value) ?? 0;
              }
            }
            if (unread < 0) unread = 0;

            final current = byPeer[peerId] ?? 0;
            if (unread > current) {
              byPeer[peerId] = unread;
            }
          }

          return byPeer;
        });
  }

  Stream<Map<String, ChatConversationPreview>> watchConversationPreviewsByPeer({
    required String userId,
  }) {
    return _firestore
        .collection(_conversationCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final byPeer = <String, ChatConversationPreview>{};

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final participantsRaw = data['participants'];
            if (participantsRaw is! List) continue;

            String? peerId;
            for (final part in participantsRaw) {
              final id = part.toString();
              if (id != userId) {
                peerId = id;
                break;
              }
            }
            if (peerId == null || peerId.isEmpty) continue;

            var unread = 0;
            final unreadRaw = data['unreadCounts'];
            if (unreadRaw is Map) {
              final value = unreadRaw[userId];
              if (value is num) {
                unread = value.toInt();
              } else if (value is String) {
                unread = int.tryParse(value) ?? 0;
              }
            }
            if (unread < 0) unread = 0;

            final lastMessageText =
                (data['lastMessage'] as String?)?.trim() ?? '';
            final lastMessageType = (data['lastMessageType'] as String?)
                ?.trim();
            final lastMessage = lastMessageText.isNotEmpty
                ? lastMessageText
                : (lastMessageType == 'image' ? '📷 Photo' : '');
            final lastMessageAt = _readTimestampOrInt(
              data['lastMessageAt'] ?? data['updatedAt'],
            );
            final lastMessageSenderId = (data['lastMessageSenderId'] as String?)
                ?.trim();

            final candidate = ChatConversationPreview(
              peerId: peerId,
              lastMessage: lastMessage,
              lastMessageAt: lastMessageAt,
              lastMessageSenderId: lastMessageSenderId,
              unreadCount: unread,
            );

            final current = byPeer[peerId];
            if (current == null) {
              byPeer[peerId] = candidate;
              continue;
            }

            final currentTime = current.lastMessageAt;
            final candidateTime = candidate.lastMessageAt;
            final candidateIsNewer =
                candidateTime != null &&
                (currentTime == null || candidateTime.isAfter(currentTime));

            if (candidateIsNewer) {
              byPeer[peerId] = candidate;
            } else if (candidate.unreadCount > current.unreadCount) {
              byPeer[peerId] = ChatConversationPreview(
                peerId: current.peerId,
                lastMessage: current.lastMessage,
                lastMessageAt: current.lastMessageAt,
                lastMessageSenderId: current.lastMessageSenderId,
                unreadCount: candidate.unreadCount,
              );
            }
          }

          return byPeer;
        });
  }

  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String conversationId,
  ) {
    return _firestore
        .collection(_conversationCollection)
        .doc(conversationId)
        .collection('messages');
  }

  Query<Map<String, dynamic>> _recentMessagesQuery({
    required String conversationId,
    required int limit,
    required bool withIdOrder,
  }) {
    var query = _messagesCollection(
      conversationId,
    ).orderBy('createdAt', descending: true);
    if (withIdOrder) {
      query = query.orderBy('id', descending: true);
    }
    return query.limit(limit);
  }

  List<ChatMessageModel> _fromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) => ChatMessageModel.fromFirestore(doc))
        .toList(growable: false);
  }

  List<ChatMessageModel> _sortAscending(List<ChatMessageModel> input) {
    final sorted = List<ChatMessageModel>.of(input);
    sorted.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  List<ChatMessageModel> _takeLast(List<ChatMessageModel> input, int limit) {
    if (limit <= 0 || input.length <= limit) {
      return input;
    }
    return input.sublist(input.length - limit);
  }

  DateTime? _readTimestampOrInt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
