import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/user_service.dart';

// Halaman register. Mendukung daftar via email/password dan Google.
// Setelah register berhasil, user akan di-sign out dan diarahkan ke halaman
// login (tidak auto-login).
class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onLoginPressed,
    required this.onSetAuthActionPending,
    required this.onRegisterSuccess,
  });

  final VoidCallback onLoginPressed;
  // Callback untuk menandai proses auth async sedang berjalan/selesai di AuthGate.
  final ValueChanged<bool> onSetAuthActionPending;
  // Dipanggil setelah register berhasil & sign out — AuthGate akan menampilkan
  // halaman login dengan pesan sukses.
  final VoidCallback onRegisterSuccess;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Register akun baru pakai email & password. Setelah berhasil, buat user doc
  // di Firestore, sign out, lalu arahkan ke halaman login dengan pesan sukses.
  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Cegah AuthGate navigasi ke HomePage saat createUser otomatis sign-in.
    widget.onSetAuthActionPending(true);

    try {
      final result =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await UserService.ensureUserDocument(
        result.user!,
        displayName: _nameController.text.trim(),
      );

      // Sign out agar user harus login manual setelah register.
      await FirebaseAuth.instance.signOut();

      // Arahkan ke halaman login dengan pesan sukses.
      widget.onRegisterSuccess();
    } on FirebaseAuthException catch (e) {
      // createUserWithEmailAndPassword gagal → user belum ter-sign in.
      if (mounted) {
        setState(() {
          _errorMessage = _mapAuthError(e.code);
        });
      }
    } catch (_) {
      // Sign out jika user sempat ter-sign in (createUser berhasil tapi
      // ensureUserDocument gagal) agar tidak stuck di HomePage tanpa Firestore doc.
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan. Coba lagi sebentar.';
        });
      }
    } finally {
      if (mounted) {
        widget.onSetAuthActionPending(false);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Daftar pakai Google Sign-In. Jika akun Google sudah terdaftar di Firestore,
  // tampilkan error. Jika belum, buat doc user, sign out, lalu arahkan ke login.
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    // Cegah AuthGate navigasi ke HomePage selama proses registrasi.
    widget.onSetAuthActionPending(true);

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Cek apakah akun Google ini sudah pernah terdaftar.
      final isRegistered =
          await UserService.isUserRegistered(result.user!.uid);
      if (isRegistered) {
        // Sudah terdaftar → tampilkan dialog SEBELUM sign out agar context
        // masih valid (sign out men-trigger AuthGate rebuild yang bisa
        // menghancurkan widget State).
        bool goToLogin = false;
        if (mounted) {
          goToLogin = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: const Text('Akun Sudah Terdaftar'),
                  content: const Text(
                    'Akun Google ini sudah terdaftar. '
                    'Silakan login dengan akun ini.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ) ??
              false;
        }

        // Sign out setelah dialog ditutup.
        await GoogleSignIn.instance.signOut();
        await FirebaseAuth.instance.signOut();

        // Jika user pilih Login, arahkan ke halaman login.
        if (goToLogin && mounted) {
          widget.onLoginPressed();
        }
        return;
      }

      // Belum terdaftar → buat doc user di Firestore.
      await UserService.ensureUserDocument(result.user!);

      // Sign out agar user harus login manual setelah register.
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();

      // Arahkan ke halaman login dengan pesan sukses.
      widget.onRegisterSuccess();
    } on GoogleSignInException catch (_) {
      // Google auth dibatalkan user, belum sampai Firebase sign-in.
      if (mounted) {
        setState(() {
          _errorMessage = 'Daftar dengan Google dibatalkan.';
        });
      }
    } on FirebaseAuthException catch (e) {
      // Sign out jika user sempat ter-sign in sebelum error.
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() {
          _errorMessage = _mapAuthError(e.code);
        });
      }
    } catch (_) {
      // Sign out jika user sempat ter-sign in (signInWithCredential berhasil tapi
      // ensureUserDocument gagal) agar tidak stuck di HomePage tanpa Firestore doc.
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal daftar dengan Google. Coba lagi.';
        });
      }
    } finally {
      if (mounted) {
        widget.onSetAuthActionPending(false);
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  // Konversi kode error Firebase Auth ke pesan yang user-friendly (Bahasa Indonesia).
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email ini sudah dipakai akun lain.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Gagal register. Silakan coba lagi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Buat akun baru',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return 'Nama wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return 'Email wajib diisi.';
                      }
                      if (!text.contains('@')) {
                        return 'Masukkan email yang valid.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(
                              () => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return 'Password wajib diisi.';
                      }
                      if (text.length < 6) {
                        return 'Password minimal 6 karakter.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword =
                              !_obscureConfirmPassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      final confirmText = (value ?? '').trim();
                      if (confirmText.isEmpty) {
                        return 'Konfirmasi password wajib diisi.';
                      }
                      if (confirmText !=
                          _passwordController.text.trim()) {
                        return 'Konfirmasi password tidak sama.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Register'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'atau',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: (_isLoading || _isGoogleLoading)
                        ? null
                        : _signInWithGoogle,
                    icon: _isGoogleLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Image.asset('assets/images/google_logo.png',
                            height: 20),
                    label: const Text('Daftar dengan Google'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed:
                        _isLoading ? null : widget.onLoginPressed,
                    child: const Text('Sudah punya akun? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
