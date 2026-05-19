import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_providers.dart';
import '../../fridge/providers/fridge_providers.dart';
import '../../../features/profile/providers/profile_providers.dart';

// Senin Premium Renk Tonun
const Color kPremiumNavy = Color(0xFF041E31);
const Color kLightBackground = Color(0xFFF4F7F9);
const Color kAccentHighlight = Color(
  0xFF005A8D,
); // Lacivertle uyumlu bir alt ton

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({required this.text, required this.isUser, required this.time});
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

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(
        _ChatMessage(text: text, isUser: true, time: DateTime.now()),
      );
      _loading = true;
    });
    _ctrl.clear();

    final reply = await ref.read(geminiRepositoryProvider).chat(text);
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
        backgroundColor: kPremiumNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Lina AI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildBubble(_messages[i]),
            ),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: msg.isUser ? kPremiumNavy : Colors.white,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: msg.isUser ? Radius.zero : const Radius.circular(20),
              bottomLeft: msg.isUser ? const Radius.circular(20) : Radius.zero,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              color: msg.isUser ? Colors.white : kPremiumNavy,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Bir şeyler yazın...',
                filled: true,
                fillColor: kLightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _send(_ctrl.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: kPremiumNavy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
