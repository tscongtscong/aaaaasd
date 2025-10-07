import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signUp({
    required String username,
    required String name,
    required String email,
    required String password,
    String role = 'customer', // customer | artist
  }) async {
    // username 중복 체크
    final dup = await _db.collection('users')
        .where('username', isEqualTo: username.trim()).limit(1).get();
    if (dup.docs.isNotEmpty) {
      throw Exception('이미 사용 중인 아이디입니다.');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(), password: password.trim(),
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'username': username.trim(),
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> loginWithUsername({
    required String username,
    required String password,
    bool requireArtist = false,
  }) async {
    final snap = await _db.collection('users')
        .where('username', isEqualTo: username.trim()).limit(1).get();
    if (snap.docs.isEmpty) throw Exception('아이디가 없습니다.');

    final data = snap.docs.first.data();
    final email = data['email'] as String?;
    if (email == null) throw Exception('계정에 이메일이 없습니다.');

    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password.trim(),
    );

    if (requireArtist) {
      final me = await _db.collection('users').doc(cred.user!.uid).get();
      if (me.data()?['role'] != 'artist') {
        await _auth.signOut();
        throw Exception('작업자 권한이 없습니다.');
      }
    }
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> logout() => _auth.signOut();
}//auth_service.dart
