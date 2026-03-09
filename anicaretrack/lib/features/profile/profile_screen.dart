import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

/// ───────────────── AniCareTrack Theme ─────────────────

const Color primary = Color(0xFF4A90E2);
const Color secondary = Color(0xFF7EDDD3);
const Color background = Color(0xFFFFF9F2);
const Color text = Color(0xFF333333);
const Color accent = Color(0xFFFF7A7A);

const Color card = Colors.white;
const Color border = Color(0xFFE6E6E6);
const Color textSecondary = Color(0xFF7A7A7A);

/// ───────────────── Simple Auth State (if not available globally) ─────────────────

class AuthState {
  static final _instance = AuthState._();

  factory AuthState() {
    return _instance;
  }

  AuthState._();

  final _auth = FirebaseAuth.instance;

  bool get isLoggedIn => _auth.currentUser != null;
  String get userId => _auth.currentUser?.uid ?? '';
  String get userEmail => _auth.currentUser?.email ?? '';
  String get userName => _auth.currentUser?.displayName ?? 'User';
  String get initials {
    final parts = userName.split(' ');
    if (parts.isEmpty) return '?';
    final letters = parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();
    return (letters.padRight(2, '?')).substring(0, 2);
  }

  String userRole = 'Owner'; // Default, should be fetched from Firestore

  Future<void> logout() async {
    await _auth.signOut();
  }
}

