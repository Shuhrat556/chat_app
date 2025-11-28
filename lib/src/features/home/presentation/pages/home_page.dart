import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/features/home/presentation/cubit/users_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    return BlocProvider(
      create: (_) => sl<UsersCubit>()..start(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(user != null ? 'Salom, ${user.username}' : 'Chat App'),
          actions: [
            IconButton(
              onPressed: () =>
                  context.read<AuthBloc>().add(const SignOutRequested()),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: user == null
            ? const Center(child: Text('Tizimga kirmagansiz'))
            : BlocBuilder<UsersCubit, UsersState>(
                builder: (context, state) {
                  if (state.status == UsersStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == UsersStatus.error) {
                    return Center(child: Text(state.error ?? 'Xatolik'));
                  }

                  final otherUsers =
                      state.users.where((u) => u.id != user.id).toList();

                  if (otherUsers.isEmpty) {
                    return const Center(
                      child: Text('Hozircha boshqa foydalanuvchi yo‘q'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: otherUsers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final peer = otherUsers[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(peer.username.isNotEmpty ? peer.username : peer.email),
                        subtitle: Text(peer.email),
                        onTap: () => context.push('/chat/${peer.id}', extra: peer),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
