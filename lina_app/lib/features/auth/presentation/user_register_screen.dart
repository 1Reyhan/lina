import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';

class UserRegisterScreen extends ConsumerStatefulWidget {
  const UserRegisterScreen({super.key});

  @override
  ConsumerState<UserRegisterScreen> createState() => _UserRegisterScreenState();
}

class _UserRegisterScreenState extends ConsumerState<UserRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .registerUser(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
            displayName: _nameCtrl.text.trim(),
          );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Müşteri Kaydı')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Ad Soyad'),
                validator: (v) => v!.isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'E-posta'),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (v) => v!.contains('@') ? null : 'Geçerli e-posta girin',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Şifre'),
                obscureText: true,
                validator: (v) => v!.length >= 6 ? null : 'En az 6 karakter',
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Kayıt Ol',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
