import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TattooReservationPage extends StatefulWidget {
  @override
  _TattooReservationPageState createState() => _TattooReservationPageState();
}

class _TattooReservationPageState extends State<TattooReservationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // ✅ Firebase Storage에 이미지 업로드
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('tattoo_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // ✅ Firestore에 예약 정보 저장
      await FirebaseFirestore.instance.collection('reservations').add({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'area': _areaController.text.trim(),
        'description': _descriptionController.text.trim(),
        'color': _colorController.text.trim(),
        'date': _dateController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'guest',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 예약이 완료되었습니다.')),
      );

      setState(() {
        _nameController.clear();
        _emailController.clear();
        _descriptionController.clear();
        _colorController.clear();
        _dateController.clear();
        _areaController.clear();
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ 오류 발생: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('타투 예약하기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (v) => v!.isEmpty ? '이름을 입력하세요' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: '이메일'),
                validator: (v) => v!.isEmpty ? '이메일을 입력하세요' : null,
              ),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: '시술 부위'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '디자인 설명'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: '원하는 색상'),
              ),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: '날짜/시간'),
              ),
              const SizedBox(height: 20),

              // ✅ 이미지 선택 영역
              _selectedImage == null
                  ? TextButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('시술 부위 사진 선택'),
                onPressed: _pickImage,
              )
                  : Column(
                children: [
                  Image.file(_selectedImage!, height: 200),
                  TextButton(
                    onPressed: () => setState(() => _selectedImage = null),
                    child: const Text('사진 제거'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitReservation,
                child: const Text('예약 제출'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} //RESERVATION.DART
