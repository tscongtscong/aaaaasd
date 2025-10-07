import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'worker_login_screen.dart';
import 'worker_reservation_detail_page.dart';

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({super.key});

  Future<void> _updateStatus(BuildContext context, String id, String next) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(id)
          .update({'status': next});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('상태가 $next 로 변경되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }

  void _goLoginAndClearStack(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WorkerLoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservationsQuery = FirebaseFirestore.instance
        .collection('reservations')
        .orderBy('createdAt', descending: true);

    return WillPopScope(
      onWillPop: () async {
        _goLoginAndClearStack(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('작업자 예약 목록'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _goLoginAndClearStack(context),
          ),
          actions: [
            IconButton(
              tooltip: '로그아웃',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) _goLoginAndClearStack(context);
              },
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: reservationsQuery.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('불러오기 오류: ${snap.error}'));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('예약이 없습니다.'));
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final m = doc.data() as Map<String, dynamic>;
                final name = (m['name'] ?? '') as String;
                final phone = (m['phone'] ?? '') as String;
                final status = (m['status'] ?? 'pending') as String;
                final dateTimes =
                    (m['dateTimes'] as List?)?.cast<String>() ?? const [];
                final firstWhen =
                dateTimes.isNotEmpty ? dateTimes.first : (m['date'] ?? '');

                return ListTile(
                  title: Text('$name / $phone'),
                  subtitle: Text('요청시간: $firstWhen\n상태: $status'),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerReservationDetailPage(
                          reservationId: doc.id,
                        ),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '승인',
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _updateStatus(context, doc.id, 'approved'),
                      ),
                      IconButton(
                        tooltip: '거절',
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _updateStatus(context, doc.id, 'rejected'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}//worker_dashboard_screen.dart
