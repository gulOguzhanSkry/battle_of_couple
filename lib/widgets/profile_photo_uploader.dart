import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class ProfilePhotoUploader extends StatefulWidget {
  final String userId;
  final String? currentPhotoUrl;
  final String displayName;
  final double radius;
  final VoidCallback? onPhotoUpdated;

  const ProfilePhotoUploader({
    super.key,
    required this.userId,
    this.currentPhotoUrl,
    required this.displayName,
    this.radius = 50,
    this.onPhotoUpdated,
  });

  @override
  State<ProfilePhotoUploader> createState() => _ProfilePhotoUploaderState();
}

class _ProfilePhotoUploaderState extends State<ProfilePhotoUploader> {
  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('${widget.userId}.jpg');

      await ref.putFile(File(image.path));
      final downloadUrl = await ref.getDownloadURL();

      // Update User Profile
      await _userService.updateProfilePhoto(widget.userId, downloadUrl);

      if (widget.onPhotoUpdated != null) {
        widget.onPhotoUpdated!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil fotoğrafı güncellendi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUploadImage,
          child: CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: widget.currentPhotoUrl != null && widget.currentPhotoUrl!.isNotEmpty
                ? NetworkImage(widget.currentPhotoUrl!)
                : null,
            child: _isUploading
                ? const CircularProgressIndicator()
                : (widget.currentPhotoUrl == null || widget.currentPhotoUrl!.isEmpty)
                    ? Text(
                        widget.displayName.isNotEmpty
                            ? widget.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(fontSize: widget.radius * 0.8, color: Colors.grey.shade600),
                      )
                    : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
