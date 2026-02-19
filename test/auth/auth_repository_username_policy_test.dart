import 'package:chat_app/src/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/presence_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_local_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/repositories_impl/auth_repository_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

class _MockUserLocalDataSource extends Mock implements UserLocalDataSource {}

class _MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}

class _MockPresenceRemoteDataSource extends Mock
    implements PresenceRemoteDataSource {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockFirebaseAuthDataSource authDataSource;
  late _MockUserLocalDataSource userLocalDataSource;
  late _MockUserRemoteDataSource userRemoteDataSource;
  late _MockPresenceRemoteDataSource presenceRemoteDataSource;
  late _MockGoogleSignIn googleSignIn;
  late AuthRepositoryImpl repository;

  setUp(() {
    authDataSource = _MockFirebaseAuthDataSource();
    userLocalDataSource = _MockUserLocalDataSource();
    userRemoteDataSource = _MockUserRemoteDataSource();
    presenceRemoteDataSource = _MockPresenceRemoteDataSource();
    googleSignIn = _MockGoogleSignIn();
    repository = AuthRepositoryImpl(
      authDataSource: authDataSource,
      userLocalDataSource: userLocalDataSource,
      userRemoteDataSource: userRemoteDataSource,
      presenceRemoteDataSource: presenceRemoteDataSource,
      googleSignIn: googleSignIn,
    );
  });

  test('signUp rejects invalid username before firebase auth call', () async {
    expect(
      () => repository.signUp(
        username: 'ab_cd',
        email: 'test@example.com',
        password: 'password123',
      ),
      throwsA(
        isA<FirebaseAuthException>().having(
          (e) => e.message,
          'message',
          'username_latin_only',
        ),
      ),
    );

    verifyNever(
      () => authDataSource.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('updateProfile rejects too-short username', () async {
    final user = _MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => authDataSource.currentUser).thenReturn(user);
    when(
      () => userRemoteDataSource.fetchUser(any()),
    ).thenAnswer((_) async => null);

    expect(
      () => repository.updateProfile(username: 'abc'),
      throwsA(
        isA<FirebaseAuthException>().having(
          (e) => e.message,
          'message',
          'username_min_5',
        ),
      ),
    );
  });
}
