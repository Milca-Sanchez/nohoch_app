import 'package:flutter/material.dart';
import '../utils/icon_mapper.dart';

class InventoryItem {
  final String id;
  final String name;
  final String categoryId;
  final int quantity;
  final String status; // 'Bueno', 'Regular', 'Malo'
  final String description;
  final String iconName;
  final DateTime registrationDate;
  final DateTime lastUpdateDate;

  InventoryItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.quantity,
    required this.status,
    required this.description,
    required this.iconName,
    required this.registrationDate,
    required this.lastUpdateDate,
  });

  IconData get icon => IconMapper.getIcon(iconName);

  InventoryItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    int? quantity,
    String? status,
    String? description,
    String? iconName,
    DateTime? registrationDate,
    DateTime? lastUpdateDate,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      registrationDate: registrationDate ?? this.registrationDate,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
    );
  }
}
