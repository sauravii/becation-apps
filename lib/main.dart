import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'features/auth/firebase_options.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/home/manage_roles_page.dart';
import 'services/user_service.dart';

// Inisialisasi Firebase & Google Sign-In, lalu jalankan app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize();

  runApp(const MyApp());
}

// Root widget, setup tema dan routing awal ke AuthGate.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Becation Apps',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

// Cek status login user. Kalau sudah login -> HomePage, belum -> Login/Register.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showLogin = true;
  bool _showRegisterSuccess = false;
  // Flag untuk mencegah AuthGate navigasi ke HomePage saat proses auth async
  // (register / login Google) sedang berjalan. Tanpa flag ini, StreamBuilder
  // akan sempat menampilkan HomePage sesaat sebelum signOut selesai.
  bool _pendingAuthAction = false;
  String? _lastProcessedUid;

  // Cache stream agar StreamBuilder tidak re-subscribe saat AuthGate rebuild
  // (re-subscribe menyebabkan connectionState kembali ke waiting → widget
  // child sesaat diganti loading Scaffold → State child dihancurkan).
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  // Toggle antara halaman Login dan Register.
  void _toggleAuthScreen() {
    setState(() {
      _showLogin = !_showLogin;
      _showRegisterSuccess = false;
      _pendingAuthAction = false;
    });
  }

  // Dipanggil oleh LoginPage/RegisterPage untuk menandai bahwa proses auth
  // async sedang berjalan (true) atau sudah selesai (false).
  // Saat pending=true: hanya set flag tanpa rebuild, agar StreamBuilder tidak
  // re-run builder prematur dan menghancurkan State child.
  // Saat pending=false: panggil setState untuk trigger rebuild.
  void _setAuthActionPending(bool pending) {
    _pendingAuthAction = pending;
    if (!pending) {
      setState(() {});
    }
  }

  // Dipanggil setelah register berhasil. Reset flag, arahkan ke halaman login,
  // dan tampilkan pesan sukses.
  void _onRegisterSuccess() {
    setState(() {
      _pendingAuthAction = false;
      _showLogin = true;
      _showRegisterSuccess = true;
    });
  }

  // Jalankan ensureUserDocument sekali per sign-in (bukan tiap rebuild).
  void _onAuthUserChanged(User? user) {
    if (user != null && user.uid != _lastProcessedUid) {
      _lastProcessedUid = user.uid;
      UserService.ensureUserDocument(user).catchError((e) {
        debugPrint('[AuthGate] ensureUserDocument failed: $e');
      });
    } else if (user == null) {
      _lastProcessedUid = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Tampilkan HomePage hanya jika user sudah login DAN tidak ada
        // proses auth async yang sedang berjalan.
        if (snapshot.hasData && !_pendingAuthAction) {
          _onAuthUserChanged(snapshot.data);
          _showRegisterSuccess = false;
          return const HomePage();
        }

        if (!snapshot.hasData) {
          _onAuthUserChanged(null);
        }

        if (_showLogin) {
          return LoginPage(
            onRegisterPressed: _toggleAuthScreen,
            onSetAuthActionPending: _setAuthActionPending,
            showRegistrationSuccess: _showRegisterSuccess,
          );
        }

        return RegisterPage(
          onLoginPressed: _toggleAuthScreen,
          onSetAuthActionPending: _setAuthActionPending,
          onRegisterSuccess: _onRegisterSuccess,
        );
      },
    );
  }
}

// Halaman utama setelah login. Tampilan berubah sesuai role (teacher/student) secara realtime.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data();
        final role = data?['role'] ?? 'student';
        final isTeacher = role == 'teacher';

        return Scaffold(
          appBar: AppBar(
            title: Text(isTeacher ? 'Dashboard Teacher' : 'Dashboard Student'),
            actions: [
              IconButton(
                onPressed: () async {
                  await GoogleSignIn.instance.signOut();
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isTeacher ? Colors.deepPurple : Colors.blueGrey,
                      child: Icon(
                        isTeacher ? Icons.school : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(user.email ?? '-'),
                    subtitle: Text(
                      'Role: ${isTeacher ? 'Teacher' : 'Student'}',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (isTeacher) ...[
                  Text(
                    'Menu Teacher',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageRolesPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Kelola Role User'),
                  ),
                ] else ...[
                  Text(
                    'Menu Student',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text('Selamat datang! Fitur LMS akan segera hadir.'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
