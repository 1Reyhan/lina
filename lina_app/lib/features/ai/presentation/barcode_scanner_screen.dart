import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/ai_providers.dart';

const Color kPremiumNavy = Color(0xFF041E31);
const Color kAccentGreen = Color(0xFF2ECC71);

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  bool _scanned = false;
  bool _loading = false;
  String? _result;
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() {
      _scanned = true;
      _loading = true;
    });
    _controller.stop();

    final code = barcode!.rawValue!;

    try {
      final analysis = await ref
          .read(geminiRepositoryProvider)
          .analyzeProductHealth(
            productName: 'Barkod: $code',
            ingredients: [],
            userAllergies: [],
          );

      if (mounted) {
        setState(() {
          _result = analysis;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _scanned = false;
        });
        _controller.start();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analiz sırasında bir hata oluştu.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Barkod Tara',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body:
          _result != null
              ? _ResultView(
                result: _result!,
                onRescan:
                    () => setState(() {
                      _result = null;
                      _scanned = false;
                      _controller.start();
                    }),
              )
              : Stack(
                children: [
                  MobileScanner(controller: _controller, onDetect: _onDetect),
                  // Tarama Alanı Efekti
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(color: kAccentGreen, width: 3),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: kAccentGreen.withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_loading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: kAccentGreen),
                            SizedBox(height: 20),
                            Text(
                              'Lina AI Ürünü İnceliyor...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final String result;
  final VoidCallback onRescan;
  const _ResultView({required this.result, required this.onRescan});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: kAccentGreen, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Analiz Tamamlandı',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kPremiumNavy,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPremiumNavy.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Text(
                  result,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: kPremiumNavy,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onRescan,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPremiumNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Yeni Ürün Tara',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
