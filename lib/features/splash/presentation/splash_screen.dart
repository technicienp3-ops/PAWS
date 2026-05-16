import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.nextScreen});

  final Widget nextScreen;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showNextScreen = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7600),
    )..forward();

    _timer = Timer(const Duration(milliseconds: 7000), () {
      if (mounted) setState(() => _showNextScreen = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showNextScreen) widget.nextScreen,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final fadeOut = Curves.easeInOut.transform(
              ((_controller.value - 0.93) / 0.07).clamp(0.0, 1.0),
            );
            return IgnorePointer(
              ignoring: fadeOut > 0.5,
              child: Opacity(opacity: 1 - fadeOut, child: child),
            );
          },
          child: _SplashContent(animation: _controller),
        ),
      ],
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F9FC),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FAFB), Color(0xFFEAF2F4)],
          ),
        ),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final assemble = Curves.easeOutBack.transform(
              (animation.value / 0.30).clamp(0.0, 1.0),
            );
            final logoReveal = Curves.easeInOut.transform(
              ((animation.value - 0.18) / 0.14).clamp(0.0, 1.0),
            );
            final finalBadgeReveal = Curves.easeInOutCubic.transform(
              ((animation.value - 0.46) / 0.16).clamp(0.0, 1.0),
            );
            final titleReveal = Curves.easeOut.transform(
              ((animation.value - 0.56) / 0.10).clamp(0.0, 1.0),
            );
            final holdPulse =
                1 + math.sin(animation.value * math.pi * 5) * 0.010;

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 336,
                    height: 336,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _FlyingPiece(
                          progress: assemble,
                          start: const Offset(-210, -170),
                          end: const Offset(-58, -48),
                          size: 72,
                          color: const Color(0xFF1565C0),
                          radius: 24,
                          angle: -0.8,
                        ),
                        _FlyingPiece(
                          progress: assemble,
                          start: const Offset(205, -155),
                          end: const Offset(58, -45),
                          size: 66,
                          color: const Color(0xFF43A047),
                          radius: 22,
                          angle: 0.7,
                        ),
                        _FlyingPiece(
                          progress: assemble,
                          start: const Offset(-210, 150),
                          end: const Offset(-48, 58),
                          size: 62,
                          color: const Color(0xFF1E88E5),
                          radius: 20,
                          angle: 0.5,
                        ),
                        _FlyingPiece(
                          progress: assemble,
                          start: const Offset(205, 175),
                          end: const Offset(52, 62),
                          size: 60,
                          color: const Color(0xFF66BB6A),
                          radius: 19,
                          angle: -0.6,
                        ),
                        Transform.scale(
                          scale: (0.70 + logoReveal * 0.30) * holdPulse,
                          child: Opacity(
                            opacity: logoReveal * (1 - finalBadgeReveal),
                            child: Container(
                              width: 214,
                              height: 214,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(48),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x2212324A),
                                    blurRadius: 30,
                                    offset: Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: SvgPicture.asset(
                                'assets/images/paws_logo.svg',
                              ),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: (0.78 + finalBadgeReveal * 0.22) * holdPulse,
                          child: Opacity(
                            opacity: finalBadgeReveal,
                            child: SvgPicture.asset(
                              'assets/images/paws_final_badge.svg',
                              width: 316,
                              height: 316,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: titleReveal,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - titleReveal)),
                      child: const Text(
                        'Toilet & Aire',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FlyingPiece extends StatelessWidget {
  const _FlyingPiece({
    required this.progress,
    required this.start,
    required this.end,
    required this.size,
    required this.color,
    required this.radius,
    required this.angle,
  });

  final double progress;
  final Offset start;
  final Offset end;
  final double size;
  final Color color;
  final double radius;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final current = Offset.lerp(start, end, progress)!;
    final rotation = angle * (1 - progress);
    return Transform.translate(
      offset: current,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: (0.2 + progress * 0.8).clamp(0.0, 1.0),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.78),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2012324A),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
