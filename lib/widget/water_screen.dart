import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  StreamSubscription? _sensorSub;

  double tiltX = 0; // left-right tilt
  double tiltY = 0; // up-down tilt
  double waveStrength = 4; // normal wave
  double baseFill = 0.3; // 30% initial fill

  @override
  void initState() {
    super.initState();

    _waveController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _sensorSub = accelerometerEventStream().listen((event) {
      final x = event.x;
      final y = event.y;
      final z = event.z;

      tiltX += ((x / 10).clamp(-0.4, 0.4) - tiltX) * 0.1;
      tiltY += ((y / 10).clamp(-0.4, 0.4) - tiltY) * 0.1;

      final acceleration = sqrt(x * x + y * y + z * z);
      waveStrength = acceleration > 15 ? 18 : 4;

      setState(() {});
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _sensorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return CustomPaint(
            painter: WaterPainter(
              animationValue: _waveController.value,
              tiltX: tiltX,
              tiltY: tiltY,
              waveStrength: waveStrength,
              baseFill: baseFill,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class WaterPainter extends CustomPainter {
  final double animationValue;
  final double tiltX;
  final double tiltY;
  final double waveStrength;
  final double baseFill;

  WaterPainter({
    required this.animationValue,
    required this.tiltX,
    required this.tiltY,
    required this.waveStrength,
    required this.baseFill,
  });

  @override
  void paint(Canvas canvas, Size size) {

    canvas.drawColor(Colors.white, BlendMode.src);

    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFB3E5FC),
          Colors.white
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    final sunCenter = Offset(size.width * 0.8, size.height * 0.2);
    final sunRadius = size.width * 0.1;

    final glowPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(sunCenter, sunRadius * 1.5, glowPaint);

    final sunPaint = Paint()
      ..color = Colors.orangeAccent;

    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    final waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4FC3F7),
          Color(0xFF01579B),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();

    double waterHeight = size.height * (1 - baseFill);
    double verticalOffset = tiltY * 80;

    path.moveTo(0, waterHeight + verticalOffset);

    for (double i = 0; i <= size.width; i++) {

      double wave = sin(
          (i / size.width * 2 * pi) +
              (animationValue * 2 * pi)) *
          waveStrength;

      double horizontalTilt =
          tiltX * (i - size.width / 2);

      path.lineTo(
          i,
          waterHeight +
              wave +
              horizontalTilt +
              verticalOffset);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, waterPaint);

  }

  @override
  bool shouldRepaint(covariant WaterPainter oldDelegate) => true;
}