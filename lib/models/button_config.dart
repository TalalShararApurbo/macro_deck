import 'package:flutter/material.dart';

class MacroButtonConfig {
  final String id;
  final String type; // 'builtin', 'custom', 'system'
  final String label;
  final String iconName;
  final bool isToggle;
  final String? keyCombo;
  final Color? customColor;

  MacroButtonConfig({
    required this.id,
    required this.type,
    required this.label,
    required this.iconName,
    required this.isToggle,
    this.keyCombo,
    this.customColor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'iconName': iconName,
        'isToggle': isToggle,
        'keyCombo': keyCombo,
        'customColor': customColor != null ? '#${customColor!.toARGB32().toRadixString(16).padLeft(8, '0')}' : null,
      };

  factory MacroButtonConfig.fromJson(Map<String, dynamic> json) {
    Color? parsedColor;
    if (json['customColor'] != null) {
      final colorStr = json['customColor'] as String;
      if (colorStr.startsWith('#')) {
        final val = int.tryParse(colorStr.substring(1), radix: 16);
        if (val != null) {
          parsedColor = Color(val);
        }
      }
    }
    return MacroButtonConfig(
      id: json['id'] as String,
      type: json['type'] as String,
      label: json['label'] as String,
      iconName: json['iconName'] as String,
      isToggle: json['isToggle'] as bool? ?? false,
      keyCombo: json['keyCombo'] as String?,
      customColor: parsedColor,
    );
  }

  MacroButtonConfig copyWith({
    String? label,
    String? iconName,
    bool? isToggle,
    String? keyCombo,
    Color? customColor,
    bool clearColor = false,
  }) {
    return MacroButtonConfig(
      id: id,
      type: type,
      label: label ?? this.label,
      iconName: iconName ?? this.iconName,
      isToggle: isToggle ?? this.isToggle,
      keyCombo: keyCombo ?? this.keyCombo,
      customColor: clearColor ? null : (customColor ?? this.customColor),
    );
  }
}
