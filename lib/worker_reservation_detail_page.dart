import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerReservationDetailPage extends StatefulWidget {
  final String reservationId; // ✅ 대시보드에서 전달받음
  const WorkerReservationDetailPage({super.key, required this.reservationId});

  @override
  State<WorkerReservationDetailPage> createState() => _WorkerReservationDetailPageState();
}

class _WorkerReservationDetailPageState extends State<WorkerReservationDetailPage> {
  bool _updating = false;

  Future<void> _updateStatus(String next) async {
    setState(() => _updating = true);
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationId)
          .update({'status': next});

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('상태가 $next 로 변경되었습니다.')));
      Navigator.pop(context); // 목록으로 복귀
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance
        .collection('reservations')
        .doc(widget.reservationId);

    return Scaffold(
      appBar: AppBar(title: const Text('예약 상세 보기')),
      body: FutureBuilder<DocumentSnapshot>(
        future: docRef.get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('불러오기 오류: ${snap.error}'));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('예약 문서를 찾을 수 없습니다.'));
          }

          final m = snap.data!.data() as Map<String, dynamic>;
          final name = (m['name'] ?? '') as String;
          final email = (m['email'] ?? '') as String;
          final location = (m['location'] ?? '') as String;
          final designText = (m['designText'] ?? '') as String;
          final color = (m['color'] ?? '') as String;
          final status = (m['status'] ?? 'pending') as String;
          final artist = (m['artistUsername'] ?? '') as String;
          final dateTimes = (m['dateTimes'] as List?)?.cast<String>() ?? const [];
          final refImages = (m['refImages'] as List?)?.cast<String>() ?? const [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoTile('상태', status),
                _infoTile('작업자(인스타)', artist.isEmpty ? '-' : artist),
                _infoTile('이름 / 나이', name),
                _infoTile('이메일', email),
                _infoTile('시술 부위', location),
                _infoTile('디자인 설명', designText),
                _infoTile('컬러', color),

                const SizedBox(height: 16),
                const Text('희망 날짜/시간', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                if (dateTimes.isEmpty)
                  const Text('-', style: TextStyle(fontSize: 16))
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dateTimes.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $t', style: const TextStyle(fontSize: 16)),
                    )).toList(),
                  ),

                const SizedBox(height: 16),
                const Text('첨부 이미지', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (refImages.isEmpty)
                  const Text('첨부된 사진 없음', style: TextStyle(fontSize: 16))
                else
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: refImages.map((url) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: MediaQuery.of(context).size.width / 3 - 20,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: MediaQuery.of(context).size.width / 3 - 20,
                          height: 100,
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    )).toList(),
                  ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _updating ? null : () => _updateStatus('approved'),
                        icon: const Icon(Icons.check),
                        label: const Text('승인'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _updating ? null : () => _updateStatus('rejected'),
                        icon: const Icon(Icons.close),
                        label: const Text('거절'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}//worker_reservation_detail_page.dart
