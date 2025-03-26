import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: true,
      home: Scaffold(
        body: SafeArea(child: BenchMarkScreen()),
      ),
    );
  }
}

class BenchMarkScreen extends StatefulWidget {
  const BenchMarkScreen({super.key});

  @override
  State<BenchMarkScreen> createState() => _BenchMarkScreenState();
}

class _BenchMarkScreenState extends State<BenchMarkScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<Bunny> bunnies = [];
  Size _bounds = Size(100, 100);
  bool _isInitialized = false;

  Future<void> _initWithContext(BuildContext context) async {
    _bounds = MediaQuery.of(context).size;
    final bunnyImage = await loadImage("bunny_atlas.png");
    _initBunnies(bunnyImage);
    _ticker = createTicker((_) {
      setState(_updateBunnies);
    });
    _ticker.start();

    setState(() {});
  }

  void _initBunnies(ui.Image bunnyImage) {
    const int bunnyCount = 1500;
    bunnies.clear();
    final random = Random(33);
    for (int i = 0; i < bunnyCount; i++) {
      final x = random.nextDouble() * _bounds.width;
      final y = random.nextDouble() * _bounds.height;
      final color = Color(random.nextInt(0xFFFFFFFF));
      final velocity = Offset(
        random.nextBool() ? 1 : -1,
        random.nextBool() ? 1 : -1,
      );
      bunnies.add(
        Bunny(
          image: bunnyImage,
          x: x,
          y: y,
          velocity: velocity,
          atlasIndex: random.nextInt(4),
          color: color,
        ),
      );
    }
  }

  void _updateBunnies() {
    for (var bunny in bunnies) {
      bunny.x += bunny.velocity.dx;
      bunny.y += bunny.velocity.dy;

      if (bunny.x > _bounds.width) {
        bunny.velocity = Offset(-1, bunny.velocity.dy);
      }
      if (bunny.y > _bounds.height) {
        bunny.velocity = Offset(bunny.velocity.dx, -1);
      }
      if (bunny.x < 0) {
        bunny.velocity = Offset(1, bunny.velocity.dy);
      }
      if (bunny.y < 0) {
        bunny.velocity = Offset(bunny.velocity.dx, 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        _isInitialized = true;
        _initWithContext(context);
      });
      return Container();
    }

    return SizedBox.expand(
      child: CustomPaint(painter: BunnyPainter(bunnies: bunnies)),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class Bunny {
  final ui.Image image;
  double x;
  double y;
  Offset velocity;
  final int atlasIndex;
  final Color color;

  Bunny({
    required this.image,
    required this.x,
    required this.y,
    required this.velocity,
    required this.atlasIndex,
    required this.color,
  });
}

class BunnyPainter extends CustomPainter {
  final List<Bunny> bunnies;

  final List<Rect> atlasRects = [
    Rect.fromLTWH(0, 0, 64, 64),
    Rect.fromLTWH(64, 0, 64, 64),
    Rect.fromLTWH(0, 64, 64, 64),
    Rect.fromLTWH(64, 64, 64, 64),
  ];

  final Paint _paint = Paint();
  final Rect _rect = Rect.fromLTWH(0, 0, 16, 16);

  BunnyPainter({required this.bunnies});

  @override
  void paint(Canvas canvas, Size size) {
    for (var bunny in bunnies) {
      _paint.colorFilter = ColorFilter.mode(bunny.color, BlendMode.modulate);

      canvas.save();
      canvas.translate(bunny.x, bunny.y);
      canvas.drawImageRect(
        bunny.image,
        atlasRects[bunny.atlasIndex],
        _rect,
        _paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Future<ui.Image> loadImage(String imageName) async {
  final data = await rootBundle.load('assets/$imageName');
  return decodeImageFromList(data.buffer.asUint8List());
}
