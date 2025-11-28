import 'package:chat_app/src/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/repositories_impl/auth_repository_impl.dart';
import 'package:chat_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:chat_app/src/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/src/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:chat_app/src/features/chat/data/local/chat_message_entity.dart';
import 'package:chat_app/src/features/chat/data/repositories_impl/chat_repository_impl.dart';
import 'package:chat_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app/src/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/watch_messages_usecase.dart';
import 'package:chat_app/src/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:chat_app/src/features/home/presentation/cubit/users_cubit.dart';
import 'package:chat_app/src/core/notifications/token_sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ChatMessageEntitySchema],
    directory: dir.path,
    inspector: false,
  );

  sl
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerSingleton<Isar>(isar)
    ..registerLazySingleton<FirebaseAuthDataSource>(
      () => FirebaseAuthDataSource(sl()),
    )
    ..registerLazySingleton<UserRemoteDataSource>(
      () => UserRemoteDataSource(sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () =>
          AuthRepositoryImpl(authDataSource: sl(), userRemoteDataSource: sl()),
    )
    ..registerLazySingleton<SignInUseCase>(() => SignInUseCase(sl()))
    ..registerLazySingleton<SignUpUseCase>(() => SignUpUseCase(sl()))
    ..registerLazySingleton<SignOutUseCase>(() => SignOutUseCase(sl()))
    ..registerLazySingleton<ObserveAuthStateUseCase>(
      () => ObserveAuthStateUseCase(sl()),
    )
    ..registerLazySingleton<SendPhoneOtpUseCase>(
      () => SendPhoneOtpUseCase(sl()),
    )
    ..registerLazySingleton<VerifyPhoneOtpUseCase>(
      () => VerifyPhoneOtpUseCase(sl()),
    )
    ..registerLazySingleton<TokenSyncService>(
      () => TokenSyncService(sl(), sl()),
    )
    ..registerFactory<AuthBloc>(
      () => AuthBloc(
        signInUseCase: sl(),
        signUpUseCase: sl(),
        signOutUseCase: sl(),
        observeAuthStateUseCase: sl(),
        sendPhoneOtpUseCase: sl(),
        verifyPhoneOtpUseCase: sl(),
        tokenSyncService: sl(),
      ),
    )
    ..registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSource(sl()),
    )
    ..registerLazySingleton<ChatLocalDataSource>(
      () => ChatLocalDataSource(sl()),
    )
    ..registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(
        dataSource: sl(),
        firebaseAuth: sl(),
        localDataSource: sl(),
      ),
    )
    ..registerLazySingleton<WatchMessagesUseCase>(
      () => WatchMessagesUseCase(sl()),
    )
    ..registerLazySingleton<SendMessageUseCase>(() => SendMessageUseCase(sl()))
    ..registerFactory<ChatCubit>(
      () => ChatCubit(
        watchMessagesUseCase: sl(),
        sendMessageUseCase: sl(),
        firebaseAuth: sl(),
      ),
    )
    ..registerFactory<UsersCubit>(() => UsersCubit(sl()));
}
