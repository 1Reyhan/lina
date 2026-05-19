import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // 🌟 DÜZELTİLDİ: 'DateFormat' hatasını çözen kritik intl paketi import edildi!
import '../providers/profile_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../shared/models/user_profile_model.dart';
import '../../../shared/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Şemaya uygun asil seçenekler
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

  // Lina Premium Tasarım Renk Kodları
  static const Color premiumNavy = Color(0xFF041E31);
  static const Color premiumBlueAccent = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color softBackground = Color(0xFFF8FAFC);
  static const Color premiumGold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text(
          'Hesabım',
          style: TextStyle(
            color: premiumNavy,
            fontWeight: FontWeight.w900,
            fontFamily: 'Nunito',
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: premiumNavy,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        shape: Border(
          bottom: BorderSide(
            color: premiumNavy.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: dangerRed, size: 22),
            tooltip: 'Çıkış Yap',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: profileAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: premiumNavy),
            ),
        error:
            (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Profil yüklenemedi: $e',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: dangerRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text(
                'Profil bulunamadı',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: premiumNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Üst Kart: Premium Kullanıcı Karşılama Alanı (UserModel ile Tam Uyumlu)
                _buildUserHeader(user, profile),
                const SizedBox(height: 20),

                // 2. TRENDYOL TİPİ HIZLI AKSİYON GRID MENÜSÜ
                _buildTrendyolGridMenu(context, profile),
                const SizedBox(height: 20),

                // 3. KULLANICI BİLGİLERİ DETAY KARTI (Senin UserModel yapından beslenir)
                _buildUserInformationCard(user),
                const SizedBox(height: 24),

                // 🌟 BÖLÜM BAŞLIĞI: Sağlık ve Hassasiyet Ayarları
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'Lina Sağlık Profilim',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: premiumNavy,
                    ),
                  ),
                ),

                // 4. Akordeon (ExpansionTile) Alerji Kalkanı
                _buildExpansionSection(
                  title: 'Alerji Kalkanı',
                  subtitle:
                      'Seçtiğiniz alerjenleri içeren ürünlerde anında uyarı verilir.',
                  icon: Icons.shield_rounded,
                  iconColor: dangerRed,
                  child: _buildChoiceChips(
                    options: _allergyOptions,
                    selectedItems: profile.allergies,
                    activeColor: dangerRed,
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
                const SizedBox(height: 10),

                // 5. Akordeon (ExpansionTile) Diyet Tercihleri
                _buildExpansionSection(
                  title: 'Diyet Tercihlerim',
                  subtitle:
                      'Size en uygun taze ürünleri öne çıkarmamıza yardımcı olur.',
                  icon: Icons.eco_rounded,
                  iconColor: successGreen,
                  child: _buildChoiceChips(
                    options: _dietOptions,
                    selectedItems: profile.dietTypes,
                    activeColor: successGreen,
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
                const SizedBox(height: 10),

                // 6. Ayarlar (Smart Replenish vb.)
                _buildSettingsCard(ref, profile),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // Kullanıcı adı, e-posta, rol ve resmi tamamen senin UserModel ve Firestore yapından asenkron dinleyen lüks alan!
  Widget _buildUserHeader(User? user, UserProfileModel profile) {
    if (user == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: premiumNavy),
          );
        }

        // Eğer Firestore'da döküman bulunamazsa yedek olarak Auth verisi gösterilir
        final bool docExists = snapshot.hasData && snapshot.data!.exists;
        String name = user.displayName ?? 'Lina Kullanıcısı';
        String email = user.email ?? '';
        String roleLabel = 'Üye';

        if (docExists) {
          final userModel = UserModel.fromFirestore(snapshot.data!);
          name = userModel.displayName;
          email = userModel.email;
          roleLabel =
              userModel.role == 'seller'
                  ? 'Lina Satıcısı'
                  : (userModel.role == 'admin' ? 'Yönetici' : 'Lina Üyesi');
        }

        final String avatarLetter =
            name.isNotEmpty ? name[0].toUpperCase() : 'L';

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [premiumNavy, premiumBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: premiumNavy.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.spa_rounded,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // Monogram Baş Harf Avatarı
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white12,
                        child: Text(
                          avatarLetter,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: premiumGold,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: premiumGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              roleLabel,
                              style: const TextStyle(
                                color: premiumGold,
                                fontSize: 10,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                              fontFamily: 'Nunito',
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Kullanıcının dil tercihi, hesap açılış tarihi gibi modellerindeki detayları sunan lüks bilgi alanı
  Widget _buildUserInformationCard(User? user) {
    if (user == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists)
          return const SizedBox();

        final userModel = UserModel.fromFirestore(snapshot.data!);
        final dateStr = DateFormat('dd MMMM yyyy').format(userModel.createdAt);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: premiumNavy.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: premiumNavy.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.badge_outlined, color: premiumNavy, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Kullanıcı Bilgilerim',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: premiumNavy,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.8),
              _buildInfoRow(
                'Hesap Durumu',
                userModel.isActive ? 'Aktif Üye ✔' : 'Pasif',
                valueColor: successGreen,
              ),
              _buildInfoRow(
                'Tercih Edilen Dil',
                userModel.languageCode.toUpperCase(),
              ),
              _buildInfoRow('Kayıt Tarihi', dateStr),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String val, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: premiumNavy.withValues(alpha: 0.45),
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? premiumNavy,
            ),
          ),
        ],
      ),
    );
  }

  // Trendyol Tarzı Hızlı Grid Menü Altyapısı
  Widget _buildTrendyolGridMenu(
    BuildContext context,
    UserProfileModel profile,
  ) {
    return Column(
      children: [
        Row(
          children: [
            _buildGridMenuItem(
              context: context,
              title: 'Siparişlerim',
              subtitle: 'Sipariş takibi yapın',
              icon: Icons.receipt_long_rounded,
              iconColor: premiumNavy,
              onTap: () => context.push('/orders'),
            ),
            const SizedBox(width: 12),
            _buildGridMenuItem(
              context: context,
              title: 'Lina Club Puan',
              subtitle: '₺${profile.loyaltyPoints} Değerinde',
              icon: Icons.stars_rounded,
              iconColor: premiumGold,
              onTap: () {
                _showInfoSnackBar(
                  context,
                  'Mevcut Lina Club puanlarınız alışverişlerinizde otomatik indirim sağlar!',
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildGridMenuItem(
              context: context,
              title: 'Adreslerim',
              subtitle: '${profile.addresses.length} Kayıtlı Adres',
              icon: Icons.location_on_rounded,
              iconColor: successGreen,
              onTap: () => _showAddressManagerDialog(context, profile),
            ),
            const SizedBox(width: 12),
            _buildGridMenuItem(
              context: context,
              title: 'Kuponlarım',
              subtitle: 'Aktif fırsatları gör',
              icon: Icons.local_offer_rounded,
              iconColor: warningOrange,
              onTap: () {
                _showInfoSnackBar(
                  context,
                  'Tebrikler! Mevcut tüm kuponlarınız sepetinizde otomatik uygulanmaktadır.',
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridMenuItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: premiumNavy.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: premiumNavy.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: premiumNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: premiumNavy.withValues(alpha: 0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Akordeon Tasarımlı Lina Sağlık Kalkanı Bölümü
  Widget _buildExpansionSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: premiumNavy.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: premiumNavy,
          collapsedIconColor: premiumNavy.withValues(alpha: 0.4),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: premiumNavy,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 32, top: 2),
            child: Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                color: premiumNavy.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ],
        ),
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
              selectedColor: activeColor.withValues(alpha: 0.12),
              checkmarkColor: activeColor,
              showCheckmark: isSelected,
              labelStyle: TextStyle(
                fontFamily: 'Nunito',
                color:
                    isSelected
                        ? activeColor
                        : premiumNavy.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      isSelected
                          ? activeColor
                          : premiumNavy.withValues(alpha: 0.12),
                  width: isSelected ? 1.6 : 1.2,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSettingsCard(WidgetRef ref, UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: premiumNavy.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Akıllı İkmal (Smart Replenish)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
                color: premiumNavy,
              ),
            ),
            subtitle: Text(
              'Sık aldığınız taze ürünleri bitmek üzereyken otomatik sepetinize ekler.',
              style: TextStyle(
                fontSize: 11.5,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
                color: premiumNavy.withValues(alpha: 0.45),
              ),
            ),
            value: profile.smartReplenishEnabled,
            activeColor: successGreen,
            activeTrackColor: successGreen.withValues(alpha: 0.2),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
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
    ref.invalidate(userProfileProvider);
  }

  void _showInfoSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: premiumNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Kayıtlı Adresleri Gösteren Lüks BottomSheet Arayüzü
  void _showAddressManagerDialog(
    BuildContext context,
    UserProfileModel profile,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: successGreen,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Kayıtlı Teslimat Adreslerim',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: premiumNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (profile.addresses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Henüz eklenmiş bir teslimat adresiniz bulunmuyor.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: premiumNavy.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: profile.addresses.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, idx) {
                        final addr = profile.addresses[idx];
                        final isDefault =
                            addr['id'] == profile.defaultAddressId || idx == 0;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isDefault
                                  ? Icons.check_circle_rounded
                                  : Icons.location_on_outlined,
                              color:
                                  isDefault
                                      ? successGreen
                                      : premiumNavy.withValues(alpha: 0.4),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    addr['title'] ?? 'Ev Adresim',
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: premiumNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    addr['address'] ?? 'Adres detayı yok',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                      color: premiumNavy.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: premiumNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kapat',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Oturumu Kapat',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: premiumNavy,
              ),
            ),
            content: const Text(
              'Lina dünyasından çıkış yapmak istediğinize emin misiniz?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
                color: premiumNavy,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'İptal',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: dangerRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
