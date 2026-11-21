import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../models/search_query.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/futuristic.dart';
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
    // Every contact reveal is logged: this is the lead the shop pays for.
    Repo.instance.logCall(r.shop.id);
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

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (part != null)
            ListenableBuilder(
              listenable: repo,
              builder: (context, _) {
                final saved = repo.isFavoritePart(part.id);
                return IconButton(
                  tooltip: saved ? 'Remove from favorites' : 'Save part',
                  icon: Icon(
                    saved ? Icons.favorite : Icons.favorite_border,
                    color: saved ? AppColors.orange : null,
                  ),
                  onPressed: () => repo.toggleFavoritePart(part.id),
                );
              },
            ),
        ],
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
              ? 'Serial ${part.oem} · ${part.fits}'
              : '${results.length} offers from local shops';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Row(
                children: [
                  const LiveDot(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Nothing in stock',
                  message:
                      'No shop has this right now. Try another spelling, or turn off "In stock only".',
                ),
              for (var i = 0; i < results.length; i++)
                FadeSlideIn(
                  index: i,
                  child: ResultCard(
                    result: results[i],
                    highlight: i == 0 && _sort == SortMode.bestMatch,
                    onCall: () => _call(results[i]),
                    onReserve: () => _reserve(results[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
