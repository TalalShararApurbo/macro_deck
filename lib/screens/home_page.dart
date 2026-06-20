import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/macro_button.dart';
import '../widgets/color_wheel_picker.dart';
import '../models/button_config.dart';
import '../services/preferences_service.dart';
import '../services/network_service.dart';
import 'settings_page.dart';

IconData getIconByName(String name) {
  switch (name) {
    case 'keyboard':
      return Icons.keyboard;
    case 'sensors':
      return Icons.sensors;
    case 'record':
      return Icons.fiber_manual_record;
    case 'movie':
      return Icons.movie_creation;
    case 'mic_off':
      return Icons.mic_off;
    case 'headset_off':
      return Icons.headset_off;
    case 'videocam_off':
      return Icons.videocam_off;
    case 'looks_one':
      return Icons.looks_one;
    case 'looks_two':
      return Icons.looks_two;
    case 'play':
      return Icons.play_arrow;
    case 'pause':
      return Icons.pause;
    case 'stop':
      return Icons.stop;
    case 'volume_up':
      return Icons.volume_up;
    case 'volume_down':
      return Icons.volume_down;
    case 'volume_off':
      return Icons.volume_off;
    case 'lightbulb':
      return Icons.lightbulb;
    case 'gamepad':
      return Icons.gamepad;
    case 'music':
      return Icons.music_note;
    case 'star':
      return Icons.star;
    case 'flash':
      return Icons.flash_on;
    case 'desktop':
      return Icons.desktop_windows;
    case 'web':
      return Icons.web;
    case 'code':
      return Icons.code;
    case 'terminal':
      return Icons.terminal;
    case 'power':
      return Icons.power_settings_new;
    case 'lock':
      return Icons.lock_outline;
    case 'refresh':
      return Icons.refresh;
    case 'folder':
      return Icons.folder_open;
    case 'link':
      return Icons.link;
    case 'brightness':
      return Icons.brightness_6;
    case 'search':
      return Icons.search;
    case 'mic':
      return Icons.mic;
    case 'headset':
      return Icons.headset;
    case 'camera':
      return Icons.videocam;
    case 'timer':
      return Icons.timer_outlined;
    case 'speed':
      return Icons.speed;
    case 'security':
      return Icons.security;
    case 'notifications':
      return Icons.notifications_active;
    case 'discord':
      return Icons.forum;
    case 'settings':
      return Icons.settings;
    case 'add':
      return Icons.add;
    default:
      return Icons.help_outline;
  }
}

