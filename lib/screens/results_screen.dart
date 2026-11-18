import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../models/search_query.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/result_card.dart';

/// Shops that have a part in stock. Opened with a text [query] (a free
/// search), an exact [part] (after a scan), or a [vehicleQuery] (brand, model
/// and/or part serial number chosen in the vehicle search).
class ResultsScreen extends StatefulWidget {
  final String? query;
  final Part? part;
  final SearchQuery? vehicleQuery;

  const ResultsScreen({super.key, this.query, this.part, this.vehicleQuery})
      : assert(query != null || part != null || vehicleQuery != null);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  SortMode _sort = SortMode.bestMatch;
  bool _inStockOnly = true;

  Future<void> _call(SearchResult r) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(r.shop.name),
        content: Text('Phone (demo number): ${r.shop.phone}\n${r.shop.hours}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _reserve(SearchResult r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reserve this part?'),
        content: Text(
          '${r.part.name}\n${r.shop.name} · ${formatDzd(r.stock.price)} DZD\n\nYou pay at the shop when you pick it up.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reserve'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    Repo.instance.reserve(r);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reserved at ${r.shop.name}. The shop will confirm.'),
      ),
    );
  }

  Widget _sortChip(String label, SortMode mode) {
    return ChoiceChip(
      label: Text(label),
      selected: _sort == mode,
      onSelected: (_) => setState(() => _sort = mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    final part = widget.part;
    final vehicleQuery = widget.vehicleQuery;
    final title = part?.name ??
        (vehicleQuery != null
            ? vehicleQuery.description
            : 'Results for “${widget.query}”');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final results = part != null
              ? repo.resultsForPart(
                  part.id,
                  sort: _sort,
                  inStockOnly: _inStockOnly,
                )
              : vehicleQuery != null
                  ? repo.searchVehicle(
                      vehicleQuery,
                      sort: _sort,
                      inStockOnly: _inStockOnly,
                    )
                  : repo.search(
                      widget.query!,
                      sort: _sort,
                      inStockOnly: _inStockOnly,
                    );
          final subtitle = part != null
              ? 'OEM ${part.oem} · ${part.fits}'
              : '${results.length} offers from local shops';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _sortChip('Best match', SortMode.bestMatch),
                  _sortChip('Nearest', SortMode.nearest),
                  _sortChip('Cheapest', SortMode.cheapest),
                  FilterChip(
                    label: const Text('In stock only'),
                    selected: _inStockOnly,
                    onSelected: (v) => setState(() => _inStockOnly = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No shop has this in stock right now.\nTry another spelling, or turn off "In stock only".',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: AppColors.muted),
                  ),
                ),
              for (var i = 0; i < results.length; i++)
                ResultCard(
                  result: results[i],
                  highlight: i == 0 && _sort == SortMode.bestMatch,
                  onCall: () => _call(results[i]),
                  onReserve: () => _reserve(results[i]),
                ),
            ],
          );
        },
      ),
    );
  }
}
