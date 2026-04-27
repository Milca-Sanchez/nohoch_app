import 'package:flutter/material.dart';

class IconMapper {
  static IconData getIcon(String name) {
    switch (name) {
      // Papelería
      case 'edit': return Icons.edit;
      case 'content_cut': return Icons.content_cut;
      case 'sticky_note_2': return Icons.sticky_note_2;
      case 'format_paint': return Icons.format_paint;
      
      // Servicios Generales
      case 'cleaning_services': return Icons.cleaning_services;
      case 'water_drop': return Icons.water_drop;
      case 'delete_outline': return Icons.delete_outline;

      // Recreación
      case 'sports_soccer': return Icons.sports_soccer;
      case 'sports_baseball': return Icons.sports_baseball;
      case 'flag': return Icons.flag;

      // Electrónica
      case 'speaker': return Icons.speaker;
      case 'mic': return Icons.mic;
      case 'campaign': return Icons.campaign;
      case 'cable': return Icons.cable;
      case 'electrical_services': return Icons.electrical_services;

      // Categorías generales
      case 'folder': return Icons.folder;
      
      default: return Icons.inventory_2;
    }
  }
}
