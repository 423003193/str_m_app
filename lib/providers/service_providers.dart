import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/local_db_service.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final localDbServiceProvider =
    Provider<LocalDbService>((ref) => LocalDbService());
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
