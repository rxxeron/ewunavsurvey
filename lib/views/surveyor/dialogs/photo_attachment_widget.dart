import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/photo_attachment_service.dart';

class PhotoAttachmentWidget extends StatelessWidget {
  final String? photoPath;
  final ValueChanged<String?> onPhotoChanged;
  final String label;

  const PhotoAttachmentWidget({
    super.key,
    required this.photoPath,
    required this.onPhotoChanged,
    this.label = 'Feature / Entrance Photo',
  });

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF81C784)),
              title: const Text('Take Photo with Camera', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await PhotoAttachmentService.captureOrPickPhoto(source: ImageSource.camera);
                if (path != null) onPhotoChanged(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF64B5F6)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await PhotoAttachmentService.captureOrPickPhoto(source: ImageSource.gallery);
                if (path != null) onPhotoChanged(path);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty && File(photoPath!).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (hasPhoto)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(photoPath!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  backgroundColor: Colors.black87,
                  radius: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () {
                      PhotoAttachmentService.deletePhoto(photoPath!);
                      onPhotoChanged(null);
                    },
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_a_photo, size: 16, color: Color(0xFF81C784)),
            label: const Text('Attach Photo (Camera / Gallery)', style: TextStyle(fontSize: 12)),
            onPressed: () => _showSourceSheet(context),
          ),
      ],
    );
  }
}
