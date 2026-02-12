import 'dart:convert';
import 'dart:io';

import 'package:chat_app/src/features/auth/data/models/app_user_model.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:path_provider/path_provider.dart';

class UserLocalDataSource {
  static const _cacheFileName = 'auth_user_cache.json';

  Future<void> saveUser(AppUser user) async {
    final file = await _cacheFile();
    if (file == null) return;

    final payload = _toMap(user);
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<AppUserModel?> fetchCachedUser(String expectedUserId) async {
    final file = await _cacheFile();
    if (file == null || !await file.exists()) return null;

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final userId = (decoded['id'] as String?) ?? '';
      if (userId != expectedUserId) return null;
      return _fromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final file = await _cacheFile();
    if (file == null || !await file.exists()) return;
    try {
      await file.delete();
    } catch (_) {
      // Ignore local cleanup failures.
    }
  }

  Future<File?> _cacheFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return File('${directory.path}/$_cacheFileName');
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toMap(AppUser user) {
    if (user is AppUserModel) return user.toMap();
    return {
      'id': user.id,
      'email': user.email,
      'username': user.username,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'birthDate': user.birthDate?.millisecondsSinceEpoch,
      'bio': user.bio,
      'photoUrl': user.photoUrl,
      'fcmToken': user.fcmToken,
      'createdAt': user.createdAt?.millisecondsSinceEpoch,
      'phone': user.phone,
      'isOnline': user.isOnline,
      'lastSeen': user.lastSeen?.millisecondsSinceEpoch,
    };
  }

  AppUserModel _fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? '',
      firstName: map['firstName'] as String?,
      lastName: map['lastName'] as String?,
      birthDate: _dateFromMillis(map['birthDate']),
      bio: map['bio'] as String?,
      photoUrl: map['photoUrl'] as String?,
      fcmToken: map['fcmToken'] as String?,
      createdAt: _dateFromMillis(map['createdAt']),
      phone: map['phone'] as String?,
      isOnline: map['isOnline'] as bool?,
      lastSeen: _dateFromMillis(map['lastSeen']),
    );
  }

  DateTime? _dateFromMillis(dynamic value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
