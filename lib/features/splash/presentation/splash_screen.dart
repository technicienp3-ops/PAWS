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
      duration: const Duration(milliseconds: 4600),
    )..forward();

    _timer = Timer(const Duration(milliseconds: 4100), () {
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
              ((_controller.value - 0.88) / 0.12).clamp(0.0, 1.0),
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
            colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9)],
          ),
        ),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final assemble = Curves.easeOutBack.transform(
              (animation.value / 0.58).clamp(0.0, 1.0),
            );
            final logoReveal = Curves.easeInOut.transform(
              ((animation.value - 0.34) / 0.24).clamp(0.0, 1.0),
            );
            final titleReveal = Curves.easeOut.transform(
              ((animation.value - 0.56) / 0.20).clamp(0.0, 1.0),
            );
            final holdPulse = 1 + math.sin(animation.value * math.pi * 8) * 0.018;

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 270,
                    height: 270,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _FlyingPiece(
                          progress: assemble,
                          start: const Offset(-170, -150),
                          end: const Offset(-48, -42),
                          size: 68,
                          color: const Color(0xFF1565C0),
                          radius: 24,
                          angle: -0.8,
                        ),
                        _FlyingPiece(
                          progress: assemble,
                          start: const Offset(165, -130),
                          end: const Offset(52, -38),
                          size: 62,
                          color: const Color(0xFF43A047),
                          radius: 22,
                          angle: 0.7,
                        ),
                        _FlyingPiece(
                          progress: assemble,
                          start: const Offset(-180, 130),
                          end: const Offset(-42, 52),
                          size: 58,
                          color: const Color(0xFF1E88E5),
                          radius: 20,
                          angle: 0.5,
                        ),
                        _FlyingPiece(
                          progress: assemble,
                          start: const Offset(170, 150),
                          end: const Offset(45, 55),
                          size: 56,
                          color: const Color(0xFF66BB6A),
                          radius: 19,
                          angle: -0.6,
                        ),
                        Transform.scale(
                          scale: (0.72 + logoReveal * 0.28) * holdPulse,
                          child: Opacity(
                            opacity: logoReveal,
                            child: Container(
                              width: 206,
                              height: 206,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.94),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: titleReveal,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - titleReveal)),
                      child: const Column(
                        children: [
                          Text(
                            'PAWS',
                            style: TextStyle(
                              color: Color(0xFF12324A),
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Toilet & Aire',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
