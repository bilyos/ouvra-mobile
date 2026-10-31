import 'package:flutter/material.dart';

/// Catégorie de service (plomberie, coiffure, ménage…).
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}
