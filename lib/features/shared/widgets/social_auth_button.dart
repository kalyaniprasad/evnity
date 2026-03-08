import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';

/// Google social login button with a custom painted G logo.
class SocialAuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;        // ADD THIS

  const SocialAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,    // ADD THIS
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(           // show spinner while loading
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.primary,
          ),
        ) : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GoogleGIcon(size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google "G" Logo ───────────────────────────────────────────────────────────

class GoogleGIcon extends StatelessWidget {
  final double size;

  const GoogleGIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final paint = Paint()..style = PaintingStyle.fill;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Blue arc
    paint.color = AppColors.googleBlue;
    canvas.drawArc(rect, -0.1, 1.68, true, paint);

    // Green arc
    paint.color = AppColors.googleGreen;
    canvas.drawArc(rect, 1.58, 1.58, true, paint);

    // Yellow arc
    paint.color = AppColors.googleYellow;
    canvas.drawArc(rect, 3.16, 1.0, true, paint);

    // Red arc
    paint.color = AppColors.googleRed;
    canvas.drawArc(rect, 4.16, 1.26, true, paint);

    // White donut center
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.65, paint);

    // Blue crossbar
    paint.color = AppColors.googleBlue;
    canvas.drawRect(
      Rect.fromLTWH(cx - 0.5, cy - r * 0.18, r * 1.08, r * 0.36),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
