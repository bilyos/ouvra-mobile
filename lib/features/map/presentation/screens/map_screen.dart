import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../../providers/data/mock_providers.dart';
import '../../../providers/domain/service_provider.dart';

/// Carte des prestataires autour de la position de l'utilisateur.
/// Utilise OpenStreetMap (flutter_map) — aucune clé API requise.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _map = MapController();

  // Centre par défaut : Yaoundé, si la géoloc échoue.
  LatLng _center = const LatLng(3.848, 11.502);
  bool _loading = true;
  bool _located = false;
  ServiceProvider? _selected;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    LatLng? pos;
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          final p = await Geolocator.getCurrentPosition();
          pos = LatLng(p.latitude, p.longitude);
        }
      }
    } catch (_) {
      // Géoloc indisponible/refusée → on garde le centre par défaut.
    }
    if (!mounted) return;
    setState(() {
      if (pos != null) {
        _center = pos;
        _located = true;
      }
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _map.move(_center, 13);
      } catch (_) {}
    });
  }

  /// Position d'un prestataire, dispersé autour de l'utilisateur selon sa
  /// distance et un angle fixe (démo).
  LatLng _providerPos(int index, double km) {
    final bearing = (index * (360 / kMockProviders.length)) * pi / 180;
    final dLat = (km / 111.0) * cos(bearing);
    final dLng =
        (km / (111.0 * cos(_center.latitude * pi / 180))) * sin(bearing);
    return LatLng(_center.latitude + dLat, _center.longitude + dLng);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12.5,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.alloservice.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 22,
                    height: 22,
                    child: const _UserDot(),
                  ),
                  for (var i = 0; i < kMockProviders.length; i++)
                    Marker(
                      point: _providerPos(i, kMockProviders[i].distanceKm),
                      width: 40,
                      height: 40,
                      child: _ProviderPin(
                        provider: kMockProviders[i],
                        selected: _selected?.id == kMockProviders[i].id,
                        onTap: () =>
                            setState(() => _selected = kMockProviders[i]),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('© OpenStreetMap')],
              ),
            ],
          ),

          // En-tête : retour + résumé
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _MapButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Retour',
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.search),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      alignment: Alignment.centerLeft,
                      decoration: _overlay(p, 22),
                      child: Text(
                        _located
                            ? '${kMockProviders.length} prestataires autour de vous'
                            : 'Position inconnue : carte centrée sur Yaoundé',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: AppSpacing.md,
            bottom: _selected == null ? AppSpacing.xxl : 230,
            child: SafeArea(
              child: _MapButton(
                icon: Icons.my_location_rounded,
                tooltip: 'Recentrer sur ma position',
                onTap: () => _map.move(_center, 13),
              ),
            ),
          ),

          if (_loading)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),

          if (_selected != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: SafeArea(
                top: false,
                child: _SelectedCard(
                  provider: _selected!,
                  onClose: () => setState(() => _selected = null),
                  onOpen: () =>
                      context.push(AppRoutes.providerDetail(_selected!.id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Surface posée sur la carte : fond plein, filet, ombre neutre très courte
/// (indispensable pour se détacher des tuiles).
BoxDecoration _overlay(OuvraPalette p, double radius) => BoxDecoration(
      color: p.background,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: p.border, width: 0.5),
      boxShadow: const [
        BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 1)),
      ],
    );

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Ink(
              height: 44,
              width: 44,
              decoration: _overlay(p, 22),
              child: Icon(icon, size: 22, color: p.ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2F7CF6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}

class _ProviderPin extends StatelessWidget {
  const _ProviderPin({
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  final ServiceProvider provider;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = provider.isAvailable ? AppColors.brand700 : AppColors.gray500;
    return Semantics(
      button: true,
      label: '${provider.profession}, ${provider.name}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.2 : 1,
          duration: const Duration(milliseconds: 160),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? p.accent : color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: Icon(Icons.handyman_rounded,
                color: selected ? AppColors.ink : Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _SelectedCard extends StatelessWidget {
  const _SelectedCard({
    required this.provider,
    required this.onClose,
    required this.onOpen,
  });

  final ServiceProvider provider;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.xs, AppSpacing.lg),
      decoration: _overlay(p, AppSpacing.radiusLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AppAvatar(name: provider.name, url: provider.avatarUrl, size: 48),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.profession,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(provider.name,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingStars(
                            rating: provider.rating,
                            reviewCount: provider.reviewCount),
                        const SizedBox(width: AppSpacing.md),
                        Text(formatDistance(provider.distanceKm),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, color: p.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: AppButton(
              label: 'Voir le profil',
              variant: AppButtonVariant.secondary,
              onPressed: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}
