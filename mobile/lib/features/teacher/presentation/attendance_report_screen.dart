import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/class_provider.dart';

class AttendanceReportScreen extends StatefulWidget {
  final String classId;
  final String className;

  const AttendanceReportScreen({super.key, required this.classId, required this.className});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadReport(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClassProvider>();
    final report = provider.report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoading && report == null
          ? const Center(child: CircularProgressIndicator())
          : report == null
              ? const Center(child: Text('No report available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.teacherGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.className,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              report['subject'] ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatItem(
                                  label: 'Sessions',
                                  value: '${report['totalSessions']}',
                                  icon: Icons.event_note_rounded,
                                ),
                                _StatItem(
                                  label: 'Students',
                                  value: '${report['totalStudents']}',
                                  icon: Icons.people_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 24),

                      Text('Student Statistics', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),

                      if (report['students'] == null || (report['students'] as List).isEmpty)
                        const GlassCard(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No student data', style: TextStyle(color: AppTheme.textMuted)),
                            ),
                          ),
                        )
                      else
                        ...List.generate((report['students'] as List).length, (index) {
                          final stat = report['students'][index];
                          final student = stat['student'];
                          final rate = stat['attendanceRate'] ?? 0;

                          Color rateColor;
                          if (rate >= 80) {
                            rateColor = AppTheme.successColor;
                          } else if (rate >= 60) {
                            rateColor = AppTheme.warningColor;
                          } else {
                            rateColor = AppTheme.errorColor;
                          }

                          return GlassCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: rateColor.withValues(alpha: 0.2),
                                      child: Text(
                                        student['name'][0].toUpperCase(),
                                        style: TextStyle(color: rateColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${stat['attended']}/${stat['totalSessions']} sessions • ${stat['absent']} absent',
                                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: rateColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$rate%',
                                        style: TextStyle(
                                          color: rateColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: rate / 100,
                                    backgroundColor: AppTheme.cardDark,
                                    valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
