import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  bool _isLoading = true;
  bool _isSaving = false;

  String role = '';
  String profileImageUrl = '';

  File? _selectedImage;

  final picker = ImagePicker();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _rateController = TextEditingController();

  bool idVerified = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = _auth.currentUser!.uid;

      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final data = doc.data()!;

      role = (data['role'] ?? '').toString().trim();
      profileImageUrl = data['profileImageUrl'] ?? '';

      if (role.toLowerCase() == 'owner') {
        _nameController.text = data['name'] ?? '';
        _addressController.text = data['address'] ?? '';
        _phoneController.text = data['phone'] ?? '';
      } else {
        _bioController.text = data['bio'] ?? '';
        _experienceController.text = data['experience'] ?? '';
        _rateController.text = data['ratePerHour']?.toString() ?? '';
        idVerified = data['idVerified'] ?? false;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return profileImageUrl;

    final uid = _auth.currentUser!.uid;

    final ref = _storage.ref().child('profile_images').child('$uid.jpg');

    await ref.putFile(_selectedImage!);

    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final uid = _auth.currentUser!.uid;

    final imageUrl = await _uploadImage();

    Map<String, dynamic> data = {
      'profileImageUrl': imageUrl
    };

    if (role.toLowerCase() == 'owner') {
      data.addAll({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
    } else {
      data.addAll({
        'bio': _bioController.text.trim(),
        'experience': _experienceController.text.trim(),
        'ratePerHour': double.tryParse(_rateController.text.trim()) ?? 0,
        'idVerified': idVerified,
      });
    }

    await _firestore.collection('users').doc(uid).update(data);

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Updated")),
    );
  }

  Widget profileImageWidget() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: CircleAvatar(
          radius: 55,
          backgroundImage: _selectedImage != null
              ? FileImage(_selectedImage!)
              : (profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : null) as ImageProvider?,
          child: (_selectedImage == null && profileImageUrl.isEmpty)
              ? const Icon(Icons.camera_alt, size: 35)
              : null,
        ),
      ),
    );
  }

  Widget ownerUI() {
    return Column(
      children: [

        profileImageWidget(),
        const SizedBox(height: 20),

        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Name"),
          validator: (v) => v == null || v.isEmpty ? "Required" : null,
        ),

        const SizedBox(height: 15),

        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: "Address"),
          validator: (v) => v == null || v.isEmpty ? "Required" : null,
        ),

        const SizedBox(height: 15),

        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: "Phone"),
          keyboardType: TextInputType.phone,
          validator: (v) => v == null || v.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget walkerUI() {
    return Column(
      children: [

        profileImageWidget(),
        const SizedBox(height: 20),

        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(labelText: "Bio"),
          validator: (v) => v == null || v.isEmpty ? "Required" : null,
        ),

        const SizedBox(height: 15),

        TextFormField(
          controller: _experienceController,
          decoration: const InputDecoration(labelText: "Experience"),
          validator: (v) => v == null || v.isEmpty ? "Required" : null,
        ),

        const SizedBox(height: 15),

        TextFormField(
          controller: _rateController,
          decoration: const InputDecoration(labelText: "Rate per Hour"),
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.isEmpty ? "Required" : null,
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            const Text("ID Verification Status"),
            const Spacer(),
            Switch(
              value: idVerified,
              onChanged: (value) {
                setState(() {
                  idVerified = value;
                });
              },
            )
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              role.toLowerCase() == 'owner'
                  ? ownerUI()
                  : walkerUI(),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}