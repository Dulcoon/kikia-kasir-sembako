import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main orchestrator
  late AnimationController _masterController;

  // Icon animations
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _iconRotation;
  late Animation<double> _iconOpacity;

  // Glow pulse behind icon
  late AnimationController _glowController;
  late Animation<double> _glowScale;
  late Animation<double> _glowOpacity;

  // Text animations
  late AnimationController _textController;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;

  // Subtitle / tagline
  late AnimationController _subtitleController;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _subtitleSlide;

  // Background gradient shift
  late AnimationController _bgController;
  late Animation<double> _bgShift;

  // Sparkle particles
  late AnimationController _particleController;

  // Exit
  late AnimationController _exitController;
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // ── Background gradient animation ──
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _bgShift = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    // ── Glow pulse ──
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowScale = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // ── Icon entrance ──
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _iconRotation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // ── Text animation ──
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // ── Subtitle animation ──
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOutCubic),
    );

    // ── Particle sparkles ──
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _generateParticles();

    // ── Exit animation ──
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    // ── Master sequencer ──
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _startSequence();
  }

  void _generateParticles() {
    final random = Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 4 + 2,
        speed: random.nextDouble() * 0.5 + 0.3,
        opacity: random.nextDouble() * 0.5 + 0.2,
        delay: random.nextDouble(),
      ));
    }
  }

  Future<void> _startSequence() async {
    // Wait a brief moment
    await Future.delayed(const Duration(milliseconds: 300));

    // Icon bounces in
    _iconController.forward();

    await Future.delayed(const Duration(milliseconds: 600));

    // Text slides up
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 400));

    // Subtitle fades in
    _subtitleController.forward();

    // Wait for the splash to be visible long enough
    await Future.delayed(const Duration(milliseconds: 1800));

    // Exit animation
    _exitController.forward();

    await Future.delayed(const Duration(milliseconds: 500));

    // Navigate
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    _iconController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _subtitleController.dispose();
    _bgController.dispose();
    _particleController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgShift,
          _iconScale,
          _iconRotation,
          _iconOpacity,
          _glowScale,
          _glowOpacity,
          _textSlide,
          _textOpacity,
          _subtitleOpacity,
          _subtitleSlide,
          _particleController,
          _exitScale,
          _exitOpacity,
        ]),
        builder: (context, child) {
          return AnimatedBuilder(
            animation: _exitController,
            builder: (context, child) {
              return Opacity(
                opacity: _exitOpacity.value,
                child: Transform.scale(
                  scale: _exitScale.value,
                  child: _buildContent(context),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Animated gradient background ──
        AnimatedBuilder(
          animation: _bgShift,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    -1.0 + _bgShift.value * 0.5,
                    -1.0 + _bgShift.value * 0.3,
                  ),
                  end: Alignment(
                    1.0 - _bgShift.value * 0.3,
                    1.0 - _bgShift.value * 0.5,
                  ),
                  colors: const [
                    Color(0xFF1E3A8A), // deep blue
                    Color(0xFF2563EB), // primary blue
                    Color(0xFF3B82F6), // bright blue
                    Color(0xFF1D4ED8), // rich blue
                  ],
                  stops: [
                    0.0,
                    0.3 + _bgShift.value * 0.1,
                    0.6 + _bgShift.value * 0.1,
                    1.0,
                  ],
                ),
              ),
            );
          },
        ),

        // ── Subtle radial glow overlay ──
        Center(
          child: AnimatedBuilder(
            animation: _glowScale,
            builder: (context, _) {
              return Container(
                width: size.width * 0.8 * _glowScale.value,
                height: size.width * 0.8 * _glowScale.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: _glowOpacity.value * 0.3),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ── Sparkle particles ──
        ...List.generate(_particles.length, (i) {
          return AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              final p = _particles[i];
              final progress =
                  ((_particleController.value + p.delay) % 1.0);
              final y = p.y - progress * p.speed;
              final opacity =
                  p.opacity * (1.0 - (progress * 2 - 1).abs());

              if (y < -0.1 || opacity <= 0) return const SizedBox.shrink();

              return Positioned(
                left: p.x * size.width,
                top: y * size.height,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: p.size * 2,
                          spreadRadius: p.size * 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),

        // ── Main content: Icon + Text ──
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon with glow ──
              AnimatedBuilder(
                animation: _iconController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _iconOpacity.value,
                    child: Transform.scale(
                      scale: _iconScale.value,
                      child: Transform.rotate(
                        angle: _iconRotation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.storefront_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // ── App name text ──
              AnimatedBuilder(
                animation: _textController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: [
                              Colors.white,
                              Color(0xFFBFDBFE), // light blue-100
                            ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          'KikiaStore',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              // ── Tagline / subtitle ──
              AnimatedBuilder(
                animation: _subtitleController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _subtitleOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _subtitleSlide.value),
                      child: Text(
                        'Solusi Kasir Digital UMKM',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // ── Bottom loading indicator ──
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _subtitleController,
            builder: (context, _) {
              return Opacity(
                opacity: _subtitleOpacity.value * 0.6,
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mempersiapkan aplikasi...',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double delay;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.delay,
  });
}
