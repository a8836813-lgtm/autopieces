import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/backend_status_card.dart';
import 'shop_shell.dart';

/// Client profile (demo) with a shortcut into the shop-owner mode.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text(
          'My profile',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _card(
          child: const Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.teal,
                child: Text(
                  'A',
                  style: TextStyle(color: AppColors.onNeon, fontSize: 20),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aymen (demo client)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Jijel · VW Golf 7, 2016',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const BackendStatusCard(),
        _card(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment method',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text('Visa •••• 4242 (demo token)'),
              SizedBox(height: 6),
              Text(
                'The app never stores card numbers. Only a token from the payment provider is kept.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Do you own a parts shop?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Open the shop dashboard to manage your stock by scanning parts and to confirm reservations.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(name: '/shop'),
                    builder: (_) => const ShopShell(),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.onNeon,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Open shop mode (demo)'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