/// ───────────────── Profile Page ─────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _profileImageUrl;
  bool _isUploading = false;
  String _userRole = 'Owner';
  Map<String, dynamic> _userData = {};

  bool _isEditing = false;
  Map<String, dynamic> _petData = {};
  String _petAge = '';
  String _petBreed = '';
  String _petLikes = '';
  String _petDislikes = '';

  late TextEditingController _ageController;
  late TextEditingController _breedController;
  late TextEditingController _likesController;
  late TextEditingController _dislikesController;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _loadProfile();

    _ageController = TextEditingController();
    _breedController = TextEditingController();
    _likesController = TextEditingController();
    _dislikesController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _ageController.dispose();
    _breedController.dispose();
    _likesController.dispose();
    _dislikesController.dispose();
    super.dispose();
  }

  /// ───────────── Load profile data ─────────────
  Future<void> _loadProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _userData = data;
          _profileImageUrl = data['photoUrl'];
          _userRole = data['role'] ?? 'Owner';
        });

        if (_userRole == 'Owner') {
          _petData = data['pet'] ?? {};
          _petAge = _petData['age'] ?? '';
          _petBreed = _petData['breed'] ?? '';
          _petLikes = _petData['likes'] ?? '';
          _petDislikes = _petData['dislikes'] ?? '';
          _ageController.text = _petAge;
          _breedController.text = _petBreed;
          _likesController.text = _petLikes;
          _dislikesController.text = _petDislikes;
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  /// ───────────── Upload image to Cloudinary ─────────────
  Future<void> _uploadProfileImage(XFile imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await imageFile.readAsBytes();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/demtcemkk/image/upload'),
      );

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: imageFile.name),
      );

      request.fields['upload_preset'] = 'tendertrust_upload';

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseData);

        String imageUrl = jsonData['secure_url'];

        await _firestore.collection('users').doc(uid).update({
          'photoUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _profileImageUrl = imageUrl;
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile photo updated"),
              backgroundColor: secondary,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    }
  }

  /// ───────────── Pick Image ─────────────
  Future<void> _pickImage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Change Profile Photo",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: text,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primary),
              title: const Text("Take Photo"),
              onTap: () => Navigator.pop(ctx, "camera"),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primary),
              title: const Text("Choose from Gallery"),
              onTap: () => Navigator.pop(ctx, "gallery"),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (result == null) return;

    XFile? picked;

    final source = result == "camera"
        ? ImageSource.camera
        : ImageSource.gallery;

    picked = await _picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (picked != null) {
      await _uploadProfileImage(picked);
    }
  }

  /// ───────────── Logout ─────────────
  void _logout() {
    AuthState().logout().then((_) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
  }

  /// ───────────── Save Profile ─────────────
  Future<void> _saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _petAge = _ageController.text;
      _petBreed = _breedController.text;
      _petLikes = _likesController.text;
      _petDislikes = _dislikesController.text;
    });

    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_userRole == 'Owner') {
        updateData['pet'] = {
          'age': _petAge,
          'breed': _petBreed,
          'likes': _petLikes,
          'dislikes': _petDislikes,
        };
      }

      await _firestore.collection('users').doc(uid).update(updateData);

      setState(() => _isEditing = false);

      _loadProfile(); // reload to update view

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated"),
            backgroundColor: secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    }
  }

  /// ───────────── UI ─────────────

  @override
  Widget build(BuildContext context) {
    final auth = AuthState();

    if (!auth.isLoggedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final displayName = auth.userName;
    final displayEmail = auth.userEmail;
    final roleDisplay = _userRole == 'Owner' ? 'Pet Owner' : 'Pet Walker';

    if (_isEditing) {
      return _buildEditScreen(displayName, displayEmail, roleDisplay);
    } else {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: background,
          centerTitle: true,
          title: const Text(
            "My Profile",
            style: TextStyle(color: text, fontWeight: FontWeight.bold),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  /// ───────── HEADER SECTION ─────────
                  _buildHeaderSection(displayName, roleDisplay),

                  const SizedBox(height: 30),

                  /// ───────── INFO CARDS ─────────
                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    label: "Email",
                    value: displayEmail,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.pets,
                    label: "Account Type",
                    value: roleDisplay,
                  ),

                  const SizedBox(height: 30),

                  /// ───────── PET INFO SECTION (if Owner) ─────────
                  if (_userRole == 'Owner') ...[
                    _buildPetInfoSection(),
                    const SizedBox(height: 30),
                  ],

                  /// ───────── STATS SECTION ─────────
                  _buildStatsSection(),

                  const SizedBox(height: 30),

                  /// ───────── QUICK ACTIONS ─────────
                  _buildQuickActionsSection(),

                  const SizedBox(height: 30),

                  /// ───────── LOGOUT BUTTON ─────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        "Log Out",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: const BorderSide(color: accent, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  /// ───────── HEADER SECTION ─────────
  Widget _buildHeaderSection(String name, String role) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: primary,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? Text(
                          AuthState().initials,
                          style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: text,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: secondary, width: 1),
          ),
          child: Text(
            role,
            style: const TextStyle(
              color: secondary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// ───────── INFO CARD WIDGET ─────────
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ───────── STATS SECTION ─────────
  Widget _buildStatsSection() {
    final isOwner = _userRole == 'Owner';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Statistics",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today,
                label: isOwner ? "Bookings" : "Jobs Completed",
                value: "${_userData['bookings'] ?? 0}",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                label: "Rating",
                value: "${_userData['rating']?.toStringAsFixed(1) ?? '0.0'} ★",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: isOwner ? Icons.favorite : Icons.group,
                label: isOwner ? "Favorites" : "Families Served",
                value: "${_userData['favorites'] ?? 0}",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.verified,
                label: "ID Verified",
                value: (_userData['idVerified'] ?? false) ? "Yes" : "No",
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ───────── STAT CARD ─────────
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: secondary, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }

  /// ───────── PET INFO SECTION ─────────
  Widget _buildPetInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Pet Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ),
        _buildInfoCard(
          icon: Icons.cake,
          label: "Age",
          value: _petAge.isNotEmpty ? _petAge : "Not specified",
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.pets,
          label: "Breed",
          value: _petBreed.isNotEmpty ? _petBreed : "Not specified",
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.favorite,
          label: "Likes",
          value: _petLikes.isNotEmpty ? _petLikes : "Not specified",
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.thumb_down,
          label: "Dislikes",
          value: _petDislikes.isNotEmpty ? _petDislikes : "Not specified",
        ),
      ],
    );
  }

  /// ───────── QUICK ACTIONS ─────────
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ),
        _buildQuickActionRow(
          icon: Icons.edit,
          label: "Edit Profile",
          onTap: () {
            setState(() => _isEditing = true);
          },
        ),
        _buildQuickActionRow(
          icon: Icons.notifications,
          label: "Notifications",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Notifications - Coming Soon")),
            );
          },
        ),
        _buildQuickActionRow(
          icon: Icons.security,
          label: "Privacy & Safety",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Privacy & Safety - Coming Soon")),
            );
          },
        ),
        _buildQuickActionRow(
          icon: Icons.help,
          label: "Help & Support",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Help & Support - Coming Soon")),
            );
          },
        ),
      ],
    );
  }

  /// ───────── QUICK ACTION ROW ─────────
  Widget _buildQuickActionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: text,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  /// ───────── EDIT SCREEN ─────────
  Widget _buildEditScreen(String displayName, String displayEmail, String roleDisplay) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: background,
        centerTitle: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: text, fontWeight: FontWeight.bold),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                /// ───────── HEADER SECTION ─────────
                _buildHeaderSection(displayName, roleDisplay),

                const SizedBox(height: 30),

                /// ───────── INFO CARDS ─────────
                _buildInfoCard(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: displayEmail,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.pets,
                  label: "Account Type",
                  value: roleDisplay,
                ),

                const SizedBox(height: 30),

                /// ───────── PET EDIT SECTION (if Owner) ─────────
                if (_userRole == 'Owner') ...[
                  _buildPetEditSection(),
                  const SizedBox(height: 30),
                ],

                /// ───────── SAVE/CANCEL BUTTONS ─────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _isEditing = false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondary,
                          side: const BorderSide(color: border),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ───────── PET EDIT SECTION ─────────
  Widget _buildPetEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Pet Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ),
        TextField(
          controller: _ageController,
          decoration: const InputDecoration(
            labelText: "Pet Age",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _breedController,
          decoration: const InputDecoration(
            labelText: "Pet Breed",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _likesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "What your pet likes",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dislikesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "What your pet dislikes",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
