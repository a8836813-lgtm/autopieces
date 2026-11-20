import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';

/// Shop owner: update quantity, price and condition of a matched part, or add
/// it as a new listing when the shop does not have it yet.
class StockEditScreen extends StatefulWidget {
  final Part part;

  const StockEditScreen({super.key, required this.part});

  @override
  State<StockEditScreen> createState() => _StockEditScreenState();
}

class _StockEditScreenState extends State<StockEditScreen> {
  final TextEditingController _price = TextEditingController();
  late int _quantity;
  late String _condition;
  late bool _isNew;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = Repo.instance.stockFor(Repo.myShopId, widget.part.id);
    _isNew = existing == null;
    _quantity = existing?.quantity ?? 1;
    _condition = existing?.condition ?? 'New';
    _price.text = existing == null ? '' : existing.price.toString();
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final digits = _price.text.replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(digits);
    if (price == null || price <= 0) {
      setState(() => _error = 'Enter the price in DZD');
      return;
    }
    Repo.instance.upsertStock(
      shopId: Repo.myShopId,
      partId: widget.part.id,
      quantity: _quantity,
      price: price,
      condition: _condition,
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil(
      (route) => route.isFirst || route.settings.name == '/shop',
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(_isNew ? 'Added to your stock' : 'Stock updated'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final part = widget.part;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your stock',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.teal, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isNew ? 'New listing' : 'Matched in your catalog',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  part.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Serial ${part.oem} · ${part.fits}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity', style: TextStyle(fontSize: 15)),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _quantity > 0
                              ? () => setState(() => _quantity--)
                              : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.remove),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => setState(() => _quantity++),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price (DZD)',
                    errorText: _error,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Condition', style: TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in const ['New', 'Used'])
                      ChoiceChip(
                        label: Text(c),
                        selected: _condition == c,
                        onSelected: (_) => setState(() => _condition = c),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save to my stock',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
