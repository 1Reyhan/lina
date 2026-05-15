import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';

class SellerRegisterScreen extends ConsumerStatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  ConsumerState<SellerRegisterScreen> createState() =>
      _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends ConsumerState<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  String _sellerType = 'bireysel_üretici';
  bool _loading = false;
  String? _error;

  final _sellerTypes = [
    {'value': 'bireysel_üretici', 'label': '🌾 Kendi Üretimim'},
    {'value': 'yerel_market', 'label': '🏪 Yerel İşletmem'},
    {'value': 'kurumsal', 'label': '📦 Toptan / Kurumsal'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _storeCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
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
          .registerSeller(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
            displayName: _nameCtrl.text.trim(),
            storeName: _storeCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            district: _districtCtrl.text.trim(),
            sellerType: _sellerType,
          );
      if (mounted) {
        // Satıcı onay bekliyor, bilgilendirme sayfasına git
        context.go('/seller/pending');
      }
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
      appBar: AppBar(title: const Text('Mağaza Aç')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Satıcı Tipi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._sellerTypes.map(
                (t) => RadioListTile<String>(
                  title: Text(t['label']!),
                  value: t['value']!,
                  groupValue: _sellerType,
                  onChanged: (v) => setState(() => _sellerType = v!),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _storeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mağaza / Çiftlik Adı',
                ),
                validator: (v) => v!.isEmpty ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'Şehir'),
                      validator: (v) => v!.isEmpty ? 'Zorunlu' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _districtCtrl,
                      decoration: const InputDecoration(labelText: 'İlçe'),
                      validator: (v) => v!.isEmpty ? 'Zorunlu' : null,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Adınız'),
                validator: (v) => v!.isEmpty ? 'Zorunlu' : null,
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
                            'Mağazamı Oluştur',
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
