import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Registration Success Screen — Premium Fintech-style
// Sequence (all durations per the spec):
//   0 ms    → play crystalline chime + light haptic
//   0 ms    → circle scales in from 0→60px (80ms, easeOutBack)
//   0 ms    → background of circle transitions neutral→#22C55E (200ms)
//  100 ms   → checkmark draws (trim-path, 300ms, cubic-bezier(0.65,0,0.45,1))
//  300 ms   → circle pulse 1.0→1.15→1.0 + haptic impact + confetti burst
//  300 ms   → sonar ripple rings expand
//  500 ms   → text slides up
// 2600 ms   → navigate by role
// ──────────────────────────────────────────────────────────────────────────────

class RegistrationSuccessScreen extends ConsumerStatefulWidget {
  const RegistrationSuccessScreen({super.key});
  @override
  ConsumerState<RegistrationSuccessScreen> createState() => _RegSuccessState();
}

class _RegSuccessState extends ConsumerState<RegistrationSuccessScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  late final AnimationController _masterCtrl; // 1600ms — everything
  late final AnimationController _textCtrl; // 400ms  — text slide
  late final AnimationController _dotCtrl; // looping dots

  // ── Sub-animations (derived from _masterCtrl using Interval) ─────────────
  // Circle: scale-in 60px
  late final Animation<double> _circleScale;
  // Circle: color shift neutral → success green
  late final Animation<double> _colorShift;
  // Checkmark trim-path (cubic-bezier 0.65,0,0.45,1)
  late final Animation<double> _checkTrim;
  // Circle pulse at impact
  late final Animation<double> _circlePulse;
  // Sonar ripple rings × 3
  late final Animation<double> _ring1;
  late final Animation<double> _ring2;
  late final Animation<double> _ring3;
  // Ambient glow opacity
  late final Animation<double> _glowPulse;
  // Confetti progress
  late final Animation<double> _confettiProg;
  // Sparkles
  late final Animation<double> _sparkleProg;

  // ── Text
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  // ── Dots loop value (0→1 repeating)
  late final Animation<double> _dotAnim;

  // ── 70 confetti particles (seeded random for consistency)
  late final List<_Particle> _particles;
  final _rng = math.Random(7);

  // ── Audio + Haptic ──────────────────────────────────────────────────────────
  final _audio = AudioPlayer();

  // ── Colours ────────────────────────────────────────────────────────────────
  static const _successGreen = Color(0xFF22C55E);
  static const _neutralGrey = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _particles = List.generate(65, (_) => _Particle(_rng));

    // ── Master: 1600ms ─────────────────────────────────────────────────────
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // circle scale-in: 0–5% (0–80ms), easeOutBack
    _circleScale = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0, 0.05, curve: _EaseOutBackCurve()),
    );

    // color shift neutral→green: 0–13% (0–200ms)
    _colorShift = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0, 0.13, curve: Curves.easeInOut),
    );

    // checkmark draw: 6.25–25% (100–400ms) — cubic-bezier(0.65,0,0.45,1)
    _checkTrim = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0625, 0.25, curve: _InkDryCurve()),
    );

    // circle pulse: 19–40% (300–640ms)
    _circlePulse =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 1.0,
              end: 1.16,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 35,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.16,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.elasticIn)),
            weight: 65,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _masterCtrl,
            curve: const Interval(0.19, 0.40),
          ),
        );

    // glow breathe: 0–60%
    _glowPulse =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.0,
              end: 0.45,
            ).chain(CurveTween(curve: Curves.easeIn)),
            weight: 30,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 0.45,
              end: 0.28,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 70,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _masterCtrl,
            curve: const Interval(0.0, 0.60),
          ),
        );

    // sonar rings — 3 staggered rings 19–100%
    _ring1 = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.19, 0.75, curve: Curves.easeOut),
    );
    _ring2 = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOut),
    );
    _ring3 = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.32, 1.00, curve: Curves.easeOut),
    );

    // confetti: 19–100%
    _confettiProg = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.19, 1.0, curve: Curves.easeOut),
    );

    // sparkles: 19–62%
    _sparkleProg = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.19, 0.62, curve: Curves.easeInOut),
    );

    // ── Text: 400ms ────────────────────────────────────────────────────────
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);

    // ── Dots loop ──────────────────────────────────────────────────────────
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotAnim = _dotCtrl;

    _runSequence();
  }

  Future<void> _runSequence() async {
    // t=0: sound + light haptic
    HapticFeedback.lightImpact();
    try {
      await _audio.play(AssetSource('sounds/success.wav'));
    } catch (_) {}

    _masterCtrl.forward();

    // t=300ms: impact haptic for the circle pulse moment
    await Future.delayed(const Duration(milliseconds: 300));
    HapticFeedback.mediumImpact();

    // t=500ms: slide up text
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _textCtrl.forward();

    // t=2600ms: navigate
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String? role;
    if (uid != null) {
      role = await ref.read(authServiceProvider).getUserRole(uid);
    }
    if (!mounted) return;
    context.go(role == 'club' ? '/club/home' : '/search');
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _textCtrl.dispose();
    _dotCtrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Animation canvas ──────────────────────────────────────────
              SizedBox(
                width: 320,
                height: 320,
                child: AnimatedBuilder(
                  animation: _masterCtrl,
                  builder: (context, child) {
                    final circleColor = Color.lerp(
                      _neutralGrey,
                      _successGreen,
                      _colorShift.value,
                    )!;
                    final pulse = _masterCtrl.value > 0.19
                        ? _circlePulse.value
                        : 1.0;
                    return CustomPaint(
                      painter: _SuccessPainter(
                        circleScale: _circleScale.value,
                        circlePulse: pulse,
                        circleColor: circleColor,
                        checkTrim: _checkTrim.value,
                        ring1: _ring1.value,
                        ring2: _ring2.value,
                        ring3: _ring3.value,
                        glowOpacity: _glowPulse.value,
                        confettiProg: _confettiProg.value,
                        sparkleProg: _sparkleProg.value,
                        particles: _particles,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // ── Text block ────────────────────────────────────────────────
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Text(
                          "You're all set! 🎉",
                          style: GoogleFonts.dmSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111827),
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Welcome to Evnity.\nYour campus just got better.',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B7280),
                            height: 1.55,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // ── "Entering the app…" + animated dots ──────────────────────
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: AnimatedBuilder(
                      animation: _dotAnim,
                      builder: (context, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Entering the app',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            ..._buildDots(_dotAnim.value),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDots(double t) {
    return List.generate(3, (i) {
      final phase = (t - i * 0.28).clamp(0.0, 1.0);
      final opacity = math.sin(phase * math.pi).clamp(0.0, 1.0);
      return Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Opacity(
          opacity: 0.25 + opacity * 0.75,
          child: Text(
            '.',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    });
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Custom Painter
// ──────────────────────────────────────────────────────────────────────────────

class _SuccessPainter extends CustomPainter {
  final double circleScale;
  final double circlePulse;
  final Color circleColor;
  final double checkTrim;
  final double ring1;
  final double ring2;
  final double ring3;
  final double glowOpacity;
  final double confettiProg;
  final double sparkleProg;
  final List<_Particle> particles;

  const _SuccessPainter({
    required this.circleScale,
    required this.circlePulse,
    required this.circleColor,
    required this.checkTrim,
    required this.ring1,
    required this.ring2,
    required this.ring3,
    required this.glowOpacity,
    required this.confettiProg,
    required this.sparkleProg,
    required this.particles,
  });

  static const _green = Color(0xFF22C55E);
  static const _baseR = 62.0; // logical px radius of the green circle

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    _drawRings(canvas, c);
    _drawGlow(canvas, c);
    _drawCircle(canvas, c);
    _drawCheckmark(canvas, c);
    _drawSparkles(canvas, c);
    _drawConfetti(canvas, c);
  }

  // ── Sonar rings ─────────────────────────────────────────────────────────────
  void _drawRings(Canvas canvas, Offset c) {
    for (final (t, maxR, baseAlpha) in [
      (ring1, 160.0, 0.18),
      (ring2, 145.0, 0.12),
      (ring3, 130.0, 0.07),
    ]) {
      if (t <= 0) continue;
      final opacity = baseAlpha * (1 - t);
      if (opacity <= 0) continue;
      final effectiveR = _baseR * circleScale * circlePulse;
      canvas.drawCircle(
        c,
        effectiveR + (maxR - effectiveR) * t,
        Paint()
          ..color = _green.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  // ── Ambient glow ────────────────────────────────────────────────────────────
  void _drawGlow(Canvas canvas, Offset c) {
    if (glowOpacity <= 0 || circleScale <= 0) return;
    final r = _baseR * circleScale * circlePulse;
    canvas.drawCircle(
      c,
      r + 20,
      Paint()
        ..color = _green.withValues(alpha: glowOpacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
  }

  // ── Main circle ─────────────────────────────────────────────────────────────
  void _drawCircle(Canvas canvas, Offset c) {
    if (circleScale <= 0) return;
    final r = _baseR * circleScale * circlePulse;
    canvas.drawCircle(c, r, Paint()..color = circleColor);
  }

  // ── Checkmark (trim-path) ────────────────────────────────────────────────────
  void _drawCheckmark(Canvas canvas, Offset c) {
    if (checkTrim <= 0 || circleScale < 0.3) return;
    final r = _baseR * math.min(circleScale, 1.0) * circlePulse;

    // Three control points for the checkmark stroke
    final p1 = c + Offset(-r * 0.37, 0.04 * r);
    final p2 = c + Offset(-r * 0.04, r * 0.38);
    final p3 = c + Offset(r * 0.44, -r * 0.28);

    final seg1Len = (p2 - p1).distance;
    final seg2Len = (p3 - p2).distance;
    final total = seg1Len + seg2Len;
    final drawn = total * checkTrim;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = r * 0.17
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (drawn <= seg1Len) {
      final t = (drawn / seg1Len).clamp(0.0, 1.0);
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      final t2 = ((drawn - seg1Len) / seg2Len).clamp(0.0, 1.0);
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t2, p2.dy + (p3.dy - p2.dy) * t2);
    }
    canvas.drawPath(path, paint);
  }

  // ── Gold sparkle stars ───────────────────────────────────────────────────────
  void _drawSparkles(Canvas canvas, Offset c) {
    if (sparkleProg <= 0) return;
    final baseR = _baseR * math.min(circleScale * circlePulse, 1.15);
    final orbitR = baseR + 26 + 10 * sparkleProg;
    final opacity = sparkleProg < 0.5 ? sparkleProg * 2 : (1 - sparkleProg) * 2;

    for (int i = 0; i < 7; i++) {
      final angle = (i / 7) * 2 * math.pi - math.pi / 2;
      final scale = 0.55 + 0.45 * math.sin(sparkleProg * math.pi + i * 0.9);
      final pos =
          c + Offset(math.cos(angle) * orbitR, math.sin(angle) * orbitR);
      final paint = Paint()
        ..color = const Color(
          0xFFFFD600,
        ).withValues(alpha: opacity.clamp(0.0, 1.0));
      _drawStar(canvas, pos, 6 * scale, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    const pts = 4;
    final path = Path();
    for (int i = 0; i < pts * 2; i++) {
      final a = (i * math.pi / pts) - math.pi / 2;
      final dist = i.isEven ? r : r * 0.36;
      final p = center + Offset(math.cos(a) * dist, math.sin(a) * dist);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ── Micro-confetti burst ─────────────────────────────────────────────────────
  void _drawConfetti(Canvas canvas, Offset c) {
    if (confettiProg <= 0) return;

    for (final p in particles) {
      final dist = p.speed * confettiProg;
      final gravity = 28.0 * confettiProg * confettiProg;
      final pos =
          c +
          Offset(math.cos(p.angle) * dist, math.sin(p.angle) * dist + gravity);

      // Opacity envelope: rises 0→0.35, full 0.35→1.0 then fades
      final opacity = confettiProg < 0.35
          ? (confettiProg / 0.35) * p.startOpacity
          : p.startOpacity * (1 - (confettiProg - 0.35) / 0.65);
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rotSpeed * confettiProg * 2);

      switch (p.shape) {
        case 0: // circle dot
          canvas.drawCircle(Offset.zero, p.size * 0.52, paint);
        case 1: // square
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
            paint,
          );
        case 2: // ribbon
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size * 2.4,
                height: p.size * 0.42,
              ),
              const Radius.circular(2),
            ),
            paint,
          );
        default: // triangle
          final path = Path()
            ..moveTo(0, -p.size * 0.7)
            ..lineTo(p.size * 0.65, p.size * 0.45)
            ..lineTo(-p.size * 0.65, p.size * 0.45)
            ..close();
          canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SuccessPainter old) => true;
}

// ──────────────────────────────────────────────────────────────────────────────
// Particle data
// ──────────────────────────────────────────────────────────────────────────────

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final int shape; // 0 circle, 1 square, 2 ribbon, 3 triangle
  final double rotSpeed;
  final double startOpacity;

  _Particle(math.Random rng)
    : angle = rng.nextDouble() * 2 * math.pi,
      speed = 75 + rng.nextDouble() * 105,
      size = 4.5 + rng.nextDouble() * 7.5,
      color = _colors[rng.nextInt(_colors.length)],
      shape = rng.nextInt(4),
      rotSpeed = (rng.nextDouble() - 0.5) * 7,
      startOpacity = 0.65 + rng.nextDouble() * 0.35;

  static const _colors = [
    Color(0xFF22C55E), // success green
    Color(0xFF2979FF), // electric blue
    Color(0xFFFFD600), // gold
    Color(0xFFFF5252), // coral red
    Color(0xFF69F0AE), // lime green
    Color(0xFFE040FB), // violet
    Color(0xFF00BCD4), // cyan
    Color(0xFFFF6D00), // orange
  ];
}

// ──────────────────────────────────────────────────────────────────────────────
// Custom Curves
// ──────────────────────────────────────────────────────────────────────────────

/// easeOutBack — circle overshoots on scale-in for a "pop" feel
class _EaseOutBackCurve extends Curve {
  const _EaseOutBackCurve();
  @override
  double transformInternal(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
  }
}

/// cubic-bezier(0.65, 0, 0.45, 1) — the "ink-dry" checkmark easing
/// Approximated as a Catmull-Rom Bezier evaluated at t.
class _InkDryCurve extends Curve {
  const _InkDryCurve();
  @override
  double transformInternal(double t) {
    // Cubic Bézier with control points (0.65,0) and (0.45,1)
    // Solved numerically via Newton's method
    double ut = t;
    for (int i = 0; i < 8; i++) {
      final slope =
          3 * (1 - ut) * (1 - ut) * 0.65 +
          6 * (1 - ut) * ut * 0.45 +
          3 * ut * ut;
      final val =
          3 * (1 - ut) * (1 - ut) * ut * 0.65 +
          3 * (1 - ut) * ut * ut * 0.45 +
          ut * ut * ut -
          t;
      if (slope.abs() < 1e-10) break;
      ut -= val / slope;
    }
    // Y value for the solved t
    return 3 * (1 - ut) * (1 - ut) * ut * 0 +
        3 * (1 - ut) * ut * ut * 1 +
        ut * ut * ut;
  }
}
