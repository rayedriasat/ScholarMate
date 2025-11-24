import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../database/database.dart';
import '../widgets/ui/glass_container.dart';
import '../theme/app_colors.dart';

/// Analytics and insights screen
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsService _analyticsService;
  bool _isLoading = true;
  int _totalReadingTime = 0;
  int _totalPagesRead = 0;
  int _readingStreak = 0;
  List<FileReadingStats> _topFiles = [];
  Map<DateTime, int> _activityData = {};

  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
  }

  Future<void> _initializeAnalytics() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    final database = context.read<AppDatabase>();
    _analyticsService = AnalyticsService(database, user.id);

    await _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _analyticsService.getTotalReadingTime(),
        _analyticsService.getTotalPagesRead(),
        _analyticsService.getReadingStreak(),
        _analyticsService.getTopFiles(limit: 5),
        _analyticsService.getReadingActivityByDate(days: 30),
      ]);

      setState(() {
        _totalReadingTime = results[0] as int;
        _totalPagesRead = results[1] as int;
        _readingStreak = results[2] as int;
        _topFiles = results[3] as List<FileReadingStats>;
        _activityData = results[4] as Map<DateTime, int>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Analytics & Insights',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.timer_outlined,
                          title: 'Total Time',
                          value: _formatDuration(_totalReadingTime),
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.auto_stories_outlined,
                          title: 'Pages Read',
                          value: _totalPagesRead.toString(),
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department_outlined,
                          title: 'Reading Streak',
                          value: '$_readingStreak days',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.description_outlined,
                          title: 'Files Read',
                          value: _topFiles.length.toString(),
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Activity heatmap
                  GlassContainer(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Reading Activity (Last 30 Days)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ActivityHeatmap(activityData: _activityData),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Top files
                  GlassContainer(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Most Read Files',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_topFiles.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No reading data yet',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          )
                        else
                          ..._topFiles.map(
                            (stats) => _FileStatTile(stats: stats),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  final Map<DateTime, int> activityData;

  const _ActivityHeatmap({required this.activityData});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 29));

    // Generate 30 days of data
    final days = List.generate(30, (index) {
      final date = startDate.add(Duration(days: index));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      return normalizedDate;
    });

    final maxSeconds = activityData.values.isEmpty
        ? 1
        : activityData.values.reduce((a, b) => a > b ? a : b);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: days.map((date) {
        final seconds = activityData[date] ?? 0;
        final intensity = seconds / maxSeconds;
        final color = seconds == 0
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: (0.2 + (intensity * 0.8)));

        return Tooltip(
          message: '${date.month}/${date.day}: ${seconds ~/ 60}m',
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FileStatTile extends StatelessWidget {
  final FileReadingStats stats;

  const _FileStatTile({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.description, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.fileId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.formattedTime} • ${stats.uniquePagesRead} pages',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
