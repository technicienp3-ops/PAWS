import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.nextScreen});

  final Widget nextScreen;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _showNextScreenTimer;
  bool _showNextScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _showNextScreenTimer = Timer(
      const Duration(milliseconds: 2550),
      () {
        if (mounted) {
          setState(() => _showNextScreen = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _showNextScreenTimer?.cancel();
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
            final fadeOut = _interval(0.88, 1);
            return IgnorePointer(
              ignoring: fadeOut > 0.65,
              child: Opacity(
                opacity: 1 - fadeOut,
                child: child,
              ),
            );
          },
          child: _SplashAnimation(controller: _controller),
        ),
      ],
    );
  }

  double _interval(double begin, double end) {
    final value = ((_controller.value - begin) / (end - begin)).clamp(0, 1);
    return Curves.easeInOut.transform(value.toDouble());
  }
}

class _SplashAnimation extends StatelessWidget {
  const _SplashAnimation({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        child: Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final scaleAnimation = Tween<double>(begin: 0.88, end: 1.16)
                  .animate(
                    CurvedAnimation(
                      parent: controller,
                      curve: const Interval(
                        0.70,
                        0.88,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                  );
              final vibration = _interval(0.60, 0.76) *
                  (1 - _interval(0.76, 0.86)) *
                  math.sin(controller.value * 84) *
                  3.5;
              final textOpacity = _interval(0.76, 0.92);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: Offset(vibration, 0),
                    child: ScaleTransition(
                      scale: scaleAnimation,
                      child: SizedBox.square(
                        dimension: 230,
                        child: CustomPaint(
                          painter: _PawSplashPainter(
                            progress: controller.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: textOpacity,
                    child: Text(
                      'PAWS',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: const Color(0xFF12324A),
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double _interval(double begin, double end) {
    final value = ((controller.value - begin) / (end - begin)).clamp(0, 1);
    return Curves.easeInOutCubic.transform(value.toDouble());
  }
}

class _PawSplashPainter extends CustomPainter {
  const _PawSplashPainter({required this.progress});

  final double progress;

  static const _blue = Color(0xFF1E88E5);
  static const _deepBlue = Color(0xFF1565C0);
  static const _green = Color(0xFF43A047);
  static const _lightGreen = Color(0xFF66BB6A);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final floatProgress = _interval(0, 0.46);
    final fusionProgress = _interval(0.38, 0.64);
    final shineProgress = _interval(0.64, 0.86);

    final toes = [
      _FloatingShape(
        start: Offset(size.width * 0.12, size.height * 0.16),
        end: center + const Offset(-56, -42),
        color: _blue,
        radius: 23,
      ),
      _FloatingShape(
        start: Offset(size.width * 0.76, size.height * 0.10),
        end: center + const Offset(-18, -64),
        color: _green,
        radius: 25,
      ),
      _FloatingShape(
        start: Offset(size.width * 0.88, size.height * 0.76),
        end: center + const Offset(22, -64),
        color: _blue,
        radius: 25,
      ),
      _FloatingShape(
        start: Offset(size.width * 0.14, size.height * 0.84),
        end: center + const Offset(58, -42),
        color: _green,
        radius: 23,
      ),
    ];

    for (final toe in toes) {
      _drawFloatingToe(canvas, toe, floatProgress);
    }

    final padPaint = Paint()
      ..color = _deepBlue.withOpacity(fusionProgress)
      ..style = PaintingStyle.fill;
    final padScale = 0.72 + (0.28 * fusionProgress);
    canvas.save();
    canvas.translate(center.dx, center.dy + 30);
    canvas.scale(padScale, padScale);
    _drawPad(canvas, Offset.zero, padPaint);
    canvas.restore();

    final innerPaint = Paint()
      ..color = _lightGreen.withOpacity(fusionProgress * 0.92)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(center.dx, center.dy + 36);
    canvas.scale(padScale * 0.72, padScale * 0.72);
    _drawPad(canvas, Offset.zero, innerPaint);
    canvas.restore();

    if (shineProgress > 0) {
      final shinePaint = Paint()
        ..color = Colors.white.withOpacity((1 - shineProgress) * 0.42)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center + Offset(-74 + shineProgress * 34, -86),
        center + Offset(-44 + shineProgress * 34, -116),
        shinePaint,
      );
      canvas.drawLine(
        center + Offset(54 + shineProgress * 24, -94),
        center + Offset(80 + shineProgress * 24, -120),
        shinePaint,
      );
    }
  }

  void _drawFloatingToe(
    Canvas canvas,
    _FloatingShape shape,
    double progress,
  ) {
    final eased = Curves.easeInOutBack.transform(progress);
    final current = Offset.lerp(shape.start, shape.end, eased)!;
    final rotation = (1 - progress) * math.pi / 4;
    final paint = Paint()..color = shape.color;

    canvas.save();
    canvas.translate(current.dx, current.dy);
    canvas.rotate(rotation);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: shape.radius * 2.05,
          height: shape.radius * 1.78,
        ),
        Radius.circular(shape.radius),
      ),
      paint,
    );
    canvas.restore();
  }

  void _drawPad(Canvas canvas, Offset center, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - 52)
      ..cubicTo(
        center.dx - 58,
        center.dy - 50,
        center.dx - 86,
        center.dy + 6,
        center.dx - 62,
        center.dy + 46,
      )
      ..cubicTo(
        center.dx - 44,
        center.dy + 76,
        center.dx - 12,
        center.dy + 50,
        center.dx,
        center.dy + 54,
      )
      ..cubicTo(
        center.dx + 12,
        center.dy + 50,
        center.dx + 44,
        center.dy + 76,
        center.dx + 62,
        center.dy + 46,
      )
      ..cubicTo(
        center.dx + 86,
        center.dy + 6,
        center.dx + 58,
        center.dy - 50,
        center.dx,
        center.dy - 52,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  double _interval(double begin, double end) {
    final value = ((progress - begin) / (end - begin)).clamp(0, 1);
    return Curves.easeInOutCubic.transform(value.toDouble());
  }

  @override
  bool shouldRepaint(covariant _PawSplashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _FloatingShape {
  const _FloatingShape({
    required this.start,
    required this.end,
    required this.color,
    required this.radius,
  });

  final Offset start;
  final Offset end;
  final Color color;
  final double radius;
}
