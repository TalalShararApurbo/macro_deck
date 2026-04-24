import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _hapticsEnabled = true;
  bool _animationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 18.0,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          SwitchListTile(
            title: const Text('Enable Haptic Feedback', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Simulate physical button presses', style: TextStyle(color: Colors.white54)),
            activeTrackColor: Colors.lightBlueAccent.withValues(alpha: 0.5),
            activeThumbColor: Colors.lightBlueAccent,
            value: _hapticsEnabled,
            onChanged: (bool value) {
              setState(() {
                _hapticsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Enable Button Animations', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Show scale and glow effects', style: TextStyle(color: Colors.white54)),
            activeTrackColor: Colors.lightBlueAccent.withValues(alpha: 0.5),
            activeThumbColor: Colors.lightBlueAccent,
            value: _animationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _animationsEnabled = value;
              });
            },
          ),
          const SizedBox(height: 32.0),
          const Center(
            child: Text(
              'Macro-Deck v0.3',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
