import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../theme.dart';

/// Shows which backend the app is using (demo data, PHP/XAMPP or Supabase).
class BackendStatusCard extends StatelessWidget {
  const BackendStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Backend',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _line('Active source', AppConfig.statusLabel),
          _line(
            'Supabase',
            AppConfig.supabaseConfigured ? 'Configured' : 'Placeholder, not set',
          ),
          _line('PHP / XAMPP', AppConfig.phpBaseUrl),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
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
