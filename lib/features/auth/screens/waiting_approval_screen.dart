import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/providers/auth_provider.dart';

class WaitingApprovalScreen extends ConsumerStatefulWidget {
  const WaitingApprovalScreen({super.key});

  @override
  ConsumerState<WaitingApprovalScreen> createState() =>
      _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final service = ref.read(authServiceProvider);
    await service.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // ── Real-time approval listener ─────────────────────────────────────────
    // Listens directly to the Firestore-backed clubStatusProvider stream.
    //
    // fireImmediately: true ensures the callback fires with the CURRENT value
    // when this widget first builds — not just on future changes. This covers
    // the edge case where the admin approves the club while the user is still
    // on the RegistrationSuccessScreen animation, so by the time they arrive
    // here the status is already 'approved' and we navigate right away.
    ref.listen<AsyncValue<String?>>(
      clubStatusProvider,
      (previous, next) {
        final status = next.valueOrNull;
        if (status == 'approved' && mounted) {
          context.go('/club/home');
        }
      },
    );

    // ── Immediate Redirect ──────────────────────────────────────────────────
    // Since ref.listen (in build) does not support fireImmediately: true,
    // we manually check if the status is already 'approved' on the first build.
    // We use addPostFrameCallback to avoid navigating DURING the build process.
    final currentStatus = ref.read(clubStatusProvider).valueOrNull;
    if (currentStatus == 'approved') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/club/home');
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Animated pending icon ──────────────────────────────────
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.18),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.hourglass_empty_rounded,
                      size: 56,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // ── Heading ─────────────────────────────────────────────────
              Text(
                'Approval Pending',
                style: AppTextStyles.displayL.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Body text ───────────────────────────────────────────────
              Text(
                'Your club account is currently under review by the administration. This process may take a short while.',
                style: AppTextStyles.bodyM.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'You will automatically be redirected to the dashboard once your account is approved.',
                style: AppTextStyles.bodyS.copyWith(
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
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
                      color: AppColors.warning.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Waiting for approval…',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Refresh button ───────────────────────────────────────────
              // Invalidates the provider so the Firestore stream restarts.
              // Useful if the user suspects their status changed but the
              // stream hasn't fired yet (e.g. after a long background period).
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Deep refresh: clear both role and status cache
                    ref.invalidate(userRoleProvider);
                    ref.invalidate(clubStatusProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Check Status',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Sign out  ─────────────────────────────────
              TextButton(
                onPressed: _signOut,
                child: Text(
                  'Sign out',
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
