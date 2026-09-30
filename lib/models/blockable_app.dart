import 'package:flutter/material.dart';

/// UI-only model for apps that can be blocked during focus.
class BlockableApp {
  const BlockableApp({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconColor,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color iconColor;
}
