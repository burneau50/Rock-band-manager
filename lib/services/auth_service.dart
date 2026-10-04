import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String adminPseudo = 'antonin';
  static const String adminEmail = 'antoninlemonnier50@gmail.com';
  static const String internalEmailDomain = '@rockband-app.invalid';

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  String normalizePseudo(String pseudo) {
    return pseudo
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'^\.|\.$'), '');
  }

  String buildInternalEmail(String pseudo) {
    final normalized = normalizePseudo(pseudo);
    return '$normalized$internalEmailDomain';
  }

  Future<UserCredential> signIn({
    required String pseudo,
    required String password,
  }) async {
    final normalized = normalizePseudo(pseudo);

    final email = normalized == adminPseudo
        ? adminEmail
        : buildInternalEmail(pseudo);

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (normalized == adminPseudo &&
        credential.user != null &&
        credential.user!.displayName != 'Antonin') {
      await credential.user!.updateDisplayName('Antonin');
    }

    return credential;
  }

  Future<UserCredential> register({
    required String pseudo,
    required String password,
  }) async {
    final normalized = normalizePseudo(pseudo);

    if (normalized == adminPseudo) {
      throw FirebaseAuthException(
        code: 'pseudo-reserved',
        message: 'Le pseudo Antonin est réservé à l’administrateur.',
      );
    }

    final internalEmail = buildInternalEmail(pseudo);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: internalEmail,
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await user.updateDisplayName(pseudo);

      await _firestore.collection('users').doc(user.uid).set({
        'displayName': pseudo,
        'username': pseudo,
        'usernameLower': normalized,
        'email': internalEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
