import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/macro_button.dart';
import '../services/preferences_service.dart';
import '../services/network_service.dart';
import 'settings_page.dart';

class CustomMacro {
  final String label;
  final String iconName;
  final bool isToggle;
  final String? keyCombo;

  CustomMacro({
    required this.label,
    required this.iconName,
    required this.isToggle,
    this.keyCombo,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'iconName': iconName,
        'isToggle': isToggle,
        'keyCombo': keyCombo,
      };

  factory CustomMacro.fromJson(Map<String, dynamic> json) {
    return CustomMacro(
      label: json['label'] as String? ?? 'New Macro',
      iconName: json['iconName'] as String? ?? 'keyboard',
      isToggle: json['isToggle'] as bool? ?? false,
      keyCombo: json['keyCombo'] as String?,
    );
  }
}

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
    default:
      return Icons.help_outline;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CustomMacro> _customMacros = [];

  @override
  void initState() {
    super.initState();
    _loadCustomMacros();
  }

  void _loadCustomMacros() {
    final list = PreferencesService.customMacros;
    setState(() {
      _customMacros = list.map((item) {
        try {
          return CustomMacro.fromJson(jsonDecode(item));
        } catch (e) {
          return CustomMacro(label: 'Error', iconName: 'help', isToggle: false);
        }
      }).toList();
    });
  }

  Future<void> _addCustomMacro(CustomMacro macro) async {
    _customMacros.add(macro);
    final list = _customMacros.map((m) => jsonEncode(m.toJson())).toList();
    await PreferencesService.setCustomMacros(list);
    setState(() {});
  }

  Future<void> _deleteCustomMacro(int index) async {
    _customMacros.removeAt(index);
    final list = _customMacros.map((m) => jsonEncode(m.toJson())).toList();
    await PreferencesService.setCustomMacros(list);
    setState(() {});
  }