String getDefaultCommand(String id) {
  switch (id) {
    case 'builtin_stream':
      return 'STREAM';
    case 'builtin_record':
      return 'RECORD';
    case 'builtin_mic_mute':
      return 'MIC_MUTE';
    case 'builtin_deafen':
      return 'DEAFEN';
    case 'builtin_camera':
      return 'CAMERA';
    case 'builtin_scene_1':
      return 'SCENE_1';
    case 'builtin_scene_2':
      return 'SCENE_2';
    case 'builtin_vol_down':
      return 'VOLUME_DOWN';
    case 'builtin_vol_up':
      return 'VOLUME_UP';
    default:
      return '';
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<MacroButtonConfig> _buttons = [];

  // Drag and drop layout variables
  int? _draggingIndex;
  int? _hoveredIndex;
  Offset _startGlobalPosition = Offset.zero;
  double _startLeft = 0.0;
  double _startTop = 0.0;
  
  String? _editingButtonId;
  bool _capsuleExpanded = false;

  // ValueNotifier for high-performance screen-refresh rate locked dragging
  final ValueNotifier<Offset> _dragPositionNotifier = ValueNotifier(Offset.zero);

  // Scroll controller for grid auto-scrolling
  final ScrollController _scrollController = ScrollController();

  // Ripple effect animation variables
  late AnimationController _rippleController;
  int? _rippleSourceIndex;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initButtonLayout();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rippleController.dispose();
    _dragPositionNotifier.dispose();
    super.dispose();
  }

  void _initButtonLayout() {
    final layoutStrings = PreferencesService.buttonLayout;
    if (layoutStrings.isNotEmpty) {
      setState(() {
        _buttons = layoutStrings.map((str) => MacroButtonConfig.fromJson(jsonDecode(str))).toList();
      });
    } else {
      // Migrate or initialize default layout
      final List<MacroButtonConfig> list = [];
      
      // 1. Built-in buttons
      final builtinIds = [
        'builtin_stream',
        'builtin_record',
        'builtin_mic_mute',
        'builtin_deafen',
        'builtin_camera',
        'builtin_scene_1',
        'builtin_scene_2',
        'builtin_vol_down',
        'builtin_vol_up',
      ];
      for (final id in builtinIds) {
        String? keyCombo;
        if (id == 'builtin_mic_mute') {
          keyCombo = PreferencesService.micMuteBind;
        } else if (id == 'builtin_deafen') {
          keyCombo = PreferencesService.deafenBind;
        } else if (id == 'builtin_camera') {
          keyCombo = PreferencesService.cameraBind;
        }

        list.add(MacroButtonConfig(
          id: id,
          type: 'builtin',
          label: _getBuiltinLabel(id),
          iconName: _getBuiltinIconName(id),
          isToggle: _getBuiltinIsToggle(id),
          keyCombo: keyCombo?.isNotEmpty == true ? keyCombo : null,
        ));
      }

      // 2. Migrate existing custom macros
      final oldCustomStrings = PreferencesService.customMacros;
      for (int i = 0; i < oldCustomStrings.length; i++) {
        try {
          final oldJson = jsonDecode(oldCustomStrings[i]);
          list.add(MacroButtonConfig(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: 'custom',
            label: oldJson['label'] as String? ?? 'New Macro',
            iconName: oldJson['iconName'] as String? ?? 'keyboard',
            isToggle: oldJson['isToggle'] as bool? ?? false,
            keyCombo: oldJson['keyCombo'] as String?,
          ));
        } catch (_) {}
      }

      // 3. Add system buttons
      list.add(MacroButtonConfig(
        id: 'system_settings',
        type: 'system',
        label: 'Settings',
        iconName: 'settings',
        isToggle: false,
      ));
      list.add(MacroButtonConfig(
        id: 'system_add_new',
        type: 'system',
        label: 'ADD NEW',
        iconName: 'add',
        isToggle: false,
      ));

      setState(() {
        _buttons = list;
      });
      _saveButtonLayout();
    }
  }

  Future<void> _saveButtonLayout() async {
    final list = _buttons.map((b) => jsonEncode(b.toJson())).toList();
    await PreferencesService.setButtonLayout(list);
  }

  String _getBuiltinLabel(String id) {
    switch (id) {
      case 'builtin_stream': return 'Stream';
      case 'builtin_record': return 'Record';
      case 'builtin_mic_mute': return 'Mic Mute';
      case 'builtin_deafen': return 'Deafen';
      case 'builtin_camera': return 'Camera';
      case 'builtin_scene_1': return 'Scene 1';
      case 'builtin_scene_2': return 'Scene 2';
      case 'builtin_vol_down': return 'VOL-';
      case 'builtin_vol_up': return 'VOL+';
      default: return '';
    }
  }

  String _getBuiltinIconName(String id) {
    switch (id) {
      case 'builtin_stream': return 'sensors';
      case 'builtin_record': return 'record';
      case 'builtin_mic_mute': return 'mic_off';
      case 'builtin_deafen': return 'headset_off';
      case 'builtin_camera': return 'videocam_off';
      case 'builtin_scene_1': return 'looks_one';
      case 'builtin_scene_2': return 'looks_two';
      case 'builtin_vol_down': return 'volume_down';
      case 'builtin_vol_up': return 'volume_up';
      default: return 'help';
    }
  }

  bool _getBuiltinIsToggle(String id) {
    return id == 'builtin_mic_mute' || id == 'builtin_deafen' || id == 'builtin_camera';
  }

  void _startEditing(String id) {
    setState(() {
      _editingButtonId = id;
      _capsuleExpanded = true;
    });
  }

  void _stopEditing() {
    if (_editingButtonId == null) return;
    setState(() {
      _capsuleExpanded = false;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && !_capsuleExpanded) {
        setState(() {
          _editingButtonId = null;
        });
      }
    });
  }

  void _showDeleteConfirmation(int index, MacroButtonConfig button) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return AlertDialog(
          backgroundColor: Colors.grey[950],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Colors.redAccent, width: 2.0),
          ),
          title: const Text(
            'DELETE MACRO?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${button.label}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteButton(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Macro "${button.label}" deleted.'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        final scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(curvedAnimation);
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  void _deleteButton(int index) {
    setState(() {
      _buttons.removeAt(index);
      _editingButtonId = null;
      _capsuleExpanded = false;
    });
    _saveButtonLayout();
  }

  void _showColorPicker(int index, MacroButtonConfig button) {
    final originalColor = button.customColor;
    showGeneralDialog<Color>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return ColorWheelPicker(
          initialColor: originalColor ?? (button.isToggle ? Colors.redAccent : Colors.lightBlueAccent),
          onColorChanged: (color) {
            setState(() {
              _buttons[index] = _buttons[index].copyWith(customColor: color);
            });
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        final scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(curvedAnimation);
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    ).then((selectedColor) {
      if (selectedColor == Colors.transparent) {
        // Reset to default
        setState(() {
          _buttons[index] = _buttons[index].copyWith(clearColor: true);
        });
        _saveButtonLayout();
        _stopEditing();
      } else if (selectedColor != null) {
        // Save selected color
        setState(() {
          _buttons[index] = _buttons[index].copyWith(customColor: selectedColor);
        });
        _saveButtonLayout();
        _stopEditing();
      } else {
        // Revert live preview if canceled
        setState(() {
          if (originalColor == null) {
            _buttons[index] = _buttons[index].copyWith(clearColor: true);
          } else {
            _buttons[index] = _buttons[index].copyWith(customColor: originalColor);
          }
        });
      }
    });
  }

  void _showBindDialog(int index, MacroButtonConfig button) {
    _showBuiltInRecordDialog(
      button.keyCombo ?? '',
      button.label,
      (val) async {
        setState(() {
          _buttons[index] = _buttons[index].copyWith(keyCombo: val.isNotEmpty ? val : '');
        });
        await _saveButtonLayout();
        _stopEditing();
      },
    );
  }

  void _showBuiltInRecordDialog(String currentBind, String title, Future<void> Function(String) onSave) async {
    final String? result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        final scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(curvedAnimation);
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return RecordBindDialog(
          title: title,
          initialBind: currentBind,
        );
      },
    );

    if (result != null) {
      await onSave(result);
      if (mounted) {
        setState(() {}); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bind for $title updated to: ${result.isEmpty ? "Default Action" : result.toUpperCase()}'),
            backgroundColor: Colors.cyan,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _addNewMacroDialog() async {
    final MacroButtonConfig? newMacro = await showGeneralDialog<MacroButtonConfig>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        
        final scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(curvedAnimation);
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return const AddMacroDialog();
      },
    );
    
    if (newMacro != null) {
      setState(() {
        // Insert before system action buttons (Settings and ADD NEW)
        int insertIndex = _buttons.indexWhere((b) => b.type == 'system');
        if (insertIndex == -1) {
          _buttons.add(newMacro);
        } else {
          _buttons.insert(insertIndex, newMacro);
        }
      });
      await _saveButtonLayout();
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        opaque: false,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInBack,
          );
          
          final scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(curvedAnimation);
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  double getGlowPulseFactor(int index, int crossAxisCount) {
    if (_rippleSourceIndex == null || !_rippleController.isAnimating) return 0.0;
    
    final sourceRow = _rippleSourceIndex! ~/ crossAxisCount;
    final sourceCol = _rippleSourceIndex! % crossAxisCount;
    final targetRow = index ~/ crossAxisCount;
    final targetCol = index % crossAxisCount;
    
    final double distance = sqrt(pow(targetRow - sourceRow, 2) + pow(targetCol - sourceCol, 2));
    
    final double t = _rippleController.value;
    final double maxDistance = 6.0; 
    final double waveCenter = t * maxDistance;
    final double waveWidth = 1.8;
    
    double intensity = 0.0;
    final double distFromWave = (distance - waveCenter).abs();
    if (distFromWave < waveWidth) {
      intensity = 1.0 - (distFromWave / waveWidth);
    }
    
    return intensity * (1.0 - t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'MACRO-DECK',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0,
            fontSize: 22.0,
            color: Colors.cyanAccent,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: RepaintBoundary(
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              if (_editingButtonId != null) {
                _stopEditing();
              }
            },
            child: OrientationBuilder(
              builder: (context, orientation) {
            final isPortrait = orientation == Orientation.portrait;
            final int crossAxisCount = isPortrait ? 3 : 6;
            
            return Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
                    return const SizedBox.shrink();
                  }
                  final double gridWidth = constraints.maxWidth;
                  
                  final padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0);
                  final double crossAxisSpacing = 20.0;
                  final double mainAxisSpacing = 20.0;
                  
                  final double usableWidth = gridWidth - padding.left - padding.right - (crossAxisCount - 1) * crossAxisSpacing;
                  final double buttonWidth = usableWidth / crossAxisCount;
                  final double buttonHeight = buttonWidth; 
                  
                  final int rows = (_buttons.length / crossAxisCount).ceil();
                  final double totalHeight = padding.top + padding.bottom + rows * buttonHeight + (rows - 1).clamp(0, 9999) * mainAxisSpacing;

                  List<Widget> stackChildren = [];

                  for (int i = 0; i < _buttons.length; i++) {
                    final config = _buttons[i];

                    // Calculate the visual slot index using virtual indices during layout
                    int visualIndex = i;
                    if (_draggingIndex != null && _hoveredIndex != null) {
                      if (i == _draggingIndex) {
                        visualIndex = _hoveredIndex!;
                      } else if (_hoveredIndex! > _draggingIndex!) {
                        if (i > _draggingIndex! && i <= _hoveredIndex!) {
                          visualIndex = i - 1;
                        }
                      } else if (_hoveredIndex! < _draggingIndex!) {
                        if (i >= _hoveredIndex! && i < _draggingIndex!) {
                          visualIndex = i + 1;
                        }
                      }
                    }

                    final int col = visualIndex % crossAxisCount;
                    final int row = visualIndex ~/ crossAxisCount;
                    final double left = padding.left + col * (buttonWidth + crossAxisSpacing);
                    final double top = padding.top + row * (buttonHeight + mainAxisSpacing);

                    // Standard button widget with snappy animated position (180ms)
                    stackChildren.add(
                      AnimatedPositioned(
                        key: ValueKey(config.id),
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        left: left,
                        top: top,
                        width: buttonWidth,
                        height: buttonHeight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPressStart: (details) {
                            _dragPositionNotifier.value = Offset(left, top);
                            setState(() {
                              _startGlobalPosition = details.globalPosition;
                              _startLeft = left;
                              _startTop = top;
                            });
                            _startEditing(config.id);
                            HapticFeedback.mediumImpact();
                          },
                          onLongPressMoveUpdate: (details) {
                            final delta = details.globalPosition - _startGlobalPosition;

                            // Threshold check to transition from static hold to dragging
                            if (_draggingIndex == null) {
                              if (delta.dx.abs() > 8.0 || delta.dy.abs() > 8.0) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _draggingIndex = i;
                                  _hoveredIndex = i;
                                });
                              }
                              return;
                            }

                            final currentLeft = _startLeft + delta.dx;
                            final currentTop = _startTop + delta.dy;
                            
                            // High performance GPU-translated update
                            _dragPositionNotifier.value = Offset(currentLeft, currentTop);

                            // Auto-scroll logic if user drags close to screen edges
                            final screenHeight = MediaQuery.of(context).size.height;
                            final touchY = details.globalPosition.dy;
                            if (touchY > screenHeight - 120) {
                              if (_scrollController.hasClients && _scrollController.offset < _scrollController.position.maxScrollExtent) {
                                _scrollController.jumpTo((_scrollController.offset + 8.0).clamp(0.0, _scrollController.position.maxScrollExtent));
                              }
                            } else if (touchY < 120) {
                              if (_scrollController.hasClients && _scrollController.offset > 0.0) {
                                _scrollController.jumpTo((_scrollController.offset - 8.0).clamp(0.0, _scrollController.position.maxScrollExtent));
                              }
                            }

                            // Hover calculations
                            final centerX = currentLeft + buttonWidth / 2;
                            final centerY = currentTop + buttonHeight / 2;

                            final hoverCol = ((centerX - padding.left) / (buttonWidth + crossAxisSpacing)).round();
                            final hoverRow = ((centerY - padding.top) / (buttonHeight + mainAxisSpacing)).round();

                            final int targetCol = hoverCol.clamp(0, crossAxisCount - 1);
                            final int targetRow = hoverRow.clamp(0, (rows - 1).clamp(0, 9999));

                            int hoveredIndex = targetRow * crossAxisCount + targetCol;
                            hoveredIndex = hoveredIndex.clamp(0, _buttons.length - 1);

                            if (_draggingIndex != null && hoveredIndex != _hoveredIndex) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _hoveredIndex = hoveredIndex;
                              });
                            }
                          },
                          onLongPressEnd: (details) {
                            if (_draggingIndex != null && _hoveredIndex != null) {
                              final int finalIndex = _hoveredIndex!;
                              final draggedItem = _buttons.removeAt(_draggingIndex!);
                              _buttons.insert(finalIndex, draggedItem);
                              HapticFeedback.heavyImpact();
                              setState(() {
                                _draggingIndex = null;
                                _hoveredIndex = null;
                                _rippleSourceIndex = finalIndex;
                              });
                              _rippleController.forward(from: 0.0);
                              _saveButtonLayout();
                            }
                          },
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _rippleController,
                              builder: (context, child) {
                                final double ripplePulse = getGlowPulseFactor(i, crossAxisCount);
                                return MacroButton(
                                  label: config.label,
                                  icon: getIconByName(config.iconName),
                                  isToggle: config.isToggle,
                                  customColor: config.customColor,
                                  glowPulseFactor: ripplePulse,
                                  isPlaceholder: _draggingIndex == i,
                                  onPressed: () {
                                    if (_editingButtonId != null) {
                                      _stopEditing();
                                      return;
                                    }
                                    if (config.type == 'system') {
                                      if (config.id == 'system_settings') {
                                        _navigateToSettings();
                                      } else if (config.id == 'system_add_new') {
                                        _addNewMacroDialog();
                                      }
                                    } else if (config.type == 'custom') {
                                      if (config.keyCombo != null && config.keyCombo!.isNotEmpty) {
                                        NetworkService.sendCommand('RUN_MACRO:${config.keyCombo}');
                                      } else {
                                        NetworkService.sendCommand('CUSTOM:${config.label}');
                                      }
                                    } else {
                                      // Built-in
                                      if (config.keyCombo != null && config.keyCombo!.isNotEmpty) {
                                        NetworkService.sendCommand('RUN_MACRO:${config.keyCombo}');
                                      } else {
                                        NetworkService.sendCommand(getDefaultCommand(config.id));
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Render edit action capsule floating drawer
                  if (_editingButtonId != null && _draggingIndex == null) {
                    final editIdx = _buttons.indexWhere((b) => b.id == _editingButtonId);
                    if (editIdx != -1) {
                      final config = _buttons[editIdx];
                      final int col = editIdx % crossAxisCount;
                      final int row = editIdx ~/ crossAxisCount;
                      final double left = padding.left + col * (buttonWidth + crossAxisSpacing);
                      final double top = padding.top + row * (buttonHeight + mainAxisSpacing);
                      
                      final bool isLastColumn = (col == crossAxisCount - 1);
                      final double capsuleWidth = 46.0;
                      final double gap = 8.0;

                      final double leftPos = isLastColumn ? (left - capsuleWidth - gap) : (left + buttonWidth + gap);

                      stackChildren.add(
                        AnimatedPositioned(
                          key: const ValueKey('edit_action_capsule'),
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          left: leftPos,
                          top: top,
                          width: capsuleWidth,
                          height: buttonHeight,
                          child: RepaintBoundary(
                            child: EditActionCapsule(
                              expanded: _capsuleExpanded,
                              isLastColumn: isLastColumn,
                              child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(23.0),
                                border: Border.all(color: Colors.white12, width: 1.0),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 10.0,
                                    spreadRadius: 1.0,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Edit Button (Pencil Icon)
                                  if (config.id == 'builtin_mic_mute' ||
                                      config.id == 'builtin_deafen' ||
                                      config.id == 'builtin_camera' ||
                                      config.type == 'custom')
                                    GestureDetector(
                                      onTap: () => _showBindDialog(editIdx, config),
                                      behavior: HitTestBehavior.opaque,
                                      child: const SizedBox(
                                        width: 38.0,
                                        height: 28.0,
                                        child: Icon(Icons.edit_rounded, color: Colors.amberAccent, size: 18.0),
                                      ),
                                    ),
                                  // Color Picker Button
                                  GestureDetector(
                                    onTap: () => _showColorPicker(editIdx, config),
                                    behavior: HitTestBehavior.opaque,
                                    child: const SizedBox(
                                      width: 38.0,
                                      height: 28.0,
                                      child: Icon(Icons.color_lens_rounded, color: Colors.cyanAccent, size: 18.0),
                                    ),
                                  ),
                                  // Delete Button
                                  if (config.type == 'custom')
                                    GestureDetector(
                                      onTap: () => _showDeleteConfirmation(editIdx, config),
                                      behavior: HitTestBehavior.opaque,
                                      child: const SizedBox(
                                        width: 38.0,
                                        height: 28.0,
                                        child: Icon(Icons.delete_rounded, color: Colors.redAccent, size: 18.0),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                    }
                  }

                  // Render the dragged item on top of everything using high-performance GPU translation
                  if (_draggingIndex != null) {
                    final config = _buttons[_draggingIndex!];
                    stackChildren.add(
                      Positioned(
                        key: ValueKey('dragged_${config.id}'),
                        left: 0,
                        top: 0,
                        width: buttonWidth,
                        height: buttonHeight,
                        child: ValueListenableBuilder<Offset>(
                          valueListenable: _dragPositionNotifier,
                          builder: (context, dragOffset, child) {
                            return Transform.translate(
                              offset: dragOffset,
                              child: child,
                            );
                          },
                          child: Transform.scale(
                            scale: 1.06,
                            child: Opacity(
                              opacity: 0.85,
                              child: IgnorePointer(
                                child: RepaintBoundary(
                                  child: MacroButton(
                                    label: config.label,
                                    icon: getIconByName(config.iconName),
                                    isToggle: config.isToggle,
                                    customColor: config.customColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    width: gridWidth,
                    height: constraints.maxHeight,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: gridWidth,
                        height: totalHeight,
                        child: Stack(
                          children: stackChildren,
                        ),
                      ),
                    ),
                  );
                }
              ),
            );
          }
        ),
      ),
    ),
  ),
);
  }
}

class AddMacroDialog extends StatefulWidget {
  const AddMacroDialog({super.key});

  @override
  State<AddMacroDialog> createState() => _AddMacroDialogState();
}

class _AddMacroDialogState extends State<AddMacroDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isToggle = false;
  String _selectedIconName = 'keyboard';
  String? _recordedCombo;
  bool _isRecording = false;

  final List<Map<String, dynamic>> _availableIconsList = [
    {'name': 'keyboard', 'icon': Icons.keyboard},
    {'name': 'sensors', 'icon': Icons.sensors},
    {'name': 'record', 'icon': Icons.fiber_manual_record},
    {'name': 'movie', 'icon': Icons.movie_creation},
    {'name': 'mic_off', 'icon': Icons.mic_off},
    {'name': 'headset_off', 'icon': Icons.headset_off},
    {'name': 'videocam_off', 'icon': Icons.videocam_off},
    {'name': 'looks_one', 'icon': Icons.looks_one},
    {'name': 'looks_two', 'icon': Icons.looks_two},
    {'name': 'play', 'icon': Icons.play_arrow},
    {'name': 'pause', 'icon': Icons.pause},
    {'name': 'stop', 'icon': Icons.stop},
    {'name': 'volume_up', 'icon': Icons.volume_up},
    {'name': 'volume_off', 'icon': Icons.volume_off},
    {'name': 'lightbulb', 'icon': Icons.lightbulb},
    {'name': 'gamepad', 'icon': Icons.gamepad},
    {'name': 'music', 'icon': Icons.music_note},
    {'name': 'star', 'icon': Icons.star},
    {'name': 'flash', 'icon': Icons.flash_on},
    {'name': 'desktop', 'icon': Icons.desktop_windows},
    {'name': 'web', 'icon': Icons.web},
    {'name': 'code', 'icon': Icons.code},
    {'name': 'terminal', 'icon': Icons.terminal},
    {'name': 'power', 'icon': Icons.power_settings_new},
    {'name': 'lock', 'icon': Icons.lock_outline},
    {'name': 'refresh', 'icon': Icons.refresh},
    {'name': 'folder', 'icon': Icons.folder_open},
    {'name': 'link', 'icon': Icons.link},
    {'name': 'brightness', 'icon': Icons.brightness_6},
    {'name': 'search', 'icon': Icons.search},
    {'name': 'mic', 'icon': Icons.mic},
    {'name': 'headset', 'icon': Icons.headset},
    {'name': 'camera', 'icon': Icons.videocam},
    {'name': 'timer', 'icon': Icons.timer_outlined},
    {'name': 'speed', 'icon': Icons.speed},
    {'name': 'security', 'icon': Icons.security},
    {'name': 'notifications', 'icon': Icons.notifications_active},
    {'name': 'discord', 'icon': Icons.forum},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    NetworkService.stopRecording();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _isRecording = true;
    });
    NetworkService.startRecording((combo) {
      if (mounted) {
        setState(() {
          _recordedCombo = combo;
          _isRecording = false;
        });
      }
    });
  }

  void _cancelListening() {
    NetworkService.stopRecording();
    setState(() {
      _isRecording = false;
    });
  }

  List<String> get _recordedKeysList {
    if (_recordedCombo == null || _recordedCombo!.isEmpty) return [];
    return _recordedCombo!.split('+');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[950],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: const BorderSide(color: Colors.cyan, width: 2.0),
      ),
      title: const Text(
        'ADD MACRO',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Macro Name',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyan),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toggle Button',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _isToggle,
                  onChanged: (value) {
                    setState(() {
                      _isToggle = value;
                    });
                  },
                  activeThumbColor: Colors.cyan,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Keyboard Bind',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            if (_isRecording) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.cyan,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    const Expanded(
                      child: Text(
                        'Recording... Press keys on PC',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelListening,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
            ] else if (_recordedCombo != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.white10),
                ),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (var key in _recordedKeysList)
                      Chip(
                        label: Text(
                          key.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.cyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                        backgroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        deleteIcon: const Icon(
                          Icons.cancel,
                          size: 16.0,
                          color: Colors.redAccent,
                        ),
                        onDeleted: () {
                          setState(() {
                            _recordedCombo = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 18),
                label: const Text('Record a Macro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[900],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: const BorderSide(color: Colors.white12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16.0),
            const Text(
              'Select Icon',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            SizedBox(
              height: 160.0,
              width: double.maxFinite,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                ),
                itemCount: _availableIconsList.length,
                itemBuilder: (context, index) {
                  final item = _availableIconsList[index];
                  final isSelected = item['name'] == _selectedIconName;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIconName = item['name'] as String;
                      });
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.cyan.withValues(alpha: 0.2) : Colors.grey[900],
                        border: Border.all(
                          color: isSelected ? Colors.cyan : Colors.transparent,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isSelected ? Colors.cyan : Colors.white70,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a macro name.'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            Navigator.pop(
              context,
              MacroButtonConfig(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                type: 'custom',
                label: name,
                iconName: _selectedIconName,
                isToggle: _isToggle,
                keyCombo: _recordedCombo,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.black,
          ),
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class RecordBindDialog extends StatefulWidget {
  final String title;
  final String? initialBind;

  const RecordBindDialog({
    super.key,
    required this.title,
    this.initialBind,
  });

  @override
  State<RecordBindDialog> createState() => _RecordBindDialogState();
}

class _RecordBindDialogState extends State<RecordBindDialog> {
  String? _recordedCombo;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _recordedCombo = widget.initialBind;
  }

  @override
  void dispose() {
    NetworkService.stopRecording();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _isRecording = true;
    });
    NetworkService.startRecording((combo) {
      if (mounted) {
        setState(() {
          _recordedCombo = combo;
          _isRecording = false;
        });
      }
    });
  }

  void _cancelListening() {
    NetworkService.stopRecording();
    setState(() {
      _isRecording = false;
    });
  }

  List<String> get _recordedKeysList {
    if (_recordedCombo == null || _recordedCombo!.isEmpty) return [];
    return _recordedCombo!.split('+');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[950],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: const BorderSide(color: Colors.cyan, width: 2.0),
      ),
      title: Text(
        'BIND ${widget.title.toUpperCase()}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Press the button to record a key shortcut on your PC.',
            style: TextStyle(color: Colors.white70, fontSize: 13.0),
          ),
          const SizedBox(height: 16.0),
          if (_isRecording) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.cyan,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Text(
                      'Recording... Press keys on PC',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.0,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _cancelListening,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ] else if (_recordedCombo != null && _recordedCombo!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.white10),
              ),
              child: Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var key in _recordedKeysList)
                    Chip(
                      label: Text(
                        key.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      deleteIcon: const Icon(
                        Icons.cancel,
                        size: 16.0,
                        color: Colors.redAccent,
                      ),
                      onDeleted: () {
                        setState(() {
                          _recordedCombo = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _startListening,
              icon: const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 18),
              label: const Text('Record Bind'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[900],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: const BorderSide(color: Colors.white12),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _recordedCombo ?? '');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.black,
          ),
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class EditActionCapsule extends StatefulWidget {
  final Widget child;
  final bool expanded;
  final bool isLastColumn;

  const EditActionCapsule({
    super.key,
    required this.child,
    required this.expanded,
    required this.isLastColumn,
  });

  @override
  State<EditActionCapsule> createState() => _EditActionCapsuleState();
}

class _EditActionCapsuleState extends State<EditActionCapsule> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curveAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    _curveAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    // Slide from offset to zero
    // Since child is 46.0 wide, and maxOffset is 54.0.
    // Slide transition offset is fractional: (46.0 + 8.0) / 46.0 = 1.1739
    final double fractionalOffset = (46.0 + 8.0) / 46.0;
    _slideAnimation = Tween<Offset>(
      begin: Offset((widget.isLastColumn ? 1.0 : -1.0) * fractionalOffset, 0.0),
      end: Offset.zero,
    ).animate(_curveAnimation);

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_curveAnimation);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    if (widget.expanded) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(EditActionCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) {
      if (widget.expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: widget.isLastColumn ? Alignment.centerRight : Alignment.centerLeft,
        child: SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}
