import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Lina projesi tasarım renk paleti ile uyumlu sabitler
const Color premiumNavy = Color(0xFF041E31);

class ReviewsScreen extends ConsumerWidget {
  final String productId;

  const ReviewsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Değerlendirmeler',
          style: TextStyle(
            fontFamily: 'MoreSugar',
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: premiumNavy,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Puan Özeti Bölümü
          _buildRatingSummary(),

          // Değerlendirme Listesi
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5, // Örnek veri sayısı
              separatorBuilder: (ctx, i) => const Divider(height: 32),
              itemBuilder: (context, index) {
                return _buildReviewItem();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          const Column(
            children: [
              Text(
                "4.8",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: premiumNavy,
                ),
              ),
              Icon(Icons.star, color: Colors.amber, size: 28),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: List.generate(
                5,
                (index) => _buildRatingBar(5 - index, 0.7 - (index * 0.1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$star Yıldız", style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              color: Colors.amber,
              backgroundColor: Colors.black12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Ayşe Yılmaz",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: List.generate(
                5,
                (i) => const Icon(Icons.star, size: 14, color: Colors.amber),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Ürün kalitesi gerçekten beklediğimden çok daha iyi. Hızlı teslimat için Lina ekibine teşekkürler!",
          style: TextStyle(color: Colors.black87, height: 1.4),
        ),
      ],
    );
  }
}
