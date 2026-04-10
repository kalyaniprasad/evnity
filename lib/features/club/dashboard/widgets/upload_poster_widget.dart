import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class UploadPosterWidget extends StatelessWidget {
  final File? imageFile;
  final String? existingImageUrl;
  final VoidCallback onTap;

  const UploadPosterWidget({
    super.key,
    required this.imageFile,
    this.existingImageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected =
        imageFile != null ||
        (existingImageUrl != null && existingImageUrl!.isNotEmpty);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        height: 168,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2.0 : 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: isSelected
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageFile != null)
                      Image.file(imageFile!, fit: BoxFit.cover)
                    else if (existingImageUrl != null)
                      Image.network(
                        existingImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Center(child: Icon(Icons.error)),
                      ),
                    Container(color: Colors.black.withValues(alpha: 0.3)),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to change image',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 26,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Upload Event Poster', style: AppTextStyles.labelM),
                  const SizedBox(height: 4),
                  Text('JPG or PNG · Max 5MB', style: AppTextStyles.caption),
                ],
              ),
      ),
    );
  }
}
