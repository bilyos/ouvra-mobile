import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

const maxVoiceSeconds = 60;

/// Note vocale enregistrée, prête à partir.
class LocalVoice {
  const LocalVoice({
    required this.path,
    required this.bytes,
    required this.contentType,
    required this.extension,
    required this.seconds,
  });

  /// Fichier local (ou adresse `blob:` sur le web), pour la réécoute.
  final String path;
  final Uint8List bytes;
  final String contentType;
  final String extension;
  final int seconds;
}

String _clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// Note vocale d'une minute au plus : pratique pour expliquer en français, en
/// anglais ou en pidgin sans avoir à écrire. AAC à 32 kbit/s en mono : une
/// minute pèse environ 240 Ko, raisonnable sur une connexion mobile.
class VoiceRecorder extends StatefulWidget {
  const VoiceRecorder({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final LocalVoice? value;
  final ValueChanged<LocalVoice?> onChanged;
  final bool enabled;

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

enum _RecState { idle, recording, denied, failed }

class _VoiceRecorderState extends State<VoiceRecorder> {
  final _recorder = AudioRecorder();
  _RecState _state = _RecState.idle;
  int _seconds = 0;
  final _levels = List<double>.filled(28, 0, growable: true);
  StreamSubscription<Amplitude>? _amp;
  Timer? _timer;
  DateTime? _startedAt;
  AudioEncoder _encoder = AudioEncoder.aacLc;

  @override
  void dispose() {
    _amp?.cancel();
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      setState(() => _state = _RecState.denied);
      return;
    }
    // AAC partout où c'est possible ; Chrome ne sait faire que de l'Opus en WebM
    _encoder = await _recorder.isEncoderSupported(AudioEncoder.aacLc)
        ? AudioEncoder.aacLc
        : AudioEncoder.opus;
    final path = kIsWeb
        ? ''
        : '${(await getTemporaryDirectory()).path}/note_${DateTime.now().millisecondsSinceEpoch}.${_encoder == AudioEncoder.aacLc ? 'm4a' : 'ogg'}';
    try {
      await _recorder.start(
        RecordConfig(
          encoder: _encoder,
          bitRate: 32000,
          sampleRate: 22050,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: path,
      );
    } catch (_) {
      setState(() => _state = _RecState.failed);
      return;
    }
    HapticFeedback.mediumImpact();
    _startedAt = DateTime.now();
    _amp = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 90))
        .listen((a) {
      // -50 dBFS (silence de la pièce) à 0 dBFS (voix proche) → 0 à 1
      final level = ((a.current + 50) / 50).clamp(0.0, 1.0);
      setState(() {
        _levels
          ..removeAt(0)
          ..add(level);
      });
    });
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final s = DateTime.now().difference(_startedAt!).inSeconds;
      if (s >= maxVoiceSeconds) {
        _stop();
      } else if (s != _seconds) {
        setState(() => _seconds = s);
      }
    });
    setState(() {
      _seconds = 0;
      _levels.fillRange(0, _levels.length, 0);
      _state = _RecState.recording;
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    await _amp?.cancel();
    final path = await _recorder.stop();
    final secs = DateTime.now()
        .difference(_startedAt ?? DateTime.now())
        .inSeconds
        .clamp(1, maxVoiceSeconds);
    if (!mounted) return;
    setState(() => _state = _RecState.idle);
    if (path == null) return;
    final bytes = await XFile(path).readAsBytes();
    final aac = _encoder == AudioEncoder.aacLc;
    widget.onChanged(LocalVoice(
      path: path,
      bytes: bytes,
      contentType: aac ? 'audio/mp4' : (kIsWeb ? 'audio/webm' : 'audio/ogg'),
      extension: aac ? 'm4a' : (kIsWeb ? 'webm' : 'ogg'),
      seconds: secs,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;

    if (widget.value != null) {
      return VoicePlayer(
        source: widget.value!.path,
        local: true,
        seconds: widget.value!.seconds,
        onDelete: widget.enabled ? () => widget.onChanged(null) : null,
      );
    }

    if (_state == _RecState.recording) {
      return Semantics(
        liveRegion: true,
        label: 'Enregistrement en cours, $_seconds secondes',
        child: Container(
          height: 64,
          padding: const EdgeInsets.only(left: AppSpacing.lg, right: 8),
          decoration: BoxDecoration(
            color: p.dangerSoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              _Pulse(color: p.danger),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 40,
                child: Text(_clock(_seconds),
                    style: theme.textTheme.labelLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: Row(
                    children: [
                      for (final l in _levels)
                        Expanded(
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 90),
                              width: 3,
                              height: 4 + 24 * l,
                              decoration: BoxDecoration(
                                color: p.danger.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${maxVoiceSeconds - _seconds} s',
                  style: theme.textTheme.labelSmall),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _stop,
                  style: FilledButton.styleFrom(
                    backgroundColor: p.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 20),
                  label: const Text('Arrêter'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: p.muted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: widget.enabled ? _start : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.lg),
                  Container(
                    width: 40,
                    height: 40,
                    decoration:
                        BoxDecoration(color: p.primary, shape: BoxShape.circle),
                    child: Icon(Icons.mic_rounded, color: p.onPrimary, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expliquer en vocal',
                            style: theme.textTheme.titleSmall),
                        Text('Une minute au plus, dans la langue de votre choix',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
        if (_state == _RecState.denied || _state == _RecState.failed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              _state == _RecState.denied
                  ? 'Le micro est bloqué. Autorisez-le dans les réglages du téléphone, ou écrivez quelques mots.'
                  : 'L\'enregistrement n\'a pas pu démarrer. Écrivez quelques mots à la place.',
              style: theme.textTheme.bodySmall?.copyWith(color: p.danger),
            ),
          ),
      ],
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.color});
  final Color color;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      );
}

/// Lecteur de note vocale : bouton lecture, barre de progression, durée.
class VoicePlayer extends StatefulWidget {
  const VoicePlayer({
    super.key,
    required this.source,
    this.local = false,
    this.seconds,
    this.onDelete,
  });

  /// URL distante, ou chemin local si [local].
  final String source;
  final bool local;
  final int? seconds;
  final VoidCallback? onDelete;

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration? _duration;
  final _subs = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _subs
      ..add(_player.onPlayerStateChanged.listen((s) => setState(() => _state = s)))
      ..add(_player.onPositionChanged.listen((d) => setState(() => _position = d)))
      ..add(_player.onDurationChanged.listen((d) => setState(() => _duration = d)))
      ..add(_player.onPlayerComplete
          .listen((_) => setState(() => _position = Duration.zero)));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
    } else if (_state == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.play(widget.local && !kIsWeb
          ? DeviceFileSource(widget.source)
          : UrlSource(widget.source));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final playing = _state == PlayerState.playing;
    final total = _duration?.inMilliseconds ??
        ((widget.seconds ?? 0) * 1000);
    final progress =
        total == 0 ? 0.0 : (_position.inMilliseconds / total).clamp(0.0, 1.0);
    final shown = playing || _position > Duration.zero
        ? _position.inSeconds
        : (_duration?.inSeconds ?? widget.seconds ?? 0);

    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: p.border, width: 0.5),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: playing ? 'Mettre en pause' : 'Écouter la note vocale',
            child: Material(
              color: p.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _toggle,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: p.onPrimary,
                      size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: p.primary,
                backgroundColor: p.border,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(_clock(shown),
              style: theme.textTheme.labelMedium?.copyWith(
                  color: p.mutedForeground,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          if (widget.onDelete != null)
            IconButton(
              tooltip: 'Supprimer la note vocale',
              onPressed: widget.onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: p.mutedForeground),
            )
          else
            const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}
