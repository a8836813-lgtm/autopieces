import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';
import '../../services/validators.dart';
import '../../theme.dart';
import '../../widgets/auth_widgets.dart';
import 'home_router.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService.instance.login(
        role: widget.role,
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => homeForUser(user)),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo() {
    final (email, password) = AuthService.demoCredentials[widget.role]!;
    _email.text = email;
    _password.text = password;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    return AuthScaffold(
      role: role,
      title: 'Log in',
      subtitle: switch (role) {
        UserRole.client => 'Welcome back. Find your parts.',
        UserRole.mechanic => 'Welcome back. Manage your reports.',
        UserRole.shop => 'Welcome back. Manage your stock.',
      },
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ErrorBanner(_error!),
              AppTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                autofillHints: const [AutofillHints.email],
              ),
              PasswordField(
                controller: _password,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password is required' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Password reset is not available in the prototype.')),
                  ),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 4),
              SubmitButton(
                  label: 'Log in', loading: _loading, onPressed: _submit),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _fillDemo,
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text('Use demo account'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New ${role.title.toLowerCase()}?',
                      style: const TextStyle(color: AppColors.muted)),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => SignUpScreen(role: role)),
                    ),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Wrong role? Change it'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
