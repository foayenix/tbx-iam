import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:logger/logger.dart';
import '../../core/env.dart';

/// Firebase service for centralized Firebase access
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _logger = Logger();

  // Firebase instances
  late final FirebaseFirestore firestore;
  late final FirebaseFunctions functions;
  late final auth.FirebaseAuth authInstance;

  bool _initialized = false;

  /// Initialize Firebase services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      firestore = FirebaseFirestore.instance;
      functions = FirebaseFunctions.instance;
      authInstance = auth.FirebaseAuth.instance;

      // Use emulator if configured
      if (Env.useFirebaseEmulator) {
        firestore.useFirestoreEmulator(
          Env.firestoreEmulatorHost,
          Env.firestoreEmulatorPort,
        );
        functions.useFunctionsEmulator(
          Env.firestoreEmulatorHost,
          5001,
        );
        authInstance.useAuthEmulator(
          Env.firestoreEmulatorHost,
          9099,
        );
        _logger.i('Firebase emulator configured');
      }

      _initialized = true;
      _logger.i('Firebase service initialized');
    } catch (e, stack) {
      _logger.e('Failed to initialize Firebase service', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Sign in anonymously
  Future<auth.User?> signInAnonymously() async {
    try {
      final credential = await authInstance.signInAnonymously();
      _logger.i('Signed in anonymously: ${credential.user?.uid}');
      return credential.user;
    } catch (e, stack) {
      _logger.e('Failed to sign in anonymously', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get current user
  auth.User? get currentUser => authInstance.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get user ID
  String? get uid => currentUser?.uid;

  /// Call Cloud Function
  Future<T?> callFunction<T>(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      _logger.d('Calling function: $name with params: $parameters');
      final callable = functions.httpsCallable(name);
      final result = await callable.call(parameters);
      _logger.d('Function $name returned: ${result.data}');
      return result.data as T?;
    } catch (e, stack) {
      _logger.e('Failed to call function $name', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Batch write helper
  WriteBatch batch() => firestore.batch();

  /// Transaction helper
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) transactionHandler,
  ) {
    return firestore.runTransaction(transactionHandler);
  }
}
