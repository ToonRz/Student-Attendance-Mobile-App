import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/student_provider.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  bool _scanned = false;

  // Manual entry fallback
  final _sessionIdController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _showManualEntry = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _sessionIdController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _processQrData(String rawData) async {
    if (_isProcessing || _scanned) return;
    setState(() {
      _isProcessing = true;
      _scanned = true;
    });

    try {
      final data = jsonDecode(rawData);
      final sessionId = data['sessionId'];
      final token = data['token'];

      if (sessionId == null || token == null) {
        _showError('Invalid QR code format');
        setState(() {
          _isProcessing = false;
          _scanned = false;
        });
        return;
      }

      await _doCheckIn(sessionId, token);
    } catch (e) {
      _showError('Invalid QR code');
      setState(() {
        _isProcessing = false;
        _scanned = false;
      });
    }
  }

  Future<void> _doCheckIn(String sessionId, String token) async {
    // Get student's current location
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission is required for check-in');
        setState(() { _isProcessing = false; _scanned = false; });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;

      final provider = context.read<StudentProvider>();
      final success = await provider.checkIn(
        sessionId: sessionId,
        qrToken: token,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (success && mounted) {
        _showSuccessDialog();
      } else if (provider.error != null && mounted) {
        _showError(provider.error!);
        provider.clearError();
        setState(() { _isProcessing = false; _scanned = false; });
      }
    } catch (e) {
      _showError('Error getting location: $e');
      setState(() { _isProcessing = false; _scanned = false; });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.studentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              const Text(
                'Check-in Successful! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 8),
              const Text(
                'Your attendance has been recorded',
                style: TextStyle(color: AppTheme.textSecondary),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Done',
                gradient: AppTheme.studentGradient,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showManualEntry = !_showManualEntry),
            child: Text(
              _showManualEntry ? 'Scanner' : 'Manual',
              style: const TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
      body: _showManualEntry
          ? _buildManualEntry(provider)
          : _buildScanner(provider),
    );
  }

  Widget _buildScanner(StudentProvider provider) {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _processQrData(barcode.rawValue!);
                break;
              }
            }
          },
        ),

        // Overlay
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),

        // Scanner frame
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.accentColor, width: 3),
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
            ),
          ),
        ),

        // Clear the center area
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 280,
              height: 280,
              child: MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _processQrData(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
            ),
          ),
        ),

        // Instructions
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppTheme.scaffoldDark],
              ),
            ),
            child: Column(
              children: [
                if (_isProcessing)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.accentColor),
                      SizedBox(height: 12),
                      Text(
                        'Verifying location & checking in...',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Point your camera at the QR code\nshown by your teacher',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntry(StudentProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.keyboard_rounded, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Manual Code Entry',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'For testing or when camera is unavailable',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),

          TextFormField(
            controller: _sessionIdController,
            decoration: const InputDecoration(
              labelText: 'Session ID',
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'QR Token',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
          ),
          const SizedBox(height: 32),

          GradientButton(
            text: 'Check In',
            icon: Icons.check_rounded,
            gradient: AppTheme.studentGradient,
            isLoading: provider.isLoading,
            onPressed: () {
              if (_sessionIdController.text.isEmpty || _tokenController.text.isEmpty) {
                _showError('Please fill in both fields');
                return;
              }
              _doCheckIn(_sessionIdController.text.trim(), _tokenController.text.trim());
            },
          ),
        ],
      ),
    );
  }
}
