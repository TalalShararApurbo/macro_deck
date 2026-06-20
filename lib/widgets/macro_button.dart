import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MacroButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isToggle;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Color? customColor;
  final double? glowPulseFactor;
  final bool isPlaceholder;

  const MacroButton({
    super.key,
    required this.label,
    required this.icon,
    this.isToggle = false,
    this.onPressed,
    this.onLongPress,
    this.customColor,
    this.glowPulseFactor,
    this.isPlaceholder = false,
  });

  @override
  State<MacroButton> createState() => _MacroButtonState();
}

class _MacroButtonState extends State<MacroButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isToggled = false;
  Timer? _glowLingerTimer;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  bool _isAnimatingForward = false;
  bool _isWaitingToReverse = false;

  bool get _isActive => widget.isToggle ? (_isToggled || _isPressed) : _isPressed;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(
        parent: _scaleController, 
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
      ),
    );

    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.vibrate();
      } else if (status == AnimationStatus.dismissed) {
        HapticFeedback.vibrate();
      }
    });
  }

  @override
  void dispose() {
    _glowLingerTimer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPlaceholder) {
      return Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: const [],
            ),
          ),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: const BorderSide(color: Colors.cyanAccent, width: 2.0),
              ),
              child: const Center(
                child: Icon(Icons.crop_free_rounded, color: Colors.cyanAccent, size: 24),
              ),
            ),
          ),
        ],
      );
    }

    final Color activeColor = widget.customColor ?? ((widget.isToggle && _isToggled) ? Colors.redAccent : Colors.lightBlueAccent);
    final bool isGlowing = _isActive || (widget.glowPulseFactor != null && widget.glowPulseFactor! > 0);
    
    final double currentGlowAlpha = (widget.glowPulseFactor != null && widget.glowPulseFactor! > 0)
        ? 0.8 * widget.glowPulseFactor!
        : 0.8;
    final double currentGlowBlur = (widget.glowPulseFactor != null && widget.glowPulseFactor! > 0)
        ? 16.0 * widget.glowPulseFactor!
        : 16.0;
    final double currentGlowSpread = (widget.glowPulseFactor != null && widget.glowPulseFactor! > 0)
        ? 3.0 * widget.glowPulseFactor!
        : 3.0;

    // Card background is static: unaffected by whether button is active/glowing or not!
    final Color cardBgColor = widget.customColor != null
        ? Color.lerp(const Color(0xFF151515), widget.customColor, 0.08)!
        : Colors.grey[900]!;

    final Color iconColor = widget.customColor != null
        ? (_isActive ? widget.customColor! : widget.customColor!.withValues(alpha: 0.65))
        : (_isActive ? activeColor : Colors.white70);

    final Color textColor = widget.customColor != null
        ? Color.lerp(Colors.white, widget.customColor, _isActive ? 0.7 : 0.4)!
        : Colors.white;

    final bool isRippleActive = widget.glowPulseFactor != null && widget.glowPulseFactor! > 0;
    final Duration containerDuration = isRippleActive
        ? Duration.zero
        : (_isActive ? const Duration(milliseconds: 50) : const Duration(milliseconds: 300));

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: containerDuration,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: isGlowing
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: currentGlowAlpha),
                      blurRadius: currentGlowBlur,
                      spreadRadius: currentGlowSpread,
                    ),
                  ]
                : [],
          ),
        ),
        ScaleTransition(
          scale: _scaleAnimation,
          child: Card(
            color: cardBgColor,
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
                widget.onPressed?.call();
              },
              onLongPress: widget.onLongPress,
              onHighlightChanged: (isHighlighted) {
                _glowLingerTimer?.cancel();
                if (isHighlighted) {
                  _isAnimatingForward = true;
                  _isWaitingToReverse = false;
                  _scaleController.forward().whenComplete(() {
                    _isAnimatingForward = false;
                    if (_isWaitingToReverse) {
                      _isWaitingToReverse = false;
                      _scaleController.reverse();
                    }
                  });

                  setState(() {
                    _isPressed = true;
                  });
                } else {
                  if (_isAnimatingForward) {
                    _isWaitingToReverse = true;
                  } else {
                    _scaleController.reverse();
                  }

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double buttonHeight = constraints.maxHeight;
                  
                  // Compute constraints-relative sizing
                  final double iconSize = buttonHeight * 0.32;
                  final double fontSize = buttonHeight * 0.11;
                  final double spacing = buttonHeight * 0.08;
                  
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: buttonHeight * 0.08,
                      vertical: buttonHeight * 0.06,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.icon,
                          size: iconSize.clamp(16.0, 48.0),
                          color: iconColor,
                        ),
                        SizedBox(height: spacing.clamp(4.0, 16.0)),
                        Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize.clamp(8.0, 15.0),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
