import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../theme.dart';

/// Icon, title and description for each role.
extension RoleUi on UserRole {
  IconData get icon => switch (this) {
        UserRole.client => Icons.person_outline,
        UserRole.mechanic => Icons.build_outlined,
        UserRole.shop => Icons.storefront_outlined,
      };

  String get title => switch (this) {
        UserRole.client => 'Client',
        UserRole.mechanic => 'Mechanic',
        UserRole.shop => 'Shop owner',
      };

  String get subtitle => switch (this) {
        UserRole.client => 'Find parts in shops near you, scan a part, read repair reports.',
        UserRole.mechanic => 'Publish repair reports and build your reputation.',
        UserRole.shop => 'Publish your stock and receive reservations.',
      };
}

/// Page frame used by the role screen, login and sign-up.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final UserRole? role;
  final List<Widget> children;
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.role,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: showBack),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (role != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(role!.icon, size: 16, color: AppColors.teal),
                          const SizedBox(width: 6),
                          Text(role!.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.teal)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(title,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.muted, height: 1.4)),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        decoration: _decoration(label, icon),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _hidden,
        validator: widget.validator,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        decoration: _decoration(widget.label, Icons.lock_outline).copyWith(
          suffixIcon: IconButton(
            icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _hidden = !_hidden),
          ),
        ),
      ),
    );
  }
}

class AppDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> options;
  final String? value;
  final void Function(String?) onChanged;

  const AppDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: _decoration(label, icon),
        items: [
          for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: onChanged,
        validator: (v) => v == null ? 'Please choose one' : null,
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF5C2BD)),
      ),
      child: Text(message,
          style: const TextStyle(color: AppColors.warn, height: 1.3)),
    );
  }
}

class SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const SubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

InputDecoration _decoration(String label, IconData icon) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.muted),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.teal),
    errorBorder: border(AppColors.warn),
    focusedErrorBorder: border(AppColors.warn),
  );
}
