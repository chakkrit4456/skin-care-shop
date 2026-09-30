import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/l10n.dart';
import '../../core/live.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

final _usersProvider = FutureProvider<List<Profile>>((ref) async {
  refreshOnLive(ref, {'users'});
  final rows = await api.get('/admin/users') as List;
  return rows.map((r) => Profile.fromJson(r)).toList();
});

const _roleKeys = {'customer': 'role_customer', 'vip': 'role_vip', 'admin': 'role_admin'};

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _q = '';

  Future<void> _setRole(Profile u, String role) async {
    try {
      await api.patch('/admin/users/${u.id}', {'role': role});
      ref.invalidate(_usersProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(profileProvider).valueOrNull?.id;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          decoration: InputDecoration(hintText: t(context, 'search_members'), prefixIcon: const Icon(Icons.search)),
          onChanged: (v) => setState(() => _q = v.toLowerCase()),
        ),
      ),
      Expanded(
        child: ref.watch(_usersProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (all) {
                final list = all.where((u) => '${u.name} ${u.username} ${u.phone ?? ''}'.toLowerCase().contains(_q)).toList();
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final u = list[i];
                    return ListTile(
                      leading: UserAvatar(url: u.avatarUrl, username: u.username),
                      title: Text(u.name.isEmpty ? u.username : u.name),
                      subtitle: Text('@${u.username}${u.phone == null || u.phone!.isEmpty ? '' : ' · ${u.phone}'}'),
                      trailing: DropdownButton<String>(
                        value: u.role,
                        items: [for (final e in _roleKeys.entries) DropdownMenuItem(value: e.key, child: Text(t(context, e.value)))],
                        onChanged: u.id == me ? null : (v) => _setRole(u, v!),
                      ),
                    );
                  },
                );
              },
            ),
      ),
    ]);
  }
}
