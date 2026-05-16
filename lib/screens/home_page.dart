import 'package:flutter/material.dart';
import '../widgets/macro_button.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                
                return SizedBox(
                  width: gridWidth,
                  child: GridView.count(
                    crossAxisCount: isPortrait ? 3 : 6,
                    mainAxisSpacing: 20.0,
                    crossAxisSpacing: 20.0,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    shrinkWrap: true,
                    childAspectRatio: 1.0,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const MacroButton(label: 'Stream', icon: Icons.sensors),
                      const MacroButton(label: 'Record', icon: Icons.fiber_manual_record),
                      const MacroButton(label: 'Clips', icon: Icons.movie_creation),
                      const MacroButton(label: 'Mic Mute', icon: Icons.mic_off, isToggle: true),
                      const MacroButton(label: 'Deafen', icon: Icons.headset_off, isToggle: true),
                      const MacroButton(label: 'Camera', icon: Icons.videocam_off, isToggle: true),
                      const MacroButton(label: 'Scene 1', icon: Icons.looks_one),
                      const MacroButton(label: 'Scene 2', icon: Icons.looks_two),
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
                      MacroButton(
                        label: 'ADD NEW',
                        icon: Icons.add,
                        onPressed: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            barrierColor: Colors.black.withValues(alpha: 0.5),
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
                              return AlertDialog(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
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
                                  child: TextField(
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
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Button configuration captured. Integration in progress...'),
                                          backgroundColor: Colors.cyan,
                                          behavior: SnackBarBehavior.floating,
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
                            },
                          );
                        },
                      ),
                    ],
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
