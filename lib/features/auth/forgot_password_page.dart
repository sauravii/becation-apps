import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Halaman reset password. Kirim link reset ke email user via Firebase Auth.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Kirim email reset password via Firebase Auth.
  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      setState(() {
        _isSuccess = true;
        _message = 'Link reset password sudah dikirim ke email kamu. Cek inbox atau folder spam.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isSuccess = false;
        _message = _mapError(e.code);
      });
    } catch (_) {
      setState(() {
        _isSuccess = false;
        _message = 'Terjadi kesalahan. Coba lagi sebentar.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Konversi kode error Firebase Auth ke pesan user-friendly.
  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak terdaftar.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Gagal mengirim email reset. Coba lagi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
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
                    'Reset Password',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan email kamu, kami akan kirimkan link untuk reset password.',
                    style: TextStyle(color: Colors.grey.shade600),
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
                      if (text.isEmpty) return 'Email wajib diisi.';
                      if (!text.contains('@')) return 'Masukkan email yang valid.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_message != null)
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _isSuccess
                            ? Colors.green.shade700
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetEmail,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kirim Link Reset'),
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
