import 'dart:ui';
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28), // increased blur
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.42),
                blurRadius: 48,
                offset: Offset(0, 24),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC38F9D7), // 80% opacity
                Color(0xCC1DE9B6),
                Color(0xCC13BBAF),
              ],
              stops: [0.0, 0.7, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Subtle white overlay for extra glass effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
              ),
              ClipRRect(
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
            ],
          ),
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
