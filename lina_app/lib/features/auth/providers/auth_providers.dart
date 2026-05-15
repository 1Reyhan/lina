import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Firebase auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Giriş yapan kullanıcının role'ü
final userRoleProvider = FutureProvider.family<String?, String>((ref, uid) {
  return ref.watch(authRepositoryProvider).getUserRole(uid);
});
