import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/user_service.dart';

const Color _kPurple = Color(0xFF6F5AAA);
const Color _kPurpleLight = Color(0xFF9886C5);

/// Halaman edit profile. Editable: displayName + photoUrl.
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nameCtrl;
  final FocusNode _nameFocus = FocusNode();
  bool _isEditingName = false;
  String _originalName = '';
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _originalName =
        user?.displayName ?? user?.email?.split('@').first ?? '';
    _nameCtrl = TextEditingController(text: _originalName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final trimmed = _nameCtrl.text.trim();
    return trimmed.isNotEmpty && trimmed != _originalName.trim();
  }

  void _startEditing() {
    setState(() => _isEditingName = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await UserService.updateDisplayName(_nameCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      Navigator.of(context).pop(true);
    } catch (err) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $err')),
      );
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File path tidak tersedia')),
        );
        return;
      }

      final file = File(path);
      final size = await file.length();
      const maxBytes = 5 * 1024 * 1024;
      if (size > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto melebihi 5 MB')),
        );
        return;
      }

      setState(() => _isUploadingPhoto = true);
      await UserService.uploadProfilePhoto(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profile berhasil diunggah')),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload foto: $err')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1B20),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        child: Column(
          children: [
            // Profile photo — listen ke Firestore supaya auto-refresh setelah upload.
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: UserService.userStream(_uid),
              builder: (context, snap) {
                final data = snap.data?.data();
                final photoUrl = (data?['photoUrl'] as String?) ?? '';
                final hasPhoto = photoUrl.isNotEmpty;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: const Color(0xFFE9DFF0),
                      backgroundImage:
                          hasPhoto ? NetworkImage(photoUrl) : null,
                      child: hasPhoto
                          ? null
                          : const Icon(Icons.person,
                              size: 72, color: _kPurple),
                    ),
                    if (_isUploadingPhoto)
                      const SizedBox(
                        width: 112,
                        height: 112,
                        child: CircularProgressIndicator(
                          color: _kPurple,
                          strokeWidth: 3,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              child: const Text(
                'Edit Photo',
                style: TextStyle(
                  color: _kPurpleLight,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: _kPurpleLight,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Name field
            _NameField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              editing: _isEditingName,
              onTapEdit: _startEditing,
              onChange: () => setState(() {}),
            ),
            const SizedBox(height: 32),
            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _hasChanges && !_isSaving ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool editing;
  final VoidCallback onTapEdit;
  final VoidCallback onChange;

  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.editing,
    required this.onTapEdit,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Name',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          if (editing)
            TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (_) => onChange(),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _kPurple, width: 2),
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1C1B20),
              ),
            )
          else
            InkWell(
              onTap: onTapEdit,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.text.isEmpty ? '—' : controller.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: controller.text.isEmpty
                              ? Colors.grey
                              : const Color(0xFF1C1B20),
                        ),
                      ),
                    ),
                    Icon(Icons.edit_outlined,
                        size: 18, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
