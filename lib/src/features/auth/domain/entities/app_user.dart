import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.bio,
    this.photoUrl,
    this.fcmToken,
    this.createdAt,
    this.phone,
  });

  final String id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? bio;
  final String? photoUrl;
  final String? fcmToken;
  final DateTime? createdAt;
  final String? phone;

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        firstName,
        lastName,
        birthDate,
        bio,
        photoUrl,
        fcmToken,
        createdAt,
        phone,
      ];
}
