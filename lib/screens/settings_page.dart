import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ipController.text = PreferencesService.pcIpAddress;
    _portController.text = PreferencesService.pcPort;
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _saveNetworkConfig() async {
    await PreferencesService.setPcIpAddress(_ipController.text);
    await PreferencesService.setPcPort(_portController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network configuration saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

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
            'Network Configuration',
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _ipController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'PC IP Address',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.lightBlueAccent),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _portController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'PC Port',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.lightBlueAccent),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _saveNetworkConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32.0),
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
