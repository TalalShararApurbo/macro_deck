import 'package:flutter/material.dart';
import '../widgets/macro_button.dart';

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
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 18.0,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: 800,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 20.0,
            crossAxisSpacing: 20.0,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            shrinkWrap: true,
            childAspectRatio: 1.0,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              MacroButton(label: 'Stream', icon: Icons.sensors),
              MacroButton(label: 'Record', icon: Icons.fiber_manual_record),
              MacroButton(label: 'Clips', icon: Icons.movie_creation),
              MacroButton(label: 'Mic Mute', icon: Icons.mic_off),
              MacroButton(label: 'Deafen', icon: Icons.headset_off),
              MacroButton(label: 'Camera', icon: Icons.videocam_off),
              MacroButton(label: 'Scene 1', icon: Icons.looks_one),
              MacroButton(label: 'Scene 2', icon: Icons.looks_two),
              MacroButton(label: 'Settings', icon: Icons.settings),
            ],
          ),
        ),
      ),
    );
  }
}
