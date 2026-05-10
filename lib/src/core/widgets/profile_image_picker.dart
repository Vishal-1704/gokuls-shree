import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

/// Profile image picker with Supabase storage upload
class ProfileImagePicker extends ConsumerStatefulWidget {
  final String? currentImageUrl;
  final String userId;
  final double size;
  final Function(String imageUrl)? onImageUploaded;

  const ProfileImagePicker({
    super.key,
    this.currentImageUrl,
    required this.userId,
    this.size = 100,
    this.onImageUploaded,
  });

  @override
  ConsumerState<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends ConsumerState<ProfileImagePicker> {
  static const String _profileBucket = 'profile-images';

  File? _selectedImage;
  bool _isUploading = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.currentImageUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Upload to Supabase Storage
        await _uploadImage();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      // Image is already compressed by image_picker via imageQuality/maxWidth.
      final bytes = await _selectedImage!.readAsBytes();
      final filePath =
          'students/${widget.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload binary image to Supabase Storage
      await supabase.storage.from(_profileBucket).uploadBinary(filePath, bytes);

      final imageUrl = supabase.storage
          .from(_profileBucket)
          .getPublicUrl(filePath);

      // Remove previously stored storage object if it belongs to the same bucket.
      final oldPath = _extractStoragePath(_imageUrl);
      if (oldPath != null && oldPath != filePath) {
        await supabase.storage.from(_profileBucket).remove([oldPath]);
      }

      // Persist only URL in DB (small footprint).
      await supabase
          .from('students')
          .update({'photo_url': imageUrl})
          .eq('id', widget.userId);

      setState(() {
        _imageUrl = imageUrl;
        _selectedImage = null;
        _isUploading = false;
      });

      widget.onImageUploaded?.call(imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Update Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_imageUrl != null)
                    _buildSourceOption(
                      icon: Icons.delete,
                      label: 'Remove',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _removeImage();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeImage() async {
    final existingPath = _extractStoragePath(_imageUrl);

    setState(() {
      _selectedImage = null;
      _imageUrl = null;
    });

    try {
      if (existingPath != null) {
        await supabase.storage.from(_profileBucket).remove([existingPath]);
      }

      await supabase
          .from('students')
          .update({'photo_url': null})
          .eq('id', widget.userId);
    } catch (e) {
      debugPrint('Error removing image: $e');
    }
  }

  String? _extractStoragePath(String? url) {
    if (url == null || url.isEmpty) return null;

    final marker = '/storage/v1/object/public/$_profileBucket/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;

    return url.substring(idx + marker.length);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Stack(
        children: [
          // Avatar
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(child: _buildAvatarContent()),
          ),

          // Edit button
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),

          // Loading overlay
          if (_isUploading)
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    }

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Image.network(
        _imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildLogoFallback();
        },
      );
    }

    return _buildLogoFallback();
  }

  Widget _buildLogoFallback() {
    return Padding(
      padding: EdgeInsets.all(widget.size * 0.22),
      child: Image.asset('assets/images/school_logo.png', fit: BoxFit.contain),
    );
  }
}
