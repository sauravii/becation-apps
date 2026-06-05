import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../components/skeleton_circle_avatar.dart';
import '../../services/auth_service.dart';
import '../../services/media_service.dart';
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
  final String _uid = AuthService.currentUid ?? '';
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    _originalName =
        user?.displayName ?? user?.email?.split('@').first ?? '';
    _nameCtrl = TextEditingController(text: _originalName);
    _userStream = UserService.userStream(_uid);
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
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (err) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $err')),
      );
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;

    try {
      final file = await MediaService.pickProfilePhoto();
      if (file == null) return;

      setState(() => _isUploadingPhoto = true);
      await UserService.uploadProfilePhoto(file);
      await MediaService.deleteTemp(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo uploaded successfully')),
      );
    } on MediaException catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.message)),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $err')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes to your name. Leave without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8B2C2C)),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final discard = await _confirmDiscard();
        if (discard) nav.pop();
      },
      child: Scaffold(
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
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _userStream,
              builder: (context, snap) {
                final waitingStream =
                    snap.connectionState == ConnectionState.waiting;
                final data = snap.data?.data();
                final photoUrl = (data?['photoUrl'] as String?) ?? '';
                final hasPhoto = photoUrl.isNotEmpty;

                Widget avatar;
                if (waitingStream) {
                  avatar = const SkeletonCircleAvatar(radius: 56);
                } else if (!hasPhoto) {
                  avatar = const CircleAvatar(
                    radius: 56,
                    backgroundColor: Color(0xFFE9DFF0),
                    child: Icon(Icons.person,
                        size: 72, color: _kPurple),
                  );
                } else {
                  avatar = ClipOval(
                    child: SizedBox(
                      width: 112,
                      height: 112,
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const SkeletonCircleAvatar(radius: 56);
                        },
                        errorBuilder: (_, __, ___) => const CircleAvatar(
                          radius: 56,
                          backgroundColor: Color(0xFFE9DFF0),
                          child: Icon(Icons.person,
                              size: 72, color: _kPurple),
                        ),
                      ),
                    ),
                  );
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    avatar,
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
