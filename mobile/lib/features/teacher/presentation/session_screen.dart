import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/session_provider.dart';

class SessionScreen extends StatefulWidget {
  final String classId;
  final String className;

  const SessionScreen({super.key, required this.classId, required this.className});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  int _durationMin = 10;
  bool _isStarting = false;

  @override
  void dispose() {
    // Don't stop QR rotation here — let the provider manage its lifecycle
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() => _isStarting = true);

    try {
      // Get teacher's current location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required. Please enable it in settings.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        setState(() => _isStarting = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;

      final provider = context.read<SessionProvider>();
      final success = await provider.openSession(
        classId: widget.classId,
        durationMin: _durationMin,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to open session'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        provider.clearError();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }

    setState(() => _isStarting = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (provider.activeSession != null) {
              _showCloseConfirmation(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: provider.activeSession == null
          ? _buildStartView(context)
          : _buildQrView(context, provider),
    );
  }

  Widget _buildStartView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.qr_code_2_rounded, size: 50, color: Colors.white),
          ).animate().fadeIn().scale(delay: 200.ms),

          const SizedBox(height: 32),

          Text(
            'Start Attendance Session',
            style: Theme.of(context).textTheme.headlineSmall,
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 8),
          const Text(
            'A QR code will be displayed for students to scan.\nThe code rotates every 30 seconds for security.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 40),

          // Duration selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                const Text('Session Duration', style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _durationMin > 5
                          ? () => setState(() => _durationMin -= 5)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppTheme.primaryColor,
                    ),
                    Text(
                      '$_durationMin min',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: _durationMin < 60
                          ? () => setState(() => _durationMin += 5)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 32),

          GradientButton(
            text: 'Start Session',
            icon: Icons.play_arrow_rounded,
            gradient: AppTheme.accentGradient,
            isLoading: _isStarting,
            onPressed: _startSession,
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context, SessionProvider provider) {
    final qrData = provider.qrData;
    if (qrData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final qrPayload = jsonEncode(qrData);
    final countdown = provider.qrCountdown;
    final progress = countdown / 30;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'QR refreshes in ${countdown}s',
                style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.cardDark,
            valueColor: AlwaysStoppedAnimation<Color>(
              countdown > 10 ? AppTheme.accentColor : AppTheme.warningColor,
            ),
            borderRadius: BorderRadius.circular(4),
          ),

          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: QrImageView(
              data: qrPayload,
              version: QrVersions.auto,
              size: 250,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: Color(0xFF1A1A2E),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 24),

          const Text(
            'Show this QR code to your students',
            style: TextStyle(color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 32),

          // Close session button
          GradientButton(
            text: 'End Session',
            icon: Icons.stop_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
            ),
            onPressed: () => _showCloseConfirmation(context),
          ),
        ],
      ),
    );
  }

  void _showCloseConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Session?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Students will no longer be able to check in.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SessionProvider>().closeSession();
              Navigator.pop(context);
            },
            child: const Text('End Session', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
