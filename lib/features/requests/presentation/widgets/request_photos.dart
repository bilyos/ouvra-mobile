import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/net_image.dart';
import '../../domain/job_request.dart';

const maxRequestPhotos = 4;

/// Photo prise ou choisie, déjà réduite, en attente d'envoi.
class LocalPhoto {
  const LocalPhoto({required this.bytes, required this.name, this.mimeType});

  final Uint8List bytes;
  final String name;
  final String? mimeType;
}

/// Jusqu'à 4 photos. Réduites à 1600 px en JPEG avant l'envoi : une photo de
/// téléphone passe de 4 Mo à environ 250 Ko, ce qui compte avec des forfaits
/// chers. Le serveur retire ensuite la position GPS des métadonnées.
class RequestPhotoPicker extends StatelessWidget {
  const RequestPhotoPicker({
    super.key,
    required this.photos,
    required this.onChanged,
    this.enabled = true,
  });

  final List<LocalPhoto> photos;
  final ValueChanged<List<LocalPhoto>> onChanged;
  final bool enabled;

  static final _picker = ImagePicker();

  Future<void> _add(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (source == null) return;
    final room = maxRequestPhotos - photos.length;
    final List<XFile> picked;
    if (source == ImageSource.camera) {
      final one = await _picker.pickImage(
          source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 75);
      picked = one == null ? const [] : [one];
    } else {
      picked = await _picker.pickMultiImage(
          maxWidth: 1600, maxHeight: 1600, imageQuality: 75, limit: room > 1 ? room : null);
    }
    if (picked.isEmpty) return;
    final added = <LocalPhoto>[];
    for (final f in picked.take(room)) {
      added.add(LocalPhoto(
          bytes: await f.readAsBytes(), name: f.name, mimeType: f.mimeType));
    }
    onChanged([...photos, ...added]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;

    if (photos.isEmpty) {
      return Material(
        color: p.muted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: enabled ? () => _add(context) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: SizedBox(
            height: 148,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera_outlined, size: 32, color: p.primary),
                const SizedBox(height: AppSpacing.sm),
                Text('Prendre une photo du problème',
                    style: theme.textTheme.titleSmall?.copyWith(color: p.primary)),
                const SizedBox(height: 2),
                Text('Jusqu\'à 4 photos', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + (photos.length < maxRequestPhotos ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          if (i == photos.length) {
            return Material(
              color: p.muted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: InkWell(
                onTap: enabled ? () => _add(context) : null,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: SizedBox(
                  width: 104,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: p.primary),
                      Text('Ajouter',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: p.primary)),
                    ],
                  ),
                ),
              ),
            );
          }
          return SizedBox(
            width: 104,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Image.memory(photos[i].bytes,
                      fit: BoxFit.cover, cacheWidth: 312),
                ),
                if (enabled)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      tooltip: 'Retirer la photo',
                      onPressed: () =>
                          onChanged([...photos]..removeAt(i)),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Color(0xB3000000), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Photos d'une demande publiée : la première en grand, les autres en ligne.
/// Un toucher ouvre la visionneuse plein écran.
class RequestGallery extends StatelessWidget {
  const RequestGallery({super.key, required this.photos, this.height = 220});

  final List<RequestPhoto> photos;
  final double height;

  void _open(BuildContext context, int index) {
    Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) =>
          _PhotoViewer(photos: photos, initial: index),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    Widget tile(int i, {double? width, double? h}) => Semantics(
          button: true,
          label: 'Agrandir la photo ${i + 1}',
          child: GestureDetector(
            onTap: () => _open(context, i),
            child: NetImage(
              url: photos[i].thumbnailUrl ?? photos[i].url,
              width: width,
              height: h,
              radius: AppSpacing.radiusMd,
            ),
          ),
        );

    if (photos.length == 1) {
      return tile(0, width: double.infinity, h: height);
    }
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(flex: 2, child: tile(0, h: height)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              children: [
                for (var i = 1; i < photos.length && i < 3; i++) ...[
                  if (i > 1) const SizedBox(height: AppSpacing.xs),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        tile(i),
                        if (i == 2 && photos.length > 3)
                          IgnorePointer(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0x8C000000),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              child: Text('+${photos.length - 3}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos, required this.initial});
  final List<RequestPhoto> photos;
  final int initial;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int _index = widget.initial;
  late final _pages = PageController(initialPage: widget.initial);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.photos.length > 1
            ? Text('${_index + 1} sur ${widget.photos.length}',
                style: theme.textTheme.titleSmall?.copyWith(color: Colors.white))
            : null,
        leading: IconButton(
          tooltip: 'Fermer',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: NetImage(url: widget.photos[i].url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
