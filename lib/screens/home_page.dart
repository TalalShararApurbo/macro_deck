import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/macro_button.dart';
import '../services/preferences_service.dart';
import 'settings_page.dart';

class CustomMacro {
  final String label;
  final String iconName;
  final bool isToggle;

  CustomMacro({
    required this.label,
    required this.iconName,
    required this.isToggle,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'iconName': iconName,
        'isToggle': isToggle,
      };

  factory CustomMacro.fromJson(Map<String, dynamic> json) {
    return CustomMacro(
      label: json['label'] as String? ?? 'New Macro',
      iconName: json['iconName'] as String? ?? 'keyboard',
      isToggle: json['isToggle'] as bool? ?? false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'MACRO-DECK',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0,
            fontSize: 22.0,
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
                gridItems.add(const MacroButton(label: 'Stream', icon: Icons.sensors));
                gridItems.add(const MacroButton(label: 'Record', icon: Icons.fiber_manual_record));
                gridItems.add(const MacroButton(label: 'Clips', icon: Icons.movie_creation));
                gridItems.add(const MacroButton(label: 'Mic Mute', icon: Icons.mic_off, isToggle: true));
                gridItems.add(const MacroButton(label: 'Deafen', icon: Icons.headset_off, isToggle: true));
                gridItems.add(const MacroButton(label: 'Camera', icon: Icons.videocam_off, isToggle: true));
                gridItems.add(const MacroButton(label: 'Scene 1', icon: Icons.looks_one));
                gridItems.add(const MacroButton(label: 'Scene 2', icon: Icons.looks_two));
                
                // 2. Custom buttons
                for (int i = 0; i < _customMacros.length; i++) {
                  final macro = _customMacros[i];
                  gridItems.add(
                    MacroButton(
                      label: macro.label,
                      icon: getIconByName(macro.iconName),
                      isToggle: macro.isToggle,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Triggered: ${macro.label}'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.cyan,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
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
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
            const SizedBox(height: 20.0),
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
            Navigator.pop(context, CustomMacro(
              label: name,
              iconName: _selectedIconName,
              isToggle: _isToggle,
            ));
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
