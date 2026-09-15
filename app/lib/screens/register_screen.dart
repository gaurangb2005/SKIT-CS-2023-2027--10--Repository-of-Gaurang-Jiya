import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  int _grade = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Complete your profile',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Tell us about you', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: Spacing.xs),
          Text(
            'This helps us show you the right content.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: Spacing.xxl),
          AppTextField(label: 'Name', controller: _nameController),
          const SizedBox(height: Spacing.md),
          DropdownButtonFormField<int>(
            initialValue: _grade,
            decoration: const InputDecoration(labelText: 'Class / Grade'),
            items: [for (var g = 1; g <= 12; g++) DropdownMenuItem(value: g, child: Text('Class $g'))],
            onChanged: (v) => setState(() => _grade = v ?? _grade),
          ),
          const SizedBox(height: Spacing.md),
          AppTextField(label: 'School', controller: _schoolController),
          const SizedBox(height: Spacing.xl),
          PrimaryButton(
            label: 'Continue',
            onPressed: () => context.go('/student'),
          ),
        ],
      ),
    );
  }
}
