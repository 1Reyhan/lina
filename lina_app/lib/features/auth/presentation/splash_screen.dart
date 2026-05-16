import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Artırılmış ve ekran geneline yayılmış dinamik patlama merkezleri
  final List<Offset> _particlePositions = [
    const Offset(0.12, 0.15),
    const Offset(0.85, 0.12),
    const Offset(0.20, 0.40),
    const Offset(0.78, 0.35),
    const Offset(0.15, 0.70),
    const Offset(0.88, 0.75),
    const Offset(0.45, 0.18),
    const Offset(0.55, 0.82),
    const Offset(0.30, 0.55),
    const Offset(0.65, 0.60),
    const Offset(0.10, 0.90),
    const Offset(0.90, 0.45),
  ];

  // Estetik ikon havuzu
  final List<String> _burstIcons = [
    '🍲',
    '🥑',
    '🥐',
    '☕',
    '🥨',
    '🍯',
    '🍲',
    '🥑',
    '🥐',
    '☕',
    '🥨',
    '🍯',
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 4,
      ), // Daha akıcı bir döngü için süreyi biraz uzattık
    )..repeat();

    _navigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ORIJINAL YÖNLENDİRME MEKANİZMASI (DOKUNULMADI)
  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      context.go('/home');
      return;
    }

    final role = await ref.read(authRepositoryProvider).getUserRole(user.uid);
    if (!mounted) return;

    switch (role) {
      case 'seller':
        context.go('/seller/dashboard');
        break;
      case 'admin':
        context.go('/home');
        break;
      default:
        context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Arka Plan: Görseldeki gibi derin ve asil bir koyu ton
      backgroundColor: const Color(0xFF041E31),
      body: Stack(
        children: [
          // Gelişmiş Işık Patlaması Efektleri
          ...List.generate(_particlePositions.length, (index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                // Karışık patlama hissi için her birine farklı gecikme veriyoruz
                double progress =
                    (_animationController.value - (index * 0.08)) % 1.0;
                if (progress < 0) progress = 0;

                double posX = _particlePositions[index].dx * size.width;
                double posY = _particlePositions[index].dy * size.height;

                // İkon büyüme ve sönme efekti
                double iconScale = math.sin(progress * math.pi) * 1.3;
                double opacity = (1.0 - progress).clamp(0.0, 1.0);

                return Stack(
                  children: [
                    // Arka plandaki ince ışık huzmeleri ve beyaz ışıltılar
                    Positioned.fill(
                      child: Opacity(
                        opacity: opacity,
                        child: CustomPaint(
                          painter: LightBurstPainter(
                            center: Offset(posX, posY),
                            progress: progress,
                          ),
                        ),
                      ),
                    ),

                    // Merkezdeki İkon
                    Positioned(
                      left: posX - 16,
                      top: posY - 16,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: iconScale,
                          child: Transform.rotate(
                            angle: progress * 0.5 * math.pi,
                            child: Text(
                              _burstIcons[index % _burstIcons.length],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }),

          // ORTA ALAN: Mavi Geçişli LINA Yazısı
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [
                        Color(0xFFB3E5FC), // Açık Mavi
                        Color(0xFF0288D1), // Orta Mavi
                        Color(0xFF01579B), // Koyu Mavi
                      ],
                      stops: [
                        (_animationController.value - 0.3).clamp(0.0, 1.0),
                        _animationController.value,
                        (_animationController.value + 0.3).clamp(0.0, 1.0),
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'LINA',
                    style: TextStyle(
                      fontFamily: 'MoreSugar',
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                      color:
                          Colors.white, // Maske sayesinde mavi geçişli olacak
                    ),
                  ),
                );
              },
            ),
          ),

          // ALT ALAN: Marka Yazısı
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'BAYSERK',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 12,
                    color: const Color(0xFFB3E5FC).withOpacity(0.7),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Görseldeki gibi ince ışık huzmelerini ve beyaz ışıltıları çizen ressam
class LightBurstPainter extends CustomPainter {
  final Offset center;
  final double progress;

  LightBurstPainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double maxRadius = 120.0; // Patlama genişliği
    final double currentRadius = progress * maxRadius;

    // Mavi ışık huzmeleri (İnce ve sık)
    final Paint linePaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withOpacity(0.8),
              const Color(0xFF4FC3F7), // Açık Mavi
              const Color(
                0xFF01579B,
              ).withOpacity(0.0), // Koyu Maviye doğru kaybolan
            ],
          ).createShader(Rect.fromCircle(center: center, radius: currentRadius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8; // Çok ince çizgiler

    // 1. Işık Huzmeleri (32 adet ince çizgi)
    int rayCount = 32;
    for (int i = 0; i < rayCount; i++) {
      double angle = (i * 2 * math.pi) / rayCount;

      // Çizgilerin boylarını hafif rastgele yaparak daha doğal bir görünüm veriyoruz
      double variance = 0.8 + (math.sin(i.toDouble()) * 0.2);

      double startDist = currentRadius * 0.1;
      double endDist = currentRadius * variance;

      Offset start = Offset(
        center.dx + startDist * math.cos(angle),
        center.dy + startDist * math.sin(angle),
      );
      Offset end = Offset(
        center.dx + endDist * math.cos(angle),
        center.dy + endDist * math.sin(angle),
      );

      canvas.drawLine(start, end, linePaint);
    }

    // 2. Beyaz Merkez Işıltısı (Görseldeki parlayan nokta)
    if (progress < 0.5) {
      final Paint glowPaint =
          Paint()
            ..color = Colors.white.withOpacity(
              (1.0 - progress * 2).clamp(0.0, 1.0),
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, 4, glowPaint);
    }

    // 3. Minik Rastgele Kıvılcımlar (Beyaz noktalar)
    final Paint sparkPaint =
        Paint()..color = Colors.white.withOpacity(1.0 - progress);
    for (int i = 0; i < 8; i++) {
      double angle = (i * 45 * math.pi) / 180;
      double dist = currentRadius * (0.6 + (i % 3) * 0.1);
      Offset sparkPos = Offset(
        center.dx + dist * math.cos(angle),
        center.dy + dist * math.sin(angle),
      );
      canvas.drawCircle(sparkPos, 1.0, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LightBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
