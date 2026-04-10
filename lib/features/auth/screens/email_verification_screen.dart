import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/app_snackbar.dart';

// ── Email Verification Pending Screen ─────────────────────────────────────────
// Shown after a brand-new email/password registration.
// Polls Firebase every 3 s to detect when the user clicks the link.

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  Timer? _resendTimer;
  int _resendCooldown = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String get _email => FirebaseAuth.instance.currentUser?.email ?? 'your email';

  @override
  void initState() {
    super.initState();

    // Subtle envelope pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Poll Firebase every 3 s for email verification
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final service = ref.read(authServiceProvider);
      final verified = await service.reloadAndCheckVerified();
      if (verified && mounted) {
        _pollTimer?.cancel();
        context.go('/success');
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _resendTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;
    try {
      final service = ref.read(authServiceProvider);
      await service.resendVerificationEmail();
      if (mounted) {
        showAppSnackbar(
          context,
          'Verification email sent again!',
          type: SnackbarType.success,
        );
        setState(() => _resendCooldown = 60);
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          setState(() {
            _resendCooldown--;
            if (_resendCooldown <= 0) t.cancel();
          });
        });
      }
    } catch (_) {
      if (mounted) {
        showAppSnackbar(
          context,
          'Failed to resend email. Try again.',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _signOut() async {
    _pollTimer?.cancel();
    final service = ref.read(authServiceProvider);
    await service.signOut();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Animated envelope icon ──────────────────────────────────
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.mark_email_unread_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // ── Heading ─────────────────────────────────────────────────
              Text(
                'Check your inbox!',
                style: AppTextStyles.displayL.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Body text ───────────────────────────────────────────────
              Text(
                'We\'ve sent a verification link to',
                style: AppTextStyles.bodyM,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _email,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Click the link in the email to continue.\nThis page will update automatically.',
                style: AppTextStyles.bodyS.copyWith(height: 1.6),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // ── Waiting indicator ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Waiting for verification…',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Resend button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _resendCooldown > 0 ? null : _resendEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.35,
                    ),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _resendCooldown > 0
                        ? 'Resend in ${_resendCooldown}s'
                        : 'Resend verification email',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Wrong email / sign out  ─────────────────────────────────
              TextButton(
                onPressed: _signOut,
                child: Text(
                  'Wrong email? Sign out',
                  style: AppTextStyles.labelS.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
