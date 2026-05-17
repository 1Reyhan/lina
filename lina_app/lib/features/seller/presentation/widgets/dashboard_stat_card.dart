import 'package:flutter/material.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Lina Premium lüks koyu lacivert marka rengi
    const Color premiumNavy = Color(0xFF041E31);

    return Container(
      // Kart içi boşluk ayarı taşmaları engellemek için mükemmel şekilde optimize edildi
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(
          20,
        ), // Yumuşak, modern ve lüks köşe yapısı
        border: Border.all(
          // Kartların kenarlıklarında asil lacivert tonunun asil bir çizgisel geçişi
          color: premiumNavy.withAlpha(40),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withAlpha(
              8,
            ), // Lacivert bazlı derinlik veren şık gölge
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween, // İçerikleri üst ve alt sınırda dengeler
        children: [
          // Üst Bölüm: İkon ve Tasarımsal Nokta Parlaması
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withAlpha(76),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          // Alt Bölüm: İstatistik Değeri ve Kart Başlığı
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              // Sayısal değerlerin hiçbir koşulda sığmayıp dikey taşma yapmaması için FittedBox sarmalı
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color:
                        premiumNavy, // Değer sayıları asil marka lacivertine boyandı
                    fontFamily: 'Nunito',
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              // Kart Başlığı (Örn: Bugünkü Sipariş)
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: premiumNavy.withAlpha(
                    128,
                  ), // Alt metinler asil rengin soft opaklığına büründü
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
