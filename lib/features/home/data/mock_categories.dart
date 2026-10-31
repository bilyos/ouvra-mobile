import 'package:flutter/material.dart';

import '../domain/service_category.dart';

/// Catégories de services proposées (données mockées, remplacées par l'API).
const List<ServiceCategory> kMockCategories = [
  ServiceCategory(id: 'plomberie', label: 'Plomberie', icon: Icons.plumbing_rounded),
  ServiceCategory(id: 'coiffure', label: 'Coiffure', icon: Icons.content_cut_rounded),
  ServiceCategory(id: 'menage', label: 'Ménage', icon: Icons.cleaning_services_rounded),
  ServiceCategory(id: 'electricite', label: 'Électricité', icon: Icons.electrical_services_rounded),
  ServiceCategory(id: 'reparation', label: 'Réparation', icon: Icons.build_rounded),
  ServiceCategory(id: 'menuiserie', label: 'Menuiserie', icon: Icons.carpenter_rounded),
  ServiceCategory(id: 'peinture', label: 'Peinture', icon: Icons.format_paint_rounded),
  ServiceCategory(id: 'cuisine', label: 'Cuisine', icon: Icons.restaurant_rounded),
  ServiceCategory(id: 'informatique', label: 'Informatique', icon: Icons.computer_rounded),
  ServiceCategory(id: 'couture', label: 'Couture', icon: Icons.checkroom_rounded),
  ServiceCategory(id: 'jardinage', label: 'Jardinage', icon: Icons.grass_rounded),
  ServiceCategory(id: 'demenagement', label: 'Déménagement', icon: Icons.local_shipping_rounded),
  ServiceCategory(id: 'garde_enfants', label: 'Garde d\'enfants', icon: Icons.child_care_rounded),
  ServiceCategory(id: 'cours', label: 'Cours particuliers', icon: Icons.school_rounded),
  ServiceCategory(id: 'esthetique', label: 'Esthétique', icon: Icons.spa_rounded),
  ServiceCategory(id: 'photographie', label: 'Photographie', icon: Icons.camera_alt_rounded),
  ServiceCategory(id: 'evenementiel', label: 'Événementiel', icon: Icons.celebration_rounded),
  ServiceCategory(id: 'securite', label: 'Sécurité', icon: Icons.security_rounded),
  ServiceCategory(id: 'transport', label: 'Transport', icon: Icons.directions_car_rounded),
  ServiceCategory(id: 'maconnerie', label: 'Maçonnerie', icon: Icons.foundation_rounded),
  ServiceCategory(id: 'mecanique', label: 'Mécanique', icon: Icons.car_repair_rounded),
  ServiceCategory(id: 'climatisation', label: 'Climatisation', icon: Icons.ac_unit_rounded),
  ServiceCategory(id: 'decoration', label: 'Décoration', icon: Icons.chair_rounded),
  ServiceCategory(id: 'soudure', label: 'Soudure', icon: Icons.hardware_rounded),
];
