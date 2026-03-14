import 'package:flutter/material.dart';

import '../../services/user_service.dart';

// Halaman untuk teacher mengelola role user (student <-> teacher).
class ManageRolesPage extends StatefulWidget {
  const ManageRolesPage({super.key});

  @override
  State<ManageRolesPage> createState() => _ManageRolesPageState();
}

class _ManageRolesPageState extends State<ManageRolesPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Ambil semua user dari Firestore.
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await UserService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  // Cari user berdasarkan email. Kalau kosong, tampilkan semua.
  Future<void> _searchByEmail() async {
    final email = _searchController.text.trim();
    if (email.isEmpty) {
      _loadUsers();
      return;
    }

    setState(() => _isLoading = true);
    final users = await UserService.searchUsersByEmail(email);
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  // Toggle role user (student <-> teacher) dengan dialog konfirmasi.
  Future<void> _changeRole(String uid, String currentRole) async {
    final newRole = currentRole == 'teacher' ? 'student' : 'teacher';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Role'),
        content: Text('Ubah role user ini menjadi "$newRole"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ubah'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await UserService.updateUserRole(uid, newRole);
      _searchController.text.trim().isEmpty ? _loadUsers() : _searchByEmail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Role')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari berdasarkan email',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchByEmail,
                ),
              ),
              onSubmitted: (_) => _searchByEmail(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('Tidak ada user ditemukan.'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final role = user['role'] ?? 'student';
                          final isTeacher = role == 'teacher';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isTeacher ? Colors.deepPurple : Colors.grey,
                              child: Icon(
                                isTeacher ? Icons.school : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(user['email'] ?? '-'),
                            subtitle: Text(
                              'Role: $role'
                              '${user['displayName'] != null && user['displayName'] != '' ? ' | ${user['displayName']}' : ''}',
                            ),
                            trailing: TextButton(
                              onPressed: () =>
                                  _changeRole(user['uid'], role),
                              child: Text(
                                isTeacher
                                    ? 'Jadikan Student'
                                    : 'Jadikan Teacher',
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
