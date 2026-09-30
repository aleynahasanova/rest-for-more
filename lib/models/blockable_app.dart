import 'package:flutter/material.dart';

class BlockableApp {
  final String id;
  final String name;
  final String packageName;
  final IconData icon;
  final Color iconColor;

  const BlockableApp({
    required this.id,
    required this.name,
    required this.packageName,
    required this.icon,
    required this.iconColor,
  });
}