import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ═════════════════════════════════════════════════════════════════════════════
// AppSnackbar — Evnity Notification
// ═════════════════════════════════════════════════════════════════════════════
//
// Usage:
//   showAppSnackbar(context, 'Profile saved!', type: SnackbarType.success);
//
// Types   : success | warning | error | info
// Animate : slide-up + fade in (280ms) · slide-down + fade out (200ms)
// Dismiss : swipe-down, tap ×, or auto after 3.5s

enum SnackbarType { success, warning, error, info }

// ── Public entry point ────────────────────────────────────────────────────────

void showAppSnackbar(
    BuildContext context,
    String message, {
      SnackbarType type = SnackbarType.info,
    }) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _AppSnackbarWidget(
      message: message,
      type: type,
      onDismiss: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );

  overlay.insert(entry);
}

// ── Widget ────────────────────────────────────────────────────────────────────

class _AppSnackbarWidget extends StatefulWidget {
  final String message;
  final SnackbarType type;
  final VoidCallback onDismiss;

  const _AppSnackbarWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_AppSnackbarWidget> createState() => _AppSnackbarWidgetState();
}

class _AppSnackbarWidgetState extends State<_AppSnackbarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1.0),   // slides down from top
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ),
    );

    _ctrl.forward();
    _timer = Timer(const Duration(milliseconds: 3500), _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  // ── Per-type tokens ───────────────────────────────────────────────────────

  Color get _accent => switch (widget.type) {
    SnackbarType.success => AppColors.success,           // 0xFF16A34A
    SnackbarType.warning => AppColors.warning,           // 0xFFD97706
    SnackbarType.error   => AppColors.error,             // 0xFFDC2626
    SnackbarType.info    => AppColors.primary,           // 0xFF1E40AF
  };

  Color get _surface => switch (widget.type) {
    SnackbarType.success => AppColors.successSurface,    // 0xFFF0FDF4
    SnackbarType.warning => AppColors.errorSurface,    // 0xFFFFFBEB
    SnackbarType.error   => AppColors.errorSurface,      // 0xFFFEF2F2
    SnackbarType.info    => AppColors.primarySurface,    // 0xFFEFF4FF
  };

  Color get _border => switch (widget.type) {
    SnackbarType.success => AppColors.success.withValues(alpha: 0.2),
    SnackbarType.warning => AppColors.warning.withValues(alpha: 0.2),
    SnackbarType.error   => AppColors.error.withValues(alpha: 0.2),
    SnackbarType.info    => AppColors.primaryBorder,     // 0xFFBFD0F5
  };

  IconData get _icon => switch (widget.type) {
    SnackbarType.success => Icons.check_circle_rounded,
    SnackbarType.warning => Icons.warning_amber_rounded,
    SnackbarType.error   => Icons.cancel_rounded,
    SnackbarType.info    => Icons.info_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: GestureDetector(
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) < -200) _dismiss(); // swipe up
                },
                onHorizontalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) > 200) _dismiss();
                },
                child: Material(
                  color: Colors.transparent,
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,       // 0x08000000
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: AppColors.shadowMedium,      // 0x14000000
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ── Left accent stripe ─────────────────────────────────────────
          Container(
            width: 4,
            height: 68,                         // taller stripe
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ── Icon ───────────────────────────────────────────────────────
          Icon(_icon, size: 24, color: _accent), // 20 → 24

          const SizedBox(width: 12),             // 10 → 12

          // ── Message ────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18), // 14 → 18
              child: Text(
                widget.message,
                style: AppTextStyles.labelL.copyWith(
                  // labelL: DM Sans 16px w700 — one step up from labelM
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // ── Dismiss ────────────────────────────────────────────────────
          // GestureDetector(
          //   onTap: _dismiss,
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), // padded to match
          //     child: Icon(
          //       Icons.close_rounded,
          //       size: 18,                       // 16 → 18
          //       color: AppColors.textMuted,
          //     ),
          //   ),
          // ),

        ],
      ),
    );
  }
}


// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../theme/app_colors.dart';
// import '../theme/app_text_styles.dart';
//
// // ═════════════════════════════════════════════════════════════════════════════
// // AppSnackbar – Modern top-sliding overlay notification
// // ═════════════════════════════════════════════════════════════════════════════
// //
// // Usage:
// //   showAppSnackbar(context, 'Profile saved!', type: SnackbarType.success);
// //
// // Types: success | warning | error | info
// // Animation: slides down from top + fade-in (200ms), fades out (150ms)
// // Dismiss: swipe-up, swipe-right, or auto after 3.5s
//
// enum SnackbarType { success, warning, error, info }
//
// // ── Public entry point ────────────────────────────────────────────────────────
//
// void showAppSnackbar(
//   BuildContext context,
//   String message, {
//   SnackbarType type = SnackbarType.info,
// }) {
//   final overlay = Overlay.of(context);
//   late OverlayEntry entry;
//
//   entry = OverlayEntry(
//     builder: (_) => _AppSnackbarWidget(
//       message: message,
//       type: type,
//       onDismiss: () {
//         if (entry.mounted) entry.remove();
//       },
//     ),
//   );
//
//   overlay.insert(entry);
// }
//
// // ── Animated widget ───────────────────────────────────────────────────────────
//
// class _AppSnackbarWidget extends StatefulWidget {
//   final String message;
//   final SnackbarType type;
//   final VoidCallback onDismiss;
//
//   const _AppSnackbarWidget({
//     required this.message,
//     required this.type,
//     required this.onDismiss,
//   });
//
//   @override
//   State<_AppSnackbarWidget> createState() => _AppSnackbarWidgetState();
// }
//
// class _AppSnackbarWidgetState extends State<_AppSnackbarWidget>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<Offset> _slide;
//   late final Animation<double> _fade;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 280),
//       reverseDuration: const Duration(milliseconds: 200),
//     );
//
//     _slide = Tween<Offset>(
//       begin: const Offset(0, -1.4),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
//
//     _fade = Tween<double>(begin: 0, end: 1).animate(
//       CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
//     );
//
//     _ctrl.forward();
//     _timer = Timer(const Duration(milliseconds: 3500), _dismiss);
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     _ctrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _dismiss() async {
//     _timer?.cancel();
//     if (!mounted) return;
//     await _ctrl.reverse();
//     widget.onDismiss();
//   }
//
//   // ── Type config ─────────────────────────────────────────────────────────
//   Color get _accentColor => switch (widget.type) {
//         SnackbarType.success => AppColors.success,
//         SnackbarType.warning => AppColors.warning,
//         SnackbarType.error => AppColors.error,
//         SnackbarType.info => AppColors.primary,
//       };
//
//   Color get _bgColor => switch (widget.type) {
//         SnackbarType.success => AppColors.successSurface,
//         SnackbarType.warning => AppColors.warningSurface,
//         SnackbarType.error => AppColors.errorSurface,
//         SnackbarType.info => AppColors.primarySurface,
//       };
//
//   IconData get _icon => switch (widget.type) {
//         SnackbarType.success => Icons.check_circle_rounded,
//         SnackbarType.warning => Icons.warning_amber_rounded,
//         SnackbarType.error => Icons.error_rounded,
//         SnackbarType.info => Icons.info_rounded,
//       };
//
//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
//           child: SlideTransition(
//             position: _slide,
//             child: FadeTransition(
//               opacity: _fade,
//               child: GestureDetector(
//                 // Swipe up or right to dismiss
//                 onVerticalDragEnd: (d) {
//                   if (d.primaryVelocity != null && d.primaryVelocity! < -200) {
//                     _dismiss();
//                   }
//                 },
//                 onHorizontalDragEnd: (d) {
//                   if (d.primaryVelocity != null && d.primaryVelocity! > 200) {
//                     _dismiss();
//                   }
//                 },
//                 child: Material(
//                   color: Colors.transparent,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: _bgColor,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border(
//                         left: BorderSide(color: _accentColor, width: 4),
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: _accentColor.withValues(alpha: 0.15),
//                           blurRadius: 20,
//                           offset: const Offset(0, 6),
//                         ),
//                         const BoxShadow(
//                           color: AppColors.shadowMedium,
//                           blurRadius: 12,
//                           offset: Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 14),
//                     child: Row(
//                       children: [
//                         // Icon bubble
//                         Container(
//                           width: 38,
//                           height: 38,
//                           decoration: BoxDecoration(
//                             color: _accentColor.withValues(alpha: 0.12),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(_icon, size: 20, color: _accentColor),
//                         ),
//                         const SizedBox(width: 12),
//                         // Message
//                         Expanded(
//                           child: Text(
//                             widget.message,
//                             style: AppTextStyles.bodyM.copyWith(
//                               color: AppColors.textPrimary,
//                               fontWeight: FontWeight.w500,
//                               height: 1.4,
//                             ),
//                           ),
//                         ),
//                         // Dismiss button
//                         GestureDetector(
//                           onTap: _dismiss,
//                           child: Padding(
//                             padding: const EdgeInsets.only(left: 8),
//                             child: Icon(Icons.close_rounded,
//                                 size: 16, color: _accentColor),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
