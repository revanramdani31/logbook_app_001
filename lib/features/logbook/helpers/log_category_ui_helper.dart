import 'package:flutter/material.dart';

class LogCategoryUiHelper {
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Mechanical':
        return Icons.precision_manufacturing;
      case 'Electronic':
        return Icons.electrical_services;
      case 'Software':
        return Icons.computer;
      case 'Integration':
        return Icons.hub;
      case 'Testing':
        return Icons.science;
      case 'Documentation':
        return Icons.description;
      default:
        return Icons.engineering;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Mechanical':
        return Colors.green;
      case 'Electronic':
        return Colors.blue;
      case 'Software':
        return Colors.deepPurple;
      case 'Integration':
        return Colors.orange;
      case 'Testing':
        return Colors.red;
      case 'Documentation':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