  void _showDeleteConfirmation(int index, CustomMacro macro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          'Are you sure you want to delete "${macro.label}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCustomMacro(index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Macro "${macro.label}" deleted.'),
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
      ),
    );
  }

  void _showBuiltInRecordDialog(String currentBind, String title, Future<void> Function(String) onSave) async {
    final String? result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.fastOutSlowIn,
        );
        final scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation);
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);

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
        setState(() {}); // Trigger rebuild to reflect any state variables
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
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          return Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double gridWidth = constraints.maxWidth > 800 ? 800 : constraints.maxWidth;
                
                final List<Widget> gridItems = [];
                
                // 1. Built-in buttons
                gridItems.add(MacroButton(
                  label: 'Stream', 
                  icon: Icons.sensors,
                  onPressed: () => NetworkService.sendCommand('STREAM'),
                ));
                gridItems.add(MacroButton(
                  label: 'Record', 
                  icon: Icons.fiber_manual_record,
                  onPressed: () => NetworkService.sendCommand('RECORD'),
                ));
                gridItems.add(MacroButton(
                  label: 'Mic Mute', 
                  icon: Icons.mic_off, 
                  isToggle: true,
                  onPressed: () {
                    final bind = PreferencesService.micMuteBind;
                    if (bind.isNotEmpty) {
                      NetworkService.sendCommand('RUN_MACRO:$bind');
                    } else {
                      NetworkService.sendCommand('MIC_MUTE');
                    }
                  },
                  onLongPress: () {
                    _showBuiltInRecordDialog(
                      PreferencesService.micMuteBind,
                      'Mic Mute',
                      (val) async => await PreferencesService.setMicMuteBind(val),
                    );
                  },
                ));
                gridItems.add(MacroButton(
                  label: 'Deafen', 
                  icon: Icons.headset_off, 
                  isToggle: true,
                  onPressed: () {
                    final bind = PreferencesService.deafenBind;
                    if (bind.isNotEmpty) {
                      NetworkService.sendCommand('RUN_MACRO:$bind');
                    } else {
                      NetworkService.sendCommand('DEAFEN');
                    }
                  },
                  onLongPress: () {
                    _showBuiltInRecordDialog(
                      PreferencesService.deafenBind,
                      'Deafen',
                      (val) async => await PreferencesService.setDeafenBind(val),
                    );
                  },
                ));
                gridItems.add(MacroButton(
                  label: 'Camera', 
                  icon: Icons.videocam_off, 
                  isToggle: true,
                  onPressed: () {
                    final bind = PreferencesService.cameraBind;
                    if (bind.isNotEmpty) {
                      NetworkService.sendCommand('RUN_MACRO:$bind');
                    } else {
                      NetworkService.sendCommand('CAMERA');
                    }
                  },
                  onLongPress: () {
                    _showBuiltInRecordDialog(
                      PreferencesService.cameraBind,
                      'Camera',
                      (val) async => await PreferencesService.setCameraBind(val),
                    );
                  },
                ));
                gridItems.add(MacroButton(
                  label: 'Scene 1', 
                  icon: Icons.looks_one,
                  onPressed: () => NetworkService.sendCommand('SCENE_1'),
                ));
                gridItems.add(MacroButton(
                  label: 'Scene 2', 
                  icon: Icons.looks_two,
                  onPressed: () => NetworkService.sendCommand('SCENE_2'),
                ));
                gridItems.add(MacroButton(
                  label: 'VOL-', 
                  icon: Icons.volume_down,
                  onPressed: () => NetworkService.sendCommand('VOLUME_DOWN'),
                ));
                gridItems.add(MacroButton(
                  label: 'VOL+', 
                  icon: Icons.volume_up,
                  onPressed: () => NetworkService.sendCommand('VOLUME_UP'),
                ));
                
                // 2. Custom buttons
                for (int i = 0; i < _customMacros.length; i++) {
                  final macro = _customMacros[i];
                  gridItems.add(
                    MacroButton(
                      label: macro.label,
                      icon: getIconByName(macro.iconName),
                      isToggle: macro.isToggle,
                      onPressed: () {
                        if (macro.keyCombo != null && macro.keyCombo!.isNotEmpty) {
                          NetworkService.sendCommand('RUN_MACRO:${macro.keyCombo}');
                        } else {
                          NetworkService.sendCommand('CUSTOM:${macro.label}');
                        }
                      },
                      onLongPress: () {
                        _showDeleteConfirmation(i, macro);
                      },
                    ),
                  );
                }
                
                // 3. System actions (Settings and ADD NEW)
                gridItems.add(
                  MacroButton(
                    label: 'Settings', 
                    icon: Icons.settings,
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
                          transitionDuration: const Duration(milliseconds: 350),
                          reverseTransitionDuration: const Duration(milliseconds: 350),
                          opaque: false,
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            final curvedAnimation = CurvedAnimation(
                              parent: animation,
                              curve: Curves.fastOutSlowIn,
                            );
                            
                            final scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation);
                            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);

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
                    },
                  ),
                );
                
                gridItems.add(
                  MacroButton(
                    label: 'ADD NEW',
                    icon: Icons.add,
                    onPressed: () async {
                      final CustomMacro? newMacro = await showGeneralDialog<CustomMacro>(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'Dismiss',
                        barrierColor: Colors.black.withValues(alpha: 0.6),
                        transitionDuration: const Duration(milliseconds: 350),
                        transitionBuilder: (context, animation, secondaryAnimation, child) {
                          final curvedAnimation = CurvedAnimation(
                            parent: animation,
                            curve: Curves.fastOutSlowIn,
                          );
                          
                          final scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation);
                          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);

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
                        await _addCustomMacro(newMacro);
                      }
                    },
                  ),
                );

                return SizedBox(
                  width: gridWidth,
                  height: constraints.maxHeight,
                  child: SafeArea(
                    child: GridView.count(
                      crossAxisCount: isPortrait ? 3 : 6,
                      mainAxisSpacing: 20.0,
                      crossAxisSpacing: 20.0,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      shrinkWrap: false,
                      physics: const BouncingScrollPhysics(),
                      children: gridItems,
                    ),
                  ),
                );
              }
            ),
          );
        }
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
              CustomMacro(
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
