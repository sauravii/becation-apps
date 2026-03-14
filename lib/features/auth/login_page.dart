import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/user_service.dart';
import 'forgot_password_page.dart';

// Halaman login. Mendukung login via email/password dan Google.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onRegisterPressed});

  final VoidCallback onRegisterPressed;

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
      setState(() {
        _errorMessage = _mapAuthError(e.code);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan. Coba lagi sebentar.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Login pakai Google Sign-In, lalu simpan/update user doc di Firestore.
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      await UserService.ensureUserDocument(result.user!);
    } on GoogleSignInException catch (_) {
      // User cancelled or other Google Sign-In error
      setState(() {
        _errorMessage = 'Login dengan Google dibatalkan.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _mapAuthError(e.code);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Gagal login dengan Google. Coba lagi.';
      });
    } finally {
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
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Image.asset('assets/images/google_logo.png', height: 20),
                    label: const Text('Login dengan Google'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading ? null : widget.onRegisterPressed,
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

