import 'dart:async';
import 'package:flutter/material.dart';

class MacroButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isToggle;

  const MacroButton({
    super.key,
    required this.label,
    required this.icon,
    this.isToggle = false,
  });

  @override
  State<MacroButton> createState() => _MacroButtonState();
}

class _MacroButtonState extends State<MacroButton> {
  bool _isPressed = false;
  bool _isToggled = false;
  Timer? _glowLingerTimer;

  bool get _isActive => widget.isToggle ? (_isToggled || _isPressed) : _isPressed;

  @override
  void dispose() {
    _glowLingerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _isActive ? const Duration(milliseconds: 50) : const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: _isActive
            ? [
                BoxShadow(
                  color: Colors.lightBlueAccent.withOpacity(0.8),
                  blurRadius: 16.0,
                  spreadRadius: 3.0,
                ),
              ]
            : [],
      ),
      child: Card(
        color: Colors.grey[900],
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: InkWell(
          onTap: () {
            if (widget.isToggle) {
              setState(() {
                _isToggled = !_isToggled;
              });
            }
          },
          onHighlightChanged: (isHighlighted) {
            _glowLingerTimer?.cancel();
            if (isHighlighted) {
              setState(() {
                _isPressed = true;
              });
            } else {
              _glowLingerTimer = Timer(const Duration(milliseconds: 400), () {
                if (mounted) {
                  setState(() {
                    _isPressed = false;
                  });
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 36.0,
                  color: _isActive ? Colors.lightBlueAccent : Colors.white70,
                ),
                const SizedBox(height: 12.0),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
