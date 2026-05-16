import 'package:flutter/material.dart';

class OrderStatusDropdown extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  static const _statuses = [
    {'value': 'pending', 'label': 'Bekliyor'},
    {'value': 'confirmed', 'label': 'Onaylandı'},
    {'value': 'preparing', 'label': 'Hazırlanıyor'},
    {'value': 'shipped', 'label': 'Yolda'},
    {'value': 'delivered', 'label': 'Teslim Edildi'},
    {'value': 'cancelled', 'label': 'İptal'},
  ];

  static const _colors = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'preparing': Colors.purple,
    'shipped': Colors.teal,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  const OrderStatusDropdown({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colors[current] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(
          0.08,
        ), // Daha lüks duran yumuşak bir arka plan tonu
        borderRadius: BorderRadius.circular(24), // Modern oval köşe yapısı
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 18),
          dropdownColor:
              theme
                  .colorScheme
                  .surface, // Açılır menü arka planını temaya eşitler
          isDense: true,
          elevation: 4,
          borderRadius: BorderRadius.circular(
            16,
          ), // Menünün kendi köşelerini de ovalleştirir
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
          onChanged: (v) => v != null ? onChanged(v) : null,
          items:
              _statuses.map((s) {
                final itemValue = s['value']!;
                final itemColor = _colors[itemValue] ?? Colors.grey;

                return DropdownMenuItem<String>(
                  value: itemValue,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Her seçeneğin soluna durum rengini belli eden minik bir nokta efekti
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: itemColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s['label']!,
                        style: TextStyle(
                          color:
                              itemValue == current
                                  ? itemColor
                                  : theme.colorScheme.onSurface,
                          fontWeight:
                              itemValue == current
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                          fontFamily: 'Nunito',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
