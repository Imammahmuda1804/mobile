import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final success = await ref.read(authControllerProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (success && mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('RANAHINSIGHT', style: AppTextStyles.label),
          const SizedBox(height: 8),
          const Text('Daftar', style: AppTextStyles.title),
          const SizedBox(height: 18),
          AppTextField(
            controller: _nameController,
            hint: 'Nama lengkap',
            label: 'Nama',
            icon: LucideIcons.userRound,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _emailController,
            hint: 'email@contoh.com',
            label: 'Email',
            icon: LucideIcons.mail,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _passwordController,
            hint: 'Minimal 6 karakter',
            label: 'Password',
            icon: LucideIcons.lock,
            obscureText: true,
          ),
          if (auth.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(auth.errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 18),
          AppButton(
            label: 'Daftar',
            icon: LucideIcons.userPlus,
            isLoading: auth.isLoading,
            onPressed: _register,
          ),
        ],
      ),
    );
  }
}
