import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/mechanic_widgets.dart';
import '../widgets/pill.dart';

/// Shop owner: parts that are out of stock or running low, with a quick
/// "+ units" button and a plain text list to send to a supplier.
class RestockScreen extends StatelessWidget {
  const RestockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Restock list')),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final out = repo.outOfStockItems;
          final low = repo.lowStockItems;
          final all = [...out, ...low];
          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nothing to restock. Every part is above your low-stock limit.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ),
            );
          }
          final summary = StringBuffer('Parts to order:\n');
          for (final s in all) {
            final p = repo.partById(s.partId);
            summary.writeln('- ${p.name} (${p.oem}): have ${s.quantity}, need 10');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Text(
                '${out.length} out of stock, ${low.length} low '
                '(limit: ${repo.lowStockLimit} or fewer).',
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              for (final s in all) _row(repo, s),
              const SectionLabel('List for your supplier'),
              InfoCard(
                child: SelectableText(
                  summary.toString(),
                  style: const TextStyle(fontSize: 13.5, height: 1.5),
                ),
              ),
              const Text(
                'Long-press the text to copy it.',
                style: TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(Repo repo, StockItem s) {
    final part = repo.partById(s.partId);
    final out = s.quantity <= 0;
    return InfoCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Pill(
                      text: out ? 'Out of stock' : '${s.quantity} left',
                      color: out ? AppColors.danger : AppColors.warn,
                      background: out ? AppColors.dangerBg : AppColors.warnBg,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${formatDzd(s.price)} DZD',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => repo.adjustStock(s, 5),
            child: const Text('+5'),
          ),
          const SizedBox(width: 6),
          FilledButton(
            onPressed: () => repo.adjustStock(s, 10),
            child: const Text('+10'),
          ),
        ],
      ),
    );
  }
}
