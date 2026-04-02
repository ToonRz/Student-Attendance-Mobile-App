import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/student_provider.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class code'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    final provider = context.read<StudentProvider>();
    final success = await provider.joinClass(code);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined class! 🎉'), backgroundColor: AppTheme.successColor),
      );
      Navigator.pop(context);
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: AppTheme.errorColor),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Class'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.studentGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.group_add_rounded, size: 40, color: Colors.white),
            ),

            const SizedBox(height: 32),

            Text('Enter Class Code', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Ask your teacher for the 6-digit class code',
              style: TextStyle(color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 32),

            TextFormField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '- - - - - -',
                hintStyle: TextStyle(
                  fontSize: 28,
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  letterSpacing: 8,
                ),
              ),
            ),

            const SizedBox(height: 32),

            GradientButton(
              text: 'Join Class',
              icon: Icons.login_rounded,
              gradient: AppTheme.studentGradient,
              isLoading: provider.isLoading,
              onPressed: _join,
            ),
          ],
        ),
      ),
    );
  }
}
