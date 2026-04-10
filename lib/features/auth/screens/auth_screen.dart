import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/social_auth_button.dart';
import '../widgets/role_card.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_mode_tabs.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Navigate based on role (called after successful auth) ─────────────────
  Future<void> _navigateForRole(String? role) async {
    if (!mounted) return;
    if (role == 'club') {
      try {
        final status = await ref.read(clubStatusProvider.future);
        if (!mounted) return;
        if (status != 'approved') {
          context.go('/waiting-approval');
          return;
        }
      } catch (_) {}
      
      if (mounted) context.go('/club/home');
    } else {
      context.go('/home');
    }
  }

  // ── Email submit ──────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authFormProvider.notifier)
        .submitForm(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );

    final formState = ref.read(authFormProvider);

    // Show error if there is one
    if (formState.errorMessage != null && mounted) {
      _showErrorSnackBar(formState.errorMessage!);
      return;
    }

    if (!mounted) return;

    // Brand-new email registration → redirect to verification screen
    if (formState.isNewEmailRegistration) {
      ref.read(authFormProvider.notifier).clearNewRegistration();
      context.go('/verify-email');
      return;
    }

    // Existing sign-in → navigate by role
    final role = await ref.read(userRoleProvider.future);
    await _navigateForRole(role);
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    final formState = ref.read(authFormProvider);

    // — Problem 2: Role must be selected before Google sign-in ————————
    if (formState.selectedRole == UserRole.none) {
      showAppSnackbar(
        context,
        'Please select your role — Student or Club Organizer — before signing in.',
        type: SnackbarType.warning,
      );
      return;
    }

    final roleStr = formState.selectedRole == UserRole.club
        ? 'club'
        : 'student';

    setState(() => _isGoogleLoading = true);

    try {
      final service = ref.read(authServiceProvider);
      final credential = await service.signInWithGoogle(selectedRole: roleStr);

      if (credential == null) {
        // User cancelled the picker
        setState(() => _isGoogleLoading = false);
        return;
      }

      // — Problem 3: Check role conflict for existing Google users ———————
      if (credential.additionalUserInfo?.isNewUser == false) {
        // Existing user – verify stored role matches selected role.
        final storedRole = await service.getUserRole(credential.user!.uid);
        if (storedRole != null && storedRole != roleStr) {
          // Role mismatch: sign out immediately and show conflict dialog.
          await service.signOut();
          if (mounted) _showConflictDialog(storedRole, roleStr);
          return;
        }
      }

      if (!mounted) return;

      // Brand-new Google user → show success animation first
      if (credential.additionalUserInfo?.isNewUser == true) {
        context.go('/success');
        return;
      }

      // Returning Google user → navigate by role
      final role = await ref.read(userRoleProvider.future);
      await _navigateForRole(role);
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar('Google sign-in failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ── Role-conflict dialog (Problem 3) ─────────────────────────────────
  void _showConflictDialog(String storedRole, String attemptedRole) {
    final message = AuthService.roleConflictMessage(storedRole, attemptedRole);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.warning_amber_rounded,
          size: 32,
          color: AppColors.warning,
        ),
        title: Text('Role Mismatch', style: AppTextStyles.headingM),
        content: Text(message, style: AppTextStyles.bodyM),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  // ── SnackBar helper ───────────────────────────────────────────────────────
  void _showErrorSnackBar(String message) {
    showAppSnackbar(context, message, type: SnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(authFormProvider);
    final formNotifier = ref.read(authFormProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 28),

                  _NavRow(onBack: () => context.go('/onboarding')),
                  const SizedBox(height: 32),

                  Text(
                    'How would you\nlike to join?',
                    style: AppTextStyles.displayL,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formState.isLoginMode
                        ? 'Select your role and sign in to continue.'
                        : 'Select your role and create your account.',
                    style: AppTextStyles.bodyM,
                  ),
                  const SizedBox(height: 28),

                  // ── Role Cards ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: RoleCard(
                          icon: Icons.school_rounded,
                          label: 'Student',
                          sublabel: 'Participant',
                          isSelected:
                              formState.selectedRole == UserRole.student,
                          onTap: () =>
                              formNotifier.selectRole(UserRole.student),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RoleCard(
                          icon: Icons.groups_2_rounded,
                          label: 'Club',
                          sublabel: 'Organization',
                          isSelected: formState.selectedRole == UserRole.club,
                          onTap: () => formNotifier.selectRole(UserRole.club),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Auth Card ────────────────────────────────────────────
                  _AuthCard(
                    formKey: _formKey,
                    formState: formState,
                    formNotifier: formNotifier,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    nameController: _nameController,
                    onSubmit: _handleSubmit,
                  ),
                  const SizedBox(height: 20),

                  _OrDivider(),
                  const SizedBox(height: 20),

                  SocialAuthButton(
                    label: 'Continue with Google',
                    isLoading: _isGoogleLoading,
                    onPressed: _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 28),

                  _FooterToggle(
                    isLoginMode: formState.isLoginMode,
                    onToggle: formNotifier.toggleMode,
                  ),
                  const SizedBox(height: 36),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav Row ───────────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final VoidCallback onBack;
  const _NavRow({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Spacer(),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.event_rounded,
            size: 22,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

// ── Auth Card ─────────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AuthFormState formState;
  final AuthFormNotifier formNotifier;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final VoidCallback onSubmit;

  const _AuthCard({
    required this.formKey,
    required this.formState,
    required this.formNotifier,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 28,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthModeTabs(
              isLoginMode: formState.isLoginMode,
              onModeChanged: (_) => formNotifier.toggleMode(),
            ),
            const SizedBox(height: 20),

            // ── Error Banner ─────────────────────────────────────────────
            if (formState.errorMessage != null) ...[
              _ErrorBanner(message: formState.errorMessage!),
              const SizedBox(height: 16),
            ],

            // ── Name (Sign Up only) ──────────────────────────────────────
            if (!formState.isLoginMode) ...[
              AuthTextField(
                label: 'Full Name',
                controller: nameController,
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
            ],

            // ── Email ────────────────────────────────────────────────────
            AuthTextField(
              label: 'College Email',
              controller: emailController,
              hint: 'you@college.edu',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Password ─────────────────────────────────────────────────
            AuthTextField(
              label: 'Password',
              controller: passwordController,
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              isPasswordVisible: formState.isPasswordVisible,
              onToggleVisibility: formNotifier.togglePasswordVisibility,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'At least 6 characters required';
                return null;
              },
            ),

            // ── Forgot Password ──────────────────────────────────────────
            if (formState.isLoginMode) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: AppTextStyles.labelS.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 22),

            // ── Submit Button ────────────────────────────────────────────
            PrimaryButton(
              label: formState.isLoginMode ? 'Sign In' : 'Create Account',
              isLoading: formState.isLoading,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Or Divider ────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('or continue with', style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
      ],
    );
  }
}

// ── Footer Toggle ─────────────────────────────────────────────────────────────

class _FooterToggle extends StatelessWidget {
  final bool isLoginMode;
  final VoidCallback onToggle;

  const _FooterToggle({required this.isLoginMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodyS,
          children: [
            TextSpan(
              text: isLoginMode
                  ? "Don't have an account? "
                  : "Already have an account? ",
            ),
            TextSpan(
              text: isLoginMode ? 'Sign Up' : 'Sign In',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              recognizer: TapGestureRecognizer()..onTap = onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
