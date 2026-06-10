import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/app_logo_widget.dart';
import '../controllers/splash_controller.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';


class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {

  // Master sequencer
  late AnimationController _seq;

  // Shimmer ring — runs once
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim1;
  late Animation<double> _shimmerAnim2;

  // Pulse ring — loops forever
  late AnimationController _pulseCtrl;

  // Staggered content animations
  late Animation<double> _logoAnim, _badgeAnim, _nameAnim,
      _barAnim, _tagAnim, _dotsAnim, _bottomAnim;

  @override
  void initState() {
    super.initState();

    // Remove native splash once Flutter splash is ready
    FlutterNativeSplash.remove();

    Get.put(SplashController());

    // ── Sequencer (1600ms total) ──────────────────────────────────
    _seq = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _logoAnim   = _interval(0.00, 0.35, curve: Curves.elasticOut);
    _badgeAnim  = _interval(0.22, 0.48, curve: Curves.elasticOut);
    _nameAnim   = _interval(0.30, 0.58);
    _barAnim    = _interval(0.40, 0.65);
    _tagAnim    = _interval(0.50, 0.74);
    _dotsAnim   = _interval(0.62, 0.88);
    _bottomAnim = _interval(0.72, 0.95);

    // ── Shimmer ring (runs once, 2.8s) ───────────────────────────
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    _shimmerAnim1 = CurvedAnimation(
      parent: _shimmerCtrl,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );

    _shimmerAnim2 = CurvedAnimation(
      parent: _shimmerCtrl,
      curve: const Interval(0.08, 1.0, curve: Curves.easeOut),
    );

    // ── Pulse ring (loops) ────────────────────────────────────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  Animation<double> _interval(double start, double end,
      {Curve curve = Curves.easeOut}) =>
      CurvedAnimation(
        parent: _seq,
        curve: Interval(start, end, curve: curve),
      );

  @override
  void dispose() {
    _seq.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppThemeData.primary5,
      body: Stack(
        children: [

          // ── Ambient blobs ─────────────────────────────────────────
          _Blob(
            color: AppThemeData.primary4,
            size: size.width * 0.58,
            opacity: 0.38,
            top: -40,
            right: -50,
          ),
          _Blob(
            color: AppThemeData.primary6,
            size: size.width * 0.52,
            opacity: 0.65,
            bottom: 40,
            left: -50,
          ),

          // ── Shimmer + pulse rings ────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_shimmerCtrl, _pulseCtrl]),
              builder: (_, __) {
                return CustomPaint(
                  size: Size(size.width, size.width),
                  painter: _RingPainter(
                    shimmer1: _shimmerAnim1.value,
                    shimmer2: _shimmerAnim2.value,
                    pulse: _pulseCtrl.value,
                  ),
                );
              },
            ),
          ),

          // ── Content ───────────────────────────────────────────────
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // ── Logo card (slimmed: 88x88, logo 48) ──────
                      ScaleTransition(
                        scale: _logoAnim,
                        child: FadeTransition(
                          opacity: _logoAnim,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                // Slimmed down from 104 → 88
                                // so the frosted border sits
                                // clearly inside the shimmer rings
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Center(
                                  child: AppLogoWidget(height: 48),
                                ),
                              ),

                              // Amber star badge
                              Positioned(
                                top: -9,
                                right: -9,
                                child: ScaleTransition(
                                  scale: _badgeAnim,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppThemeData.secondary4,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppThemeData.primary5,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── App name ──────────────────────────────────
                      _FadeSlide(
                        animation: _nameAnim,
                        child: Text(
                          "Tireda",
                          style: TextStyle(
                            fontSize: 32,
                            color: AppThemeData.primaryWhite,
                            fontFamily: FontFamily.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 9),

                      // ── Amber underline bar ───────────────────────
                      FadeTransition(
                        opacity: _barAnim,
                        child: ScaleTransition(
                          scale: _barAnim,
                          child: Container(
                            width: 38,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppThemeData.secondary4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 11),

                      // ── Tagline (bolded) ──────────────────────────
                      _FadeSlide(
                        animation: _tagAnim,
                        child: Text(
                          "BUY.  SELL.  CONNECT.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontFamily: FontFamily.bold,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 52),

                      // ── Bouncing dots loader ──────────────────────
                      FadeTransition(
                        opacity: _dotsAnim,
                        child: const _BouncingDots(),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom domain strip ───────────────────────────────
              FadeTransition(
                opacity: _bottomAnim,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "tireda.ng",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.55),
                          fontFamily: FontFamily.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shimmer + pulse ring painter ─────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double shimmer1, shimmer2, pulse;

  _RingPainter({
    required this.shimmer1,
    required this.shimmer2,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Pulse ring — breathing loop
    // Radius kept well outside the 88px logo card (half = 44px)
    // inner ring at ~58px radius, outer at ~64px gives clear gap
    final pulseRadius = 58.0 + (pulse * 6.0);
    final pulseOpacity = 0.12 + (pulse * 0.10);
    canvas.drawCircle(
      Offset(cx, cy),
      pulseRadius,
      Paint()
        ..color = const Color(0xff5DCAA5).withValues(alpha: pulseOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    // Shimmer ring 1 — tight, bright teal
    // radius 62 — sits just outside the 44px logo half-width with room
    if (shimmer1 > 0 && shimmer1 < 1) {
      final opacity = shimmer1 < 0.06
          ? shimmer1 / 0.06
          : shimmer1 > 0.78
          ? (1.0 - shimmer1) / 0.22
          : 1.0;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: 62),
        -pi / 2,
        2 * pi * shimmer1,
        false,
        Paint()
          ..color = const Color(0xff9FE1CB).withValues(alpha: opacity.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Shimmer ring 2 — wider, subtler
    if (shimmer2 > 0 && shimmer2 < 1) {
      final opacity = shimmer2 < 0.08
          ? shimmer2 / 0.08
          : shimmer2 > 0.82
          ? (1.0 - shimmer2) / 0.18
          : 0.45;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: 80),
        -pi / 2,
        2 * pi * shimmer2,
        false,
        Paint()
          ..color = const Color(0xff5DCAA5).withValues(alpha: opacity.clamp(0.0, 0.5))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.shimmer1 != shimmer1 ||
          old.shimmer2 != shimmer2 ||
          old.pulse != pulse;
}

// ── Reusable fade + slide transition ─────────────────────────────────────────

class _FadeSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _FadeSlide({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.28),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

// ── Ambient background blob ───────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final Color color;
  final double size, opacity;
  final double? top, bottom, left, right;

  const _Blob({
    required this.color,
    required this.size,
    required this.opacity,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

// ── Bouncing dot loader ───────────────────────────────────────────────────────

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _dots;

  // Teal / Amber / Teal — alternating brand colors
  static const _colors = [
    AppThemeData.primary3,   // #5DCAA5 teal
    AppThemeData.secondary4, // #EF9F27 amber
    AppThemeData.primary3,   // #5DCAA5 teal
  ];

  @override
  void initState() {
    super.initState();
    _dots = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 550),
      );
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _dots) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
            (i) => AnimatedBuilder(
          animation: _dots[i],
          builder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Transform.translate(
              offset: Offset(0, -7 * _dots[i].value),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _colors[i],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}