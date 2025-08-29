import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:just_audio/just_audio.dart';

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
            if (isPlayerReady) ...[
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: duration.inMilliseconds > 0 
                          ? position.inMilliseconds / duration.inMilliseconds 
                          : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        ),
                      ),
                    ),
                    Center(
                      child: Text('Waveform'), // Placeholder for waveform
                    ),
                  ],
                ),
              ),
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
            ] else ...[
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Icon(
                      Icons.audio_file_rounded,
                      size: 48,
                      color: AppTheme.errorColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Audio file not available',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
