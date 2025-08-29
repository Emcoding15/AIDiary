import 'package:flutter/material.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import '../config/theme.dart';

class StatsCard extends StatelessWidget {
  final int totalEntries;
  final int entriesThisWeek;
  final int totalMinutes;

  const StatsCard({
    Key? key,
    required this.totalEntries,
    required this.entriesThisWeek,
    required this.totalMinutes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF38F9D7),
            Color(0xFF1DE9B6),
            Color(0xFF13BBAF),
          ],
          stops: [0.0, 0.7, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                margin: const EdgeInsets.only(top: 32),
                height: 185,
                width: double.infinity,
                child: WaveWidget(
                  config: CustomConfig(
                    gradients: [
                      [
                        Color(0xFF38F9D7),
                        Color(0xFF1DE9B6),
                        Color(0xFF13BBAF),
                      ],
                      [
                        Color(0xFF13BBAF),
                        Color(0xFF1DE9B6),
                        Color(0xFF38F9D7),
                      ],
                    ],
                    durations: [4500, 19440],
                    heightPercentages: [0.22, 0.25],
                    blur: MaskFilter.blur(BlurStyle.solid, 2),
                    gradientBegin: Alignment.centerLeft,
                    gradientEnd: Alignment.centerRight,
                  ),
                  waveAmplitude: 3,
                  backgroundColor: Colors.transparent,
                  size: const Size(double.infinity, double.infinity),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Color(0xFF1A2B2E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatItem(
                        context,
                        '$totalEntries',
                        'Total\nEntries',
                        Icons.list_alt_rounded,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        context,
                        '$entriesThisWeek',
                        'Entries\nThis Week',
                        Icons.calendar_today_rounded,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        context,
                        '$totalMinutes',
                        'Total\nMinutes',
                        Icons.access_time_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Color(0xFF1A2B2E),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1A2B2E),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
