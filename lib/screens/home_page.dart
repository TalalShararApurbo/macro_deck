import 'package:flutter/material.dart';
import '../widgets/macro_button.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                            MaterialPageRoute(builder: (context) => const SettingsPage()),
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
