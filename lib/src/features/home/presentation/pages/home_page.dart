import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/features/home/presentation/cubit/users_cubit.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;
    final t = context.l10n;

    return BlocProvider(
      create: (_) => sl<UsersCubit>()..start(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0f1b2c), Color(0xFF1b2b4c), Color(0xFF233b6e)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.chatsTitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.read<AuthBloc>().add(
                          const SignOutRequested(),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: user == null
                      ? Center(
                          child: Text(
                            t.notSignedIn,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : BlocBuilder<UsersCubit, UsersState>(
                          builder: (context, state) {
                            if (state.status == UsersStatus.loading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (state.status == UsersStatus.error) {
                              return Center(
                                child: Text(
                                  state.error ?? t.error,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            final otherUsers = state.users
                                .where((u) => u.id != user.id)
                                .toList();

                            if (otherUsers.isEmpty) {
                              return Center(
                                child: Text(
                                  t.noUsers,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: otherUsers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final peer = otherUsers[index];
                                return LiquidGlass.withOwnLayer(
                                  shape: const LiquidRoundedRectangle(
                                    borderRadius: 18,
                                  ),
                                  settings: LiquidGlassSettings(
                                    glassColor: Colors.white.withOpacity(0.08),
                                    blur: 12,
                                    thickness: 18,
                                  ),
                                  fake: true,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.12),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.white
                                            .withOpacity(0.15),
                                        backgroundImage: peer.photoUrl != null
                                            ? NetworkImage(peer.photoUrl!)
                                            : null,
                                        child: peer.photoUrl == null
                                            ? const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        peer.username.isNotEmpty
                                            ? peer.username
                                            : peer.email,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        (peer.bio != null &&
                                                peer.bio!.isNotEmpty)
                                            ? peer.bio!
                                            : peer.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                      onTap: () => context.push(
                                        '/chat/${peer.id}',
                                        extra: peer,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
