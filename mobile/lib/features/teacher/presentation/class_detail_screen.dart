import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/class_provider.dart';
import 'session_screen.dart';
import 'attendance_report_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final String classId;
  final String className;

  const ClassDetailScreen({super.key, required this.classId, required this.className});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadClassDetail(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClassProvider>();
    final cls = provider.selectedClass;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceReportScreen(
                    classId: widget.classId,
                    className: widget.className,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading && cls == null
          ? const Center(child: CircularProgressIndicator())
          : cls == null
              ? const Center(child: Text('Class not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class info card
                      GlassCard(
                        gradient: AppTheme.teacherGradient,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.class_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cls['name'],
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        cls['subject'],
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text('Class Code: ', style: TextStyle(color: Colors.white70)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    cls['code'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: cls['code']));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Code copied!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 24),

                      // Open session button
                      GradientButton(
                        text: 'Open Attendance Session',
                        icon: Icons.qr_code_rounded,
                        gradient: AppTheme.accentGradient,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SessionScreen(
                                classId: widget.classId,
                                className: widget.className,
                              ),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 24),

                      // Students list
                      Text(
                        'Students (${cls['members']?.length ?? 0})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),

                      if (cls['members'] == null || (cls['members'] as List).isEmpty)
                        GlassCard(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.people_outline, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No students yet',
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Share code "${cls['code']}" with students',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ...List.generate((cls['members'] as List).length, (index) {
                          final member = cls['members'][index];
                          final student = member['student'];
                          return GlassCard(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  child: Text(
                                    student['name'][0].toUpperCase(),
                                    style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
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
                                        student['email'],
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                      ),
                                    ],
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
