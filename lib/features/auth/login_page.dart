import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/user_service.dart';
import 'forgot_password_page.dart';

// Halaman login. Mendukung login via email/password dan Google.
// Google login akan validasi apakah akun sudah terdaftar di Firestore sebelum
// mengizinkan masuk.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onRegisterPressed,
    required this.onSetAuthActionPending,
    this.showRegistrationSuccess = false,
  });

  final VoidCallback onRegisterPressed;
  // Callback untuk menandai proses auth async sedang berjalan/selesai di AuthGate.
  final ValueChanged<bool> onSetAuthActionPending;
  // Jika true, tampilkan banner sukses registrasi di atas form.
  final bool showRegistrationSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login pakai email & password, lalu simpan/update user doc di Firestore.
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await UserService.ensureUserDocument(result.user!);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapAuthError(e.code);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan. Coba lagi sebentar.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Login pakai Google Sign-In dengan validasi: hanya izinkan masuk jika akun
  // sudah terdaftar di Firestore. Jika belum terdaftar, sign out dan tampilkan error.
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    // Cegah AuthGate navigasi ke HomePage selama proses validasi.
    widget.onSetAuthActionPending(true);

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Validasi: cek apakah akun Google ini sudah terdaftar di Firestore.
      final isRegistered =
          await UserService.isUserRegistered(result.user!.uid);
      if (!isRegistered) {
        // Belum terdaftar → tampilkan dialog SEBELUM sign out agar context
        // masih valid (sign out men-trigger AuthGate rebuild yang bisa
        // menghancurkan widget State).
        bool goToRegister = false;
        if (mounted) {
          goToRegister = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: const Text('Email Belum Terdaftar'),
                  content: const Text(
                    'Akun Google ini belum terdaftar. '
                    'Silakan register terlebih dahulu.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ) ??
              false;
        }

        // Sign out setelah dialog ditutup.
        await GoogleSignIn.instance.signOut();
        await FirebaseAuth.instance.signOut();

        // Jika user pilih Register, arahkan ke halaman register.
        if (goToRegister && mounted) {
          widget.onRegisterPressed();
        }
        return;
      }

      // Sudah terdaftar → update lastLogin dan biarkan AuthGate tampilkan HomePage.
      await UserService.ensureUserDocument(result.user!);
      widget.onSetAuthActionPending(false);
    } on GoogleSignInException catch (_) {
      // Google auth dibatalkan user, belum sampai Firebase sign-in.
      if (mounted) {
        setState(() {
          _errorMessage = 'Login dengan Google dibatalkan.';
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
      // Sign out jika user sempat ter-sign in sebelum error
      // (misal ensureUserDocument gagal setelah signInWithCredential berhasil).
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal login dengan Google. Coba lagi.';
        });
      }
    } finally {
      // Reset pending flag untuk semua error/cancel cases.
      widget.onSetAuthActionPending(false);
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  // Konversi kode error Firebase Auth ke pesan yang user-friendly (Bahasa Indonesia).
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Coba lagi nanti.';
      default:
        return 'Gagal login. Silakan coba lagi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
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
                  // Banner sukses registrasi, ditampilkan setelah user berhasil register.
                  if (widget.showRegistrationSuccess)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        'Registrasi berhasil! Silakan login dengan akun yang sudah didaftarkan.',
                        style: TextStyle(color: Colors.green.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Text(
                    'Masuk ke akun kamu',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
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
                          setState(() => _obscurePassword = !_obscurePassword);
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
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: const Text('Lupa Password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        : _loginWithGoogle,
                    icon: _isGoogleLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Image.asset('assets/images/google_logo.png',
                            height: 20),
                    label: const Text('Login dengan Google'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed:
                        _isLoading ? null : widget.onRegisterPressed,
                    child: const Text('Belum punya akun? Register'),
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
