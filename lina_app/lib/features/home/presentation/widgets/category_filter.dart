import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  // Lina Vizyonu: Bireysel üreticiler ve ev yapımı ürünleri kapsayan kategoriler
  static const categories = [
    'Tümü',
    'Ev Yapımı & Doğal', // Ev hanımları ve bireysel üreticiler için
    'Meyve & Sebze',
    'Süt Ürünleri',
    'Et & Tavuk',
    'Tahıl & Bakliyat',
    'Yöresel Ürünler', // Yerel marketler/esnaf için
    'Atıştırmalık',
    'İçecek',
    'Diyet & Sağlık', // Alerji/Diyet odaklı paketler için
  ];

  const CategoryFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45, // Biraz yükselttik, metinler daha rahat nefes alsın
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat == selected;

          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.green.shade700
                        : Colors.white, // Beyaz arka plan daha temiz durur
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color:
                      isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
