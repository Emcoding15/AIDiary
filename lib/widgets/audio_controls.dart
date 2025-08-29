import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

class AudioControls extends StatelessWidget {
  final bool isPlayerReady;
  final bool isPlaying;
  final Duration duration;
  final Duration position;
  final double? fileSize;
  final VoidCallback onPlayPause;
  final AudioPlayer audioPlayer;

  const AudioControls({
    Key? key,
    required this.isPlayerReady,
    required this.isPlaying,
    required this.duration,
    required this.position,
    required this.fileSize,
    required this.onPlayPause,
    required this.audioPlayer,
  }) : super(key: key);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatFileSize(double kiloBytes) {
    if (kiloBytes < 1024) {
      return '${kiloBytes.toStringAsFixed(1)} KB';
    } else {
      final megaBytes = kiloBytes / 1024;
      return '${megaBytes.toStringAsFixed(2)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.headphones_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Audio Recording',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (fileSize != null)
                  Row(
                    children: [
                      Icon(
                        Icons.storage_rounded,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatFileSize(fileSize!),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Dynamic progress bar (step 3)
            Builder(
              builder: (context) {
                double progress = (duration.inMilliseconds > 0)
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0;
                return WaveProgressBar(
                  progress: progress.clamp(0.0, 1.0),
                  height: 24,
                  backgroundColor: Colors.grey.shade800,
                  waveColor: Theme.of(context).colorScheme.primary,
                  waveColor2: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: 12,
                  amplitude: 8,
                  speed: 1.0,
                  frequency: 1.0,
                );
              },
            ),
            if (isPlayerReady) ...[
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  thumbColor: Theme.of(context).colorScheme.primary,
                  overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: position.inSeconds.toDouble(),
                  min: 0,
                  max: duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    final newPosition = Duration(seconds: value.toInt());
                    audioPlayer.seek(newPosition);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded),
                    onPressed: () {
                      final newPosition = position - const Duration(seconds: 10);
                      audioPlayer.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                    },
                    iconSize: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      boxShadow: AppTheme.lightShadow,
                    ),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: AppTheme.shortAnimationDuration,
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          key: ValueKey<bool>(isPlaying),
                          color: Colors.white,
                        ),
                      ),
                      onPressed: onPlayPause,
                      iconSize: 36,
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded),
                    onPressed: () {
                      final newPosition = position + const Duration(seconds: 10);
                      audioPlayer.seek(newPosition > duration ? duration : newPosition);
                    },
                    iconSize: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WaveProgressBar extends StatefulWidget {
  final double progress;
  final double height;
  final Color backgroundColor;
  final Color waveColor;
  final Color waveColor2;
  final double borderRadius;
  final double amplitude;
  final double speed;
  final double frequency;

  const WaveProgressBar({
    super.key,
    required this.progress,
    this.height = 24,
    required this.backgroundColor,
    required this.waveColor,
    required this.waveColor2,
    this.borderRadius = 12,
    this.amplitude = 8,
    this.speed = 1.0,
    this.frequency = 1.0,
  });

  @override
  State<WaveProgressBar> createState() => _WaveProgressBarState();
}

class _WaveProgressBarState extends State<WaveProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WaveProgressPainter(
            progress: widget.progress,
            backgroundColor: widget.backgroundColor,
            waveColor: widget.waveColor,
            waveColor2: widget.waveColor2,
            borderRadius: widget.borderRadius,
            amplitude: widget.amplitude,
            phase: _controller.value * 2 * math.pi * widget.speed,
            frequency: widget.frequency,
          ),
          size: Size(double.infinity, widget.height),
        );
      },
    );
  }
}

class _WaveProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color waveColor;
  final Color waveColor2;
  final double borderRadius;
  final double amplitude;
  final double phase;
  final double frequency;

  _WaveProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.waveColor,
    required this.waveColor2,
    required this.borderRadius,
    required this.amplitude,
    required this.phase,
    required this.frequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    // Draw background
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(bgRect, bgPaint);

    // Draw wave progress
    final progressWidth = size.width * progress.clamp(0.0, 1.0);
    if (progressWidth <= 0) return;
    final waveRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, progressWidth, size.height),
      Radius.circular(borderRadius),
    );
    canvas.save();
    canvas.clipRRect(waveRect);

    // Draw first wave
    final wavePaint = Paint()
      ..color = waveColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= progressWidth; x++) {
      double y = size.height / 2 + amplitude * math.sin(frequency * (x / progressWidth) * 2 * math.pi + phase);
      path.lineTo(x, y);
    }
    path.lineTo(progressWidth, size.height);
    path.close();
    canvas.drawPath(path, wavePaint);

    // Draw second wave (symmetrical, phase offset by pi)
    final wavePaint2 = Paint()
      ..color = waveColor2.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height);
    for (double x = 0; x <= progressWidth; x++) {
      double y = size.height / 2 + amplitude * math.sin(frequency * (x / progressWidth) * 2 * math.pi + phase + math.pi);
      path2.lineTo(x, y);
    }
    path2.lineTo(progressWidth, size.height);
    path2.close();
    canvas.drawPath(path2, wavePaint2);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaveProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.waveColor2 != waveColor2 ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.phase != phase ||
        oldDelegate.frequency != frequency;
  }
}
