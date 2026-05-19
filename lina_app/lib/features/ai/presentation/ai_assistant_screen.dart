import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../providers/ai_providers.dart';

// Lina Premium Renk Tonları
const Color kPremiumNavy = Color(0xFF041E31);
const Color kLightBackground = Color(0xFFF4F7F9);
const Color kAccentHighlight = Color(0xFF005A8D);
const Color kSuccessGreen = Color(0xFF10B981);
const Color kWarningOrange = Color(0xFFF59E0B);

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final Uint8List? imageBytes;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.imageBytes,
  });
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  final bool isSellerMode;
  const AiAssistantScreen({super.key, this.isSellerMode = false});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text:
            widget.isSellerMode
                ? 'Merhaba, Lina AI aktif. Mağaza performansınızı ve stratejilerinizi optimize etmek için buradayım.'
                : 'Merhaba, Lina AI aktif. Mutfak asistanınız olarak size yardımcı olmaya hazırım.',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  // Yönlendirme butonlarını oluşturan yardımcı widget
  Widget _buildQuickAction(String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPremiumNavy.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: kPremiumNavy),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kPremiumNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;
    final bytes = await pickedFile.readAsBytes();
    setState(() => _selectedImageBytes = bytes);
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Fotoğraf Çek'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Galeriden Seç'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty && _selectedImageBytes == null) return;
    final currentBytes = _selectedImageBytes;
    final sentText = text.trim();
    setState(() {
      _messages.add(
        _ChatMessage(
          text: sentText,
          isUser: true,
          time: DateTime.now(),
          imageBytes: currentBytes,
        ),
      );
      _loading = true;
      _selectedImageBytes = null;
    });
    _ctrl.clear();
    final reply = await ref
        .read(geminiRepositoryProvider)
        .chat(
          sentText.isEmpty ? 'Analiz et.' : sentText,
          imageBytes: currentBytes,
        );
    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(text: reply, isUser: false, time: DateTime.now()),
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: const Text(
          'Lina AI',
          style: TextStyle(color: kPremiumNavy, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Sadece kullanıcı modundaysa yönlendirme butonlarını göster
          if (!widget.isSellerMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildQuickAction(
                    'Tarif Analizi',
                    Icons.auto_stories,
                    '/ai/recipe',
                  ),
                  _buildQuickAction(
                    'Barkod Tara',
                    Icons.qr_code_scanner,
                    '/ai/barcode',
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildBubble(_messages[i]),
            ),
          ),
          if (_selectedImageBytes != null) _buildSelectedImagePreview(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: msg.isUser ? kPremiumNavy : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              if (msg.imageBytes != null)
                Image.memory(msg.imageBytes!, height: 100),
              Text(
                msg.text,
                style: TextStyle(
                  color: msg.isUser ? Colors.white : kPremiumNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Image.memory(_selectedImageBytes!, width: 50, height: 50),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _selectedImageBytes = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
              color: kPremiumNavy,
            ),
            onPressed: _showImageSourceDialog,
          ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Mesajınızı yazın...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: kLightBackground,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: kPremiumNavy),
            onPressed: () => _send(_ctrl.text),
          ),
        ],
      ),
    );
  }
}
