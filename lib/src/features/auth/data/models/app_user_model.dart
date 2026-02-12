import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    required super.username,
    super.firstName,
    super.lastName,
    super.birthDate,
    super.bio,
    super.photoUrl,
    super.fcmToken,
    super.createdAt,
    super.phone,
    super.isOnline,
    super.lastSeen,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'birthDate': birthDate?.millisecondsSinceEpoch,
        'bio': bio,
        'photoUrl': photoUrl,
        'fcmToken': fcmToken,
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'phone': phone,
        'isOnline': isOnline,
        'lastSeen': lastSeen?.millisecondsSinceEpoch,
      };

  factory AppUserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('User document is empty for id ${doc.id}');
    }
    return AppUserModel(
      id: data['id'] as String? ?? doc.id,
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      birthDate: (data['birthDate'] as int?) != null
          ? DateTime.fromMillisecondsSinceEpoch(data['birthDate'] as int)
          : null,
      bio: data['bio'] as String?,
      photoUrl: data['photoUrl'] as String?,
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as int?) != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : null,
      phone: data['phone'] as String?,
      isOnline: data['isOnline'] as bool?,
      lastSeen: _readTimestampOrInt(data['lastSeen']),
    );
  }

  factory AppUserModel.fromFirebaseUser(User user) => AppUserModel(
        id: user.uid,
        email: user.email ?? '',
        username: user.displayName ?? '',
        firstName: user.displayName,
        lastName: null,
        birthDate: null,
        bio: null,
        photoUrl: user.photoURL,
        fcmToken: null,
        createdAt: user.metadata.creationTime,
        phone: user.phoneNumber,
        isOnline: true,
        lastSeen: DateTime.now(),
      );

  static DateTime? _readTimestampOrInt(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
