import 'package:chat_app/src/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_local_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/presence_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/repositories_impl/auth_repository_impl.dart';
import 'package:chat_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:chat_app/src/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_in_with_apple_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:chat_app/src/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/src/features/chat/data/repositories_impl/chat_repository_impl.dart';
import 'package:chat_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app/src/features/chat/domain/usecases/load_older_messages_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/watch_messages_usecase.dart';
import 'package:chat_app/src/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:chat_app/src/features/home/presentation/cubit/users_cubit.dart';
import 'package:chat_app/src/core/notifications/token_sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() {
      final firestore = FirebaseFirestore.instance;
      firestore.settings = const Settings(persistenceEnabled: true);
      return firestore;
    })
    ..registerLazySingleton<FirebaseDatabase>(() => FirebaseDatabase.instance)
    ..registerLazySingleton<FirebaseAuthDataSource>(
      () => FirebaseAuthDataSource(sl()),
    )
    ..registerLazySingleton<UserRemoteDataSource>(
      () => UserRemoteDataSource(sl()),
    )
    ..registerLazySingleton<UserLocalDataSource>(UserLocalDataSource.new)
    ..registerLazySingleton<PresenceRemoteDataSource>(
      () => PresenceRemoteDataSource(sl(), sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        authDataSource: sl(),
        userLocalDataSource: sl(),
        userRemoteDataSource: sl(),
        presenceRemoteDataSource: sl(),
      ),
    )
    ..registerLazySingleton<SignInUseCase>(() => SignInUseCase(sl()))
    ..registerLazySingleton<SignInWithGoogleUseCase>(
      () => SignInWithGoogleUseCase(sl()),
    )
    ..registerLazySingleton<SignInWithAppleUseCase>(
      () => SignInWithAppleUseCase(sl()),
    )
    ..registerLazySingleton<SignUpUseCase>(() => SignUpUseCase(sl()))
    ..registerLazySingleton<SignOutUseCase>(() => SignOutUseCase(sl()))
    ..registerLazySingleton<ObserveAuthStateUseCase>(
      () => ObserveAuthStateUseCase(sl()),
    )
    ..registerLazySingleton<UpdateProfileUseCase>(
      () => UpdateProfileUseCase(sl()),
    )
    ..registerLazySingleton<DeleteAccountUseCase>(
      () => DeleteAccountUseCase(sl()),
    )
    ..registerLazySingleton<SendPhoneOtpUseCase>(
      () => SendPhoneOtpUseCase(sl()),
    )
    ..registerLazySingleton<VerifyPhoneOtpUseCase>(
      () => VerifyPhoneOtpUseCase(sl()),
    )
    ..registerLazySingleton<SendPasswordResetUseCase>(
      () => SendPasswordResetUseCase(sl()),
    )
    ..registerLazySingleton<TokenSyncService>(
      () => TokenSyncService(sl(), sl()),
    )
    ..registerFactory<AuthBloc>(
      () => AuthBloc(
        signInUseCase: sl(),
        signInWithGoogleUseCase: sl(),
        signInWithAppleUseCase: sl(),
        signUpUseCase: sl(),
        signOutUseCase: sl(),
        sendPasswordResetUseCase: sl(),
        observeAuthStateUseCase: sl(),
        sendPhoneOtpUseCase: sl(),
        verifyPhoneOtpUseCase: sl(),
        updateProfileUseCase: sl(),
        deleteAccountUseCase: sl(),
        tokenSyncService: sl(),
      ),
    )
    ..registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSource(sl()),
    )
    ..registerLazySingleton<ChatLocalDataSource>(ChatLocalDataSource.new)
    ..registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(
        localDataSource: sl(),
        dataSource: sl(),
        firebaseAuth: sl(),
      ),
    )
    ..registerLazySingleton<WatchMessagesUseCase>(
      () => WatchMessagesUseCase(sl()),
    )
    ..registerLazySingleton<LoadOlderMessagesUseCase>(
      () => LoadOlderMessagesUseCase(sl()),
    )
    ..registerLazySingleton<SendMessageUseCase>(() => SendMessageUseCase(sl()))
    ..registerFactory<ChatCubit>(
      () => ChatCubit(
        watchMessagesUseCase: sl(),
        loadOlderMessagesUseCase: sl(),
        sendMessageUseCase: sl(),
        firebaseAuth: sl(),
      ),
    )
    ..registerFactory<UsersCubit>(() => UsersCubit(sl()));
}
