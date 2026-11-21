import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../theme.dart';
import 'futuristic.dart';

/// Shows which backend the app is using and what is still to be filled in.
class BackendStatusCard extends StatelessWidget {
  const BackendStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final live = AppConfig.backendMode != BackendMode.mock;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      accent: live ? AppColors.green : AppColors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionHeader('Backend')),
              StatusChip(
                label: live ? 'Connected' : 'Demo mode',
                color: live ? AppColors.green : AppColors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _line(Icons.storage_outlined, 'Active source', AppConfig.statusLabel),
          _line(
            Icons.bolt_outlined,
            'Supabase',
            AppConfig.supabaseConfigured ? 'Configured' : 'Placeholder, not set',
          ),
          _line(
            Icons.dns_outlined,
            'PHP / XAMPP',
            AppConfig.phpBaseUrl,
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 8),
          Text(
            '$label  ',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
