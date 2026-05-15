import 'package:flutter/material.dart';
import '../../../../shared/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          // Puanları görselin üzerine bindirmek için Stack kullandık
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ürün görseli
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child:
                        product.images.isNotEmpty
                            ? Image.network(
                              product.images.first,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                            : _placeholder(),
                  ),
                ),
                // Bilgiler
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.category,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.hasDiscount)
                                  Text(
                                    '₺${product.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 10,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  '₺${product.effectivePrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            _addButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // SOL ÜST: AI Sağlık Puanı (Lina'nın imzası)
            Positioned(
              top: 8,
              left: 8,
              child: _scoreBadge(
                Icons.favorite,
                product.healthScore.toStringAsFixed(1),
                Colors.orange.shade700,
              ),
            ),
            // SAĞ ÜST: Karbon Ayak İzi
            Positioned(
              top: 8,
              right: 8,
              child: _scoreBadge(
                Icons.eco,
                product.carbonScore.toStringAsFixed(0),
                Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBadge(IconData icon, String score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            score,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: onAddToCart,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.green.shade700,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey.shade100,
    child: Center(
      child: Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade300),
    ),
  );
}
