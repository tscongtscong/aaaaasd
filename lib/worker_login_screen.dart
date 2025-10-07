import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'worker_dashboard_screen.dart';
// 앱의 "처음 화면" 위젯을 가져옵니다. (이름이 다르면 바꿔주세요)
import 'main.dart' show RoleSelectionScreen;

class WorkerLoginScreen extends StatefulWidget {
  const WorkerLoginScreen({super.key});

  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
  final TextEditingController _usernameCtrl = TextEditingController(); // 인스타/아이디
  final TextEditingController _pwCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  // 처음 화면으로 완전히 이동(스택 비우기)
  void _goToStart(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) =>  RoleSelectionScreen()),
          (route) => false,
    );
  }

  Future<void> _loginAsWorker() async {
    final username = _usernameCtrl.text.trim();
    final password = _pwCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력하세요.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // 1) Firestore에서 username으로 email 찾기
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        throw Exception('해당 아이디가 없습니다.');
      }

      final data = snap.docs.first.data();
      final email = data['email'] as String?;
      if (email == null || email.isEmpty) {
        throw Exception('계정에 이메일 정보가 없습니다.');
      }

      // 2) Firebase Auth: 이메일 + 비밀번호로 로그인
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3) 역할(role) 확인: artist만 통과
      final me = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      final role = me.data()?['role'];
      if (role != 'artist') {
        await FirebaseAuth.instance.signOut();
        throw Exception('작업자 권한이 없습니다.');
      }

      if (!mounted) return;
      // 4) 성공 → 대시보드로 이동(스택 비움: 뒤로가기로 검은 화면 방지)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WorkerDashboardScreen()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = '로그인 실패';
      if (e.code == 'wrong-password') msg = '비밀번호가 올바르지 않습니다.';
      if (e.code == 'user-not-found') msg = '사용자를 찾을 수 없습니다.';
      if (e.code == 'invalid-credential') msg = '자격 증명이 올바르지 않습니다.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 하드웨어 뒤로가기도 "처음 화면"으로
      onWillPop: () async {
        _goToStart(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('작업자 로그인'),
          automaticallyImplyLeading: false, // 기본 뒤로가기 화살표 숨김
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: '처음 화면으로',
              onPressed: () => _goToStart(context),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: '아이디(인스타 이름)'),
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: _pwCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호'),
                onSubmitted: (_) => _loginAsWorker(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _loginAsWorker,
                  child: _loading
                      ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('로그인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//worker_login_screen.dart