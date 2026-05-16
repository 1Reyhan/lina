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

    return Container(
      // Kartın dış sınırlarında modern eğim ve gölgelendirme
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(
          20,
        ), // Daha yumuşak modern köşe ovali
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween, // Spacer yerine daha güvenli esnek dağılım
        children: [
          // Üst Satır: İkon ve Tasarımsal Parıltı Çemberi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(
                    0.12,
                  ), // Daha dolgun duran yumuşak opaklık
                  shape:
                      BoxShape
                          .circle, // Kare yerine premium dairesel ikon yuvası
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              // İleride buraya küçük bir yukarı/aşağı yüzdelik trend ikonu eklemek için alan bıraktık
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          // Alt Satır: İstatistik Değeri ve Başlık Alanı
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Değer Kısmı (Ciro, Sipariş Sayısı vb.)
              Text(
                value,
                maxLines: 1,
                overflow:
                    TextOverflow
                        .ellipsis, // Büyük sayılarda yan yana taşmayı önler
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontFamily:
                      'Nunito', // Projenin ana font ailesi entegre edildi
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              // Kart Başlığı (Bekleyen Siparişler vb.)
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 13,
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
