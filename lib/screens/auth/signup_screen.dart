import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';
import '../../services/validators.dart';
import '../../theme.dart';
import '../../widgets/auth_widgets.dart';
import 'home_router.dart';

const _wilayas = [
  'Jijel', 'Alger', 'Constantine', 'Sétif', 'Béjaïa', 'Skikda', 'Annaba',
  'Oran', 'Batna', 'Blida', 'Tizi Ouzou', 'Mila', 'Other',
];

const _specialties = [
  'General mechanics', 'Electrical / electronics', 'Bodywork and paint',
  'Engine and gearbox', 'Brakes and suspension', 'Air conditioning',
  'Tires and alignment',
];

const _shopTypes = ['Retail shop', 'Wholesaler', 'Used parts', 'Tires specialist'];

class SignUpScreen extends StatefulWidget {
  final UserRole role;
  const SignUpScreen({super.key, required this.role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();

  // Common
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // Role-specific
  final _garage = TextEditingController();
  final _experience = TextEditingController();
  final _shopName = TextEditingController();
  final _address = TextEditingController();
  final _register = TextEditingController(); // commercial register (optional)
  String? _wilaya;
  String? _specialty;
  String? _shopType;

  bool _accepted = false;
  bool _showTermsError = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _name, _email, _phone, _password, _confirm,
      _garage, _experience, _shopName, _address, _register,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _profile() {
    switch (widget.role) {
      case UserRole.client:
        return {'wilaya': _wilaya ?? ''};
      case UserRole.mechanic:
        return {
          'garage': _garage.text.trim(),
          'specialty': _specialty ?? '',
          'wilaya': _wilaya ?? '',
          'experience': _experience.text.trim(),
        };
      case UserRole.shop:
        return {
          'shopName': _shopName.text.trim(),
          'shopType': _shopType ?? '',
          'address': _address.text.trim(),
          'wilaya': _wilaya ?? '',
          'commercialRegister': _register.text.trim(),
        };
    }
  }

  Future<void> _submit() async {
    final valid = _form.currentState!.validate();
    setState(() => _showTermsError = !_accepted);
    if (!valid || !_accepted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService.instance.signUp(
        role: widget.role,
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        profile: _profile(),
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

  List<Widget> _roleFields() {
    switch (widget.role) {
      case UserRole.client:
        return [
          AppDropdown(
            label: 'Wilaya',
            icon: Icons.location_on_outlined,
            options: _wilayas,
            value: _wilaya,
            onChanged: (v) => setState(() => _wilaya = v),
          ),
        ];
      case UserRole.mechanic:
        return [
          AppTextField(
            controller: _garage,
            label: 'Garage / workshop name',
            icon: Icons.garage_outlined,
            validator: (v) => Validators.required(v, 'Garage name'),
          ),
          AppDropdown(
            label: 'Specialty',
            icon: Icons.build_outlined,
            options: _specialties,
            value: _specialty,
            onChanged: (v) => setState(() => _specialty = v),
          ),
          AppTextField(
            controller: _experience,
            label: 'Years of experience',
            icon: Icons.workspace_premium_outlined,
            keyboardType: TextInputType.number,
            validator: Validators.years,
          ),
          AppDropdown(
            label: 'Wilaya',
            icon: Icons.location_on_outlined,
            options: _wilayas,
            value: _wilaya,
            onChanged: (v) => setState(() => _wilaya = v),
          ),
        ];
      case UserRole.shop:
        return [
          AppTextField(
            controller: _shopName,
            label: 'Shop name',
            icon: Icons.storefront_outlined,
            validator: (v) => Validators.required(v, 'Shop name'),
          ),
          AppDropdown(
            label: 'Shop type',
            icon: Icons.category_outlined,
            options: _shopTypes,
            value: _shopType,
            onChanged: (v) => setState(() => _shopType = v),
          ),
          AppTextField(
            controller: _address,
            label: 'Shop address',
            icon: Icons.place_outlined,
            validator: (v) => Validators.required(v, 'Address'),
          ),
          AppDropdown(
            label: 'Wilaya',
            icon: Icons.location_on_outlined,
            options: _wilayas,
            value: _wilaya,
            onChanged: (v) => setState(() => _wilaya = v),
          ),
          AppTextField(
            controller: _register,
            label: 'Commercial register no. (optional)',
            icon: Icons.badge_outlined,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    return AuthScaffold(
      role: role,
      title: 'Create account',
      subtitle: switch (role) {
        UserRole.client => 'Takes one minute. No payment needed.',
        UserRole.mechanic => 'Your profile will appear in the mechanics directory.',
        UserRole.shop => 'Your stock will be visible to clients near you.',
      },
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ErrorBanner(_error!),
              const _SectionLabel('Account'),
              AppTextField(
                controller: _name,
                label: 'Full name',
                icon: Icons.person_outline,
                validator: (v) => Validators.required(v, 'Name'),
                autofillHints: const [AutofillHints.name],
              ),
              AppTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                autofillHints: const [AutofillHints.email],
              ),
              AppTextField(
                controller: _phone,
                label: 'Phone (e.g. 0550123456)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              PasswordField(
                controller: _password,
                validator: Validators.password,
              ),
              PasswordField(
                controller: _confirm,
                label: 'Confirm password',
                textInputAction: TextInputAction.next,
                validator: Validators.confirm(() => _password.text),
              ),
              const SizedBox(height: 6),
              _SectionLabel(switch (role) {
                UserRole.client => 'Your location',
                UserRole.mechanic => 'Your workshop',
                UserRole.shop => 'Your shop',
              }),
              ..._roleFields(),
              CheckboxListTile(
                value: _accepted,
                onChanged: (v) => setState(() {
                  _accepted = v ?? false;
                  if (_accepted) _showTermsError = false;
                }),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('I accept the terms of use and privacy policy',
                    style: TextStyle(fontSize: 14)),
              ),
              if (_showTermsError)
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('You must accept to continue',
                      style: TextStyle(color: AppColors.warn, fontSize: 12.5)),
                ),
              const SizedBox(height: 8),
              SubmitButton(
                  label: 'Create account',
                  loading: _loading,
                  onPressed: _submit),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?',
                      style: TextStyle(color: AppColors.muted)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Log in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.muted)),
    );
  }
}
