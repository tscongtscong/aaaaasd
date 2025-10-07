import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'worker_login_screen.dart';
import 'worker_dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  static const String _fixedRole = 'artist';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _signUpArtist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'username': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': _fixedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WorkerDashboardScreen()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 가입된 이메일입니다. 로그인 해주세요.')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WorkerLoginScreen()),
        );
      } else {
        String msg = '회원가입 실패';
        if (e.code == 'weak-password') msg = '비밀번호가 너무 약합니다(6자 이상).';
        if (e.code == 'invalid-email') msg = '이메일 형식이 올바르지 않습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('작업자 회원가입')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration:
                  const InputDecoration(labelText: '작업자 아이디 / 닉네임'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? '아이디(닉네임)을 입력하세요.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: '이메일'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return '이메일을 입력하세요.';
                    }
                    if (!v.contains('@')) {
                      return '올바른 이메일을 입력하세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pwCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  validator: (v) => (v == null || v.length < 6)
                      ? '비밀번호는 6자 이상으로 입력하세요.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pw2Ctrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '비밀번호 확인'),
                  validator: (v) =>
                  (v != _pwCtrl.text) ? '비밀번호가 일치하지 않습니다.' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _signUpArtist,
                    child: _loading
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('작업자 회원가입'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const WorkerLoginScreen()),
                  ),
                  child: const Text('이미 계정이 있나요? 로그인'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}//signup_screen.dart
