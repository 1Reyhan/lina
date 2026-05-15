import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_providers.dart';
import '../data/profile_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../shared/models/user_profile_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Şemana uygun seçenekler
  static const _allergyOptions = [
    'Gluten',
    'Fıstık',
    'Süt',
    'Yumurta',
    'Soya',
    'Balık',
    'Kabuklu Deniz Ürünleri',
    'Ceviz',
  ];

  static const _dietOptions = [
    'Vegan',
    'Vejetaryen',
    'Keto',
    'Glutensiz',
    'Laktozsuz',
    'Halal',
    'Düşük Karbon',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Sağlık Profilim',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Profil yüklenemedi: $e')),
        data: (profile) {
          if (profile == null)
            return const Center(child: Text('Profil bulunamadı'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Üst Kart: Kullanıcı ve Sadakat Puanı
                _buildUserHeader(user, profile),
                const SizedBox(height: 16),

                // 2. Alerji Yönetimi
                _ProfileSection(
                  title: 'Alerji Kalkanı',
                  subtitle:
                      'Seçili alerjenleri içeren ürünlerde sizi uyaracağız.',
                  icon: Icons.shield_outlined,
                  iconColor: Colors.red,
                  child: _buildChoiceChips(
                    options: _allergyOptions,
                    selectedItems: profile.allergies,
                    activeColor: Colors.red,
                    onSelected:
                        (item) => _updatePreference(
                          ref,
                          profile.uid,
                          'allergies',
                          profile.allergies,
                          item,
                        ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Diyet Tercihleri
                _ProfileSection(
                  title: 'Diyet Tercihlerim',
                  subtitle:
                      'Size en uygun ürünleri öne çıkarmamıza yardımcı olur.',
                  icon: Icons.eco_outlined,
                  iconColor: Colors.green,
                  child: _buildChoiceChips(
                    options: _dietOptions,
                    selectedItems: profile.dietTypes,
                    activeColor: Colors.green,
                    onSelected:
                        (item) => _updatePreference(
                          ref,
                          profile.uid,
                          'dietTypes',
                          profile.dietTypes,
                          item,
                        ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Ayarlar (Smart Replenish vb.)
                _buildSettingsCard(ref, profile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserHeader(User? user, UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.green.shade50,
            child: Text(
              user?.displayName?[0].toUpperCase() ?? 'L',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Lina Kullanıcısı',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                // Şemandaki loyaltyPoints alanı
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '✨ ${profile.loyaltyPoints} Lina Puan',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChips({
    required List<String> options,
    required List<String> selectedItems,
    required Color activeColor,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          options.map((option) {
            final isSelected = selectedItems.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              selectedColor: activeColor.withAlpha(40),
              checkmarkColor: activeColor,
              labelStyle: TextStyle(
                color: isSelected ? activeColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? activeColor : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSettingsCard(WidgetRef ref, UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Akıllı İkmal (Smart Replenish)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Biten ürünleri otomatik sepete ekle',
              style: TextStyle(fontSize: 12),
            ),
            value: profile.smartReplenishEnabled,
            activeColor: Colors.green,
            onChanged:
                (val) => ref.read(profileRepositoryProvider).updateProfile(
                  profile.uid,
                  {'smartReplenishEnabled': val},
                ),
          ),
        ],
      ),
    );
  }

  void _updatePreference(
    WidgetRef ref,
    String uid,
    String field,
    List<String> currentList,
    String item,
  ) {
    final newList = List<String>.from(currentList);
    newList.contains(item) ? newList.remove(item) : newList.add(item);
    ref.read(profileRepositoryProvider).updateProfile(uid, {field: newList});
    // Stream kullandığımız için invalidate yapmaya gerek kalmayabilir ama garantiye alalım
    ref.invalidate(userProfileProvider);
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Çıkış Yap'),
            content: const Text('Oturumu kapatmak istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('Çıkış', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ProfileSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
