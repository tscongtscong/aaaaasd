import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TattooReservationPage extends StatefulWidget {
  @override
  _TattooReservationPageState createState() => _TattooReservationPageState();
}

class _TattooReservationPageState extends State<TattooReservationPage> {
  final picker = ImagePicker();
  File? procedureImage;
  File? designImage;

  final TextEditingController artistIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController designTextController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController datetimeController = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    artistIdController.dispose();
    nameController.dispose();
    emailController.dispose();
    locationController.dispose();
    designTextController.dispose();
    colorController.dispose();
    datetimeController.dispose();
    super.dispose();
  }

  Future<void> pickImage(Function(File) onImagePicked) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      onImagePicked(File(pickedFile.path));
    }
  }

  Future<String> _uploadImage(File image, String uid, String type) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('reservations')
          .child(uid)
          .child('${type}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception('이미지 업로드 실패: $e');
    }
  }

  void _goHomeSafely(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // tattoo_reservation_page.dart

  Future<void> _submitReservation() async {
    FocusScope.of(context).unfocus();

    if (artistIdController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        !emailController.text.contains('@') ||
        locationController.text.trim().isEmpty ||
        designTextController.text.trim().isEmpty ||
        colorController.text.trim().isEmpty ||
        datetimeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 항목(이메일 형식 포함)을 모두 입력하세요.')),
      );
      return;
    }

    // ✅ 수정된 부분: 사용자 인증 정보가 없으면 'guest_user'로 처리
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

    final List<String> dateTimes = datetimeController.text
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() => _submitting = true);
    // ... (이하 이미지 업로드 및 Firestore 저장 로직은 동일하게 진행)
    try {
      // 1️⃣ 이미지 업로드
      List<String> uploadedImages = [];
      if (procedureImage != null) {
        uploadedImages.add(await _uploadImage(procedureImage!, uid, 'procedure'));
      }
      if (designImage != null) {
        uploadedImages.add(await _uploadImage(designImage!, uid, 'design'));
      }

      // 2️⃣ Firestore에 예약 데이터 저장
      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': uid,
        'artistUsername': artistIdController.text.trim(),
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'location': locationController.text.trim(),
        'designText': designTextController.text.trim(),
        'color': colorController.text.trim(),
        'dateTimes': dateTimes,
        'refImages': uploadedImages,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예약이 접수되었습니다.')),
      );

      // 입력 필드 초기화
      artistIdController.clear();
      nameController.clear();
      emailController.clear();
      locationController.clear();
      designTextController.clear();
      colorController.clear();
      datetimeController.clear();
      setState(() {
        procedureImage = null;
        designImage = null;
      });

      _goHomeSafely(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('예약 저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('타투 예약 신청')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("작업자(인스타 이름)*"),
            TextField(controller: artistIdController),
            const SizedBox(height: 20),

            const Text("이름 / 나이*"),
            TextField(controller: nameController),
            const SizedBox(height: 20),

            const Text("이메일*"),
            TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),

            const Text("시술부위*"),
            TextField(controller: locationController),
            const SizedBox(height: 20),

            const Text("시술부위 사진 (선택)"),
            imageUploadBox(procedureImage, () {
              pickImage((file) => setState(() => procedureImage = file));
            }),
            const SizedBox(height: 20),

            const Text("디자인 설명*"),
            TextField(controller: designTextController, maxLines: 3),
            const SizedBox(height: 20),

            const Text("디자인 사진첨부 (선택)"),
            imageUploadBox(designImage, () {
              pickImage((file) => setState(() => designImage = file));
            }),
            const SizedBox(height: 20),

            const Text("컬러*"),
            TextField(controller: colorController),
            const SizedBox(height: 20),

            const Text("날짜와 시간 (여러 개, 쉼표(,) 또는 줄바꿈으로 구분)*"),
            TextField(controller: datetimeController, maxLines: 2),
            const SizedBox(height: 40),

            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitReservation,
                  child: _submitting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("다음"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget imageUploadBox(File? image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        dashPattern: const [6, 3],
        color: Colors.grey,
        child: Container(
          height: 120,
          width: double.infinity,
          alignment: Alignment.center,
          child: image == null
              ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
              : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 120,
            ),
          ),
        ),
      ),
    );
  }
}
//tattoo_reservation_page.dart