import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/pill.dart';
import 'results_screen.dart';

/// Client: every reservation made, with a filter and a spending summary.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const _filters = ['All', 'Active', 'Completed', 'Cancelled'];
  String _filter = 'All';

  bool _matches(Reservation r) {
    switch (_filter) {
      case 'Active':
        return r.isActive;
      case 'Completed':
        return r.status == 'Completed';
      case 'Cancelled':
        return r.status == 'Cancelled';
      default:
        return true;
    }
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Pill _statusPill(String status) {
    switch (status) {
      case 'Completed':
        return const Pill(
            text: 'Completed', color: AppColors.green, background: AppColors.greenBg);
      case 'Confirmed':
        return const Pill(
            text: 'Confirmed', color: AppColors.teal, background: AppColors.chipBg);
      case 'Cancelled':
        return const Pill(
            text: 'Cancelled', color: AppColors.muted, background: AppColors.chipBg);
      default:
        return const Pill(
            text: 'Pending', color: AppColors.warn, background: AppColors.warnBg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order history',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final all = List<Reservation>.of(repo.clientReservations)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final shown = all.where(_matches).toList();
          final completed = all.where((r) => r.status == 'Completed').length;
          final shopsUsed = all.map((r) => r.item.shop.id).toSet().length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                children: [
                  _stat('${formatDzd(repo.clientSpent)} DZD', 'Spent'),
                  const SizedBox(width: 8),
                  _stat('$completed', 'Picked up'),
                  const SizedBox(width: 8),
                  _stat('$shopsUsed', 'Shops'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final f in _filters)
                    ChoiceChip(
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nothing here yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              for (final r in shown)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.item.part.name,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          _statusPill(r.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r.item.shop.name} · ${formatDzd(r.item.stock.price)} DZD',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.muted),
                      ),
                      Text(
                        r.status == 'Completed' && r.completedAt != null
                            ? 'Picked up ${formatDate(r.completedAt!)}'
                            : 'Reserved ${formatDate(r.createdAt)}',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ResultsScreen(part: r.item.part),
                          ),
                        ),
                        icon: const Icon(Icons.replay, size: 18),
                        label: const Text('Buy again'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
