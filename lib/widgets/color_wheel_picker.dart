import 'dart:math';
import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ColorWheelPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const ColorWheelPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  late HSVColor _hsvColor;
  List<Color> _recentColors = [];
  final double _wheelSize = 220.0;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _loadRecentColors();
  }

  void _loadRecentColors() {
    final hexList = PreferencesService.recentColors;
    setState(() {
      _recentColors = hexList.map((hexStr) {
        try {
          if (hexStr.startsWith('#')) {
            final val = int.tryParse(hexStr.substring(1), radix: 16);
            if (val != null) return Color(val);
          }
        } catch (_) {}
        return Colors.cyanAccent;
      }).toList();
    });
  }

  void _saveRecentColor(Color color) async {
    final hexStr = '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
    final hexList = List<String>.from(PreferencesService.recentColors);
    
    // Avoid duplicates - remove if already present, insert at front
    hexList.remove(hexStr);
    hexList.insert(0, hexStr);
    
    // Limit to 6 recent colors
    if (hexList.length > 6) {
      hexList.removeRange(6, hexList.length);
    }
    
    await PreferencesService.setRecentColors(hexList);
  }

  void _updateColorFromOffset(Offset localOffset, double radius) {
    final center = Offset(radius, radius);
    final dx = localOffset.dx - center.dx;
    final dy = localOffset.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);
    
    final saturation = (distance / radius).clamp(0.0, 1.0);
    final angle = atan2(dy, dx);
    final hue = ((angle * 180 / pi) + 360) % 360.0;
    
    setState(() {
      _hsvColor = HSVColor.fromAHSV(1.0, hue, saturation, 1.0);
    });
    widget.onColorChanged(_hsvColor.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _hsvColor.toColor();
    final radius = _wheelSize / 2;

    return Dialog(
      backgroundColor: Colors.grey[950],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: const BorderSide(color: Colors.white10, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CUSTOMIZE COLOR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 24.0),
            
            // Color Wheel Container
            GestureDetector(
              onPanStart: (details) => _updateColorFromOffset(details.localPosition, radius),
              onPanUpdate: (details) => _updateColorFromOffset(details.localPosition, radius),
              onTapDown: (details) => _updateColorFromOffset(details.localPosition, radius),
              child: SizedBox(
                width: _wheelSize,
                height: _wheelSize,
                child: RepaintBoundary(
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(
                          painter: ColorWheelBackgroundPainter(),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ColorWheelThumbPainter(
                            hsvColor: _hsvColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            
            // Current & Recent Colors Row
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT COLOR',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.0,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    // Active color circle
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.5),
                            blurRadius: 10.0,
                            spreadRadius: 1.0,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Container(
                      height: 32.0,
                      width: 1.0,
                      color: Colors.white10,
                    ),
                    const SizedBox(width: 16.0),
                    
                    // Recent colors list
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RECENT COLORS',
                            style: TextStyle(
                              color: Colors.white30,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.0,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          _recentColors.isEmpty
                              ? const Text(
                                  'No recents yet',
                                  style: TextStyle(color: Colors.white24, fontSize: 12.0),
                                )
                              : SizedBox(
                                  height: 30.0,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _recentColors.length,
                                    itemBuilder: (context, index) {
                                      final recentColor = _recentColors[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _hsvColor = HSVColor.fromColor(recentColor);
                                            });
                                            widget.onColorChanged(recentColor);
                                          },
                                          borderRadius: BorderRadius.circular(15.0),
                                          child: Container(
                                            width: 30.0,
                                            height: 30.0,
                                            decoration: BoxDecoration(
                                              color: recentColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white24, width: 1.0),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            
            // Reset to Default Button
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context, Colors.transparent);
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent, size: 18.0),
              label: const Text(
                'Reset to Default',
                style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                backgroundColor: Colors.cyan.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            
            // Dialog Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Revert to initial color
                    widget.onColorChanged(widget.initialColor);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () {
                    _saveRecentColor(activeColor);
                    Navigator.pop(context, activeColor);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  ),
                  child: const Text(
                    'Save Color',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ColorWheelBackgroundPainter extends CustomPainter {
  const ColorWheelBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw Hue circle using SweepGradient
    final paintHue = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFFF0000), // Red
          Color(0xFFFFFF00), // Yellow
          Color(0xFF00FF00), // Green
          Color(0xFF00FFFF), // Cyan
          Color(0xFF0000FF), // Blue
          Color(0xFFFF00FF), // Magenta
          Color(0xFFFF0000), // Red back
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, paintHue);

    // 2. Draw Saturation using RadialGradient
    final paintSat = Paint()
      ..shader = RadialGradient(
        colors: const [
          Colors.white,
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, paintSat);
  }

  @override
  bool shouldRepaint(covariant ColorWheelBackgroundPainter oldDelegate) => false;
}

class ColorWheelThumbPainter extends CustomPainter {
  final HSVColor hsvColor;

  ColorWheelThumbPainter({required this.hsvColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw Indicator Thumb
    final angle = hsvColor.hue * pi / 180.0;
    final r = hsvColor.saturation * radius;
    final thumbOffset = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));

    final selectedColor = hsvColor.toColor();
    
    // Draw shadow first
    canvas.drawCircle(
      thumbOffset,
      10.0,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );

    // Draw white outer ring
    canvas.drawCircle(
      thumbOffset,
      8.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Draw dark border inside white ring to isolate it on light/dark areas
    canvas.drawCircle(
      thumbOffset,
      6.0,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Draw colored center dot
    canvas.drawCircle(
      thumbOffset,
      5.0,
      Paint()
        ..color = selectedColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant ColorWheelThumbPainter oldDelegate) {
    return oldDelegate.hsvColor != hsvColor;
  }
}
