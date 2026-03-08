import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class UploadPosterWidget extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const UploadPosterWidget({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBorder,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Poster Selected',
                    style: AppTextStyles.labelM
                        .copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to change image',
                    style: AppTextStyles.caption,
                  ),
                ],
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
                  Text(
                    'JPG or PNG · Max 5MB',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
      ),
    );
  }
}
