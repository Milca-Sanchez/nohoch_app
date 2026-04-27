import 'package:flutter/material.dart';
import '../utils/icon_mapper.dart';

class InventoryCategory {
  final String id;
  final String name;
  final String iconName;
  final Color color;
  final int lowStockThreshold;

  InventoryCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    required this.lowStockThreshold,
  });

  IconData get icon => IconMapper.getIcon(iconName);
}
