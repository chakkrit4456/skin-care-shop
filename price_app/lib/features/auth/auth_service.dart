import '../../core/api.dart';

final usernamePattern = RegExp(r'^[a-zA-Z0-9_.]{3,30}$');

Future<void> signIn(String username, String password) async {
  final r = await api.post('/auth/login', {'username': username.trim(), 'password': password});
  await api.setToken(r['token']);
}

Future<void> signUp({required String name, required String username, required String password, String? phone}) async {
  final r = await api.post('/auth/register', {
    'name': name.trim(),
    'username': username.trim(),
    'password': password,
    'phone': phone?.trim(),
  });
  await api.setToken(r['token']);
}

Future<void> signOut() => api.setToken(null);
