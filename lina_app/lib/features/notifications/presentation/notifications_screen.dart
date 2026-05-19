import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/notification_repository.dart';

final _notifRepoProvider = Provider((ref) => NotificationRepository());

final _notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(_notifRepoProvider).watchNotifications(uid);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _typeConfig = {
    'order': {'icon': Icons.receipt_long_outlined, 'color': Colors.blue},
    'return': {'icon': Icons.assignment_return_outlined, 'color': Colors.red},
    'replenish': {'icon': Icons.refresh_outlined, 'color': Colors.teal},
    'campaign': {'icon': Icons.campaign_outlined, 'color': Colors.purple},
    'fridge': {'icon': Icons.kitchen_outlined, 'color': Colors.orange},
    'ai_tip': {'icon': Icons.auto_awesome_outlined, 'color': Colors.green},
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(_notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF041E31),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          notifsAsync.when(
            data: (notifs) {
              final unread = notifs.where((n) => n['isRead'] == false).toList();
              if (unread.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  final repo = ref.read(_notifRepoProvider);
                  for (final n in unread) {
                    await repo.markRead(n['id']);
                  }
                },
                child: const Text(
                  'Tümünü Oku',
                  style: TextStyle(
                    color: Color(0xFF2ECC71),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
            ),
        error: (e, _) => Center(child: Text('Hata oluştu: $e')),
        data:
            (notifs) =>
                notifs.isEmpty
                    ? _EmptyState()
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: notifs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder:
                          (_, i) => _NotificationTile(notif: notifs[i]),
                    ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final Map<String, dynamic> notif;
  const _NotificationTile({required this.notif});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = notif['type'] ?? 'order';
    final isRead = notif['isRead'] ?? false;
    final config =
        NotificationsScreen._typeConfig[type] ??
        {'icon': Icons.notifications_none, 'color': Colors.grey};

    return InkWell(
      onTap: () => ref.read(_notifRepoProvider).markRead(notif['id']),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF1FAF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? Colors.transparent : const Color(0xFFD4EDDA),
          ),
          boxShadow:
              isRead
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                    ),
                  ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (config['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                config['icon'] as IconData,
                color: config['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif['title'] ?? '',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['body'] ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(notif['createdAt']),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is! Timestamp) return '';
    final dt = timestamp.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key}); // key parametresi eklendi

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          const Text(
            'Bildirim Yok',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni hareket olduğunda burada göreceksin.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
