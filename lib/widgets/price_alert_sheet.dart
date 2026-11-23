import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';

/// Bottom sheet: ask to be told when [part] is available at or under a price.
Future<void> showPriceAlertSheet(BuildContext context, Part part) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PriceAlertSheet(part: part),
  );
}

class _PriceAlertSheet extends StatefulWidget {
  final Part part;

  const _PriceAlertSheet({required this.part});

  @override
  State<_PriceAlertSheet> createState() => _PriceAlertSheetState();
}

class _PriceAlertSheetState extends State<_PriceAlertSheet> {
  late final TextEditingController _price;
  String? _error;

  @override
  void initState() {
    super.initState();
    final repo = Repo.instance;
    final existing = repo.alertFor(widget.part.id);
    final cheapest = repo.cheapestOffer(widget.part.id);
    final suggested = existing?.targetPrice ??
        (cheapest == null ? 0 : (cheapest.stock.price * 0.9).round());
    _price = TextEditingController(text: suggested > 0 ? '$suggested' : '');
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final digits = _price.text.replaceAll(RegExp(r'[^0-9]'), '');
    final value = int.tryParse(digits);
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter a price in DZD');
      return;
    }
    Repo.instance.setPriceAlert(widget.part.id, value);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert set: ${formatDzd(value)} DZD or less. See it in Saved.'),
      ),
    );
  }

  void _remove() {
    Repo.instance.removePriceAlert(widget.part.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    final cheapest = repo.cheapestOffer(widget.part.id);
    final hasAlert = repo.alertFor(widget.part.id) != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price alert',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.part.name,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            cheapest == null
                ? 'Nobody has it in stock right now.'
                : 'Cheapest now: ${formatDzd(cheapest.stock.price)} DZD at ${cheapest.shop.name}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Tell me when it costs this or less (DZD)',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (hasAlert)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _remove,
                    child: const Text('Remove alert'),
                  ),
                ),
              if (hasAlert) const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.orange),
                  child: Text(hasAlert ? 'Update alert' : 'Set alert'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
