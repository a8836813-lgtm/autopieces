import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../utils.dart';
import '../widgets/mechanic_widgets.dart';

/// Mechanic helper: price a job (labor, parts, discount, TVA) for a client.
class EstimateScreen extends StatefulWidget {
  const EstimateScreen({super.key});

  @override
  State<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends State<EstimateScreen> {
  final _hours = TextEditingController(text: '1');
  final _rate = TextEditingController(text: '1500');
  final _parts = TextEditingController(text: '0');
  final _discount = TextEditingController(text: '0');
  bool _tva = false;

  @override
  void dispose() {
    for (final c in [_hours, _rate, _parts, _discount]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.').trim()) ?? 0;

  Widget _field(TextEditingController c, String label, String suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, int value, {bool bold = false, bool minus = false}) {
    final style = TextStyle(
      fontSize: bold ? 18 : 14.5,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('${minus ? '- ' : ''}${formatDzd(value)} DZD', style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labor = (_num(_hours) * _num(_rate)).round();
    final parts = _num(_parts).round();
    final subtotal = labor + parts;
    final pct = _num(_discount).clamp(0, 100);
    final discount = (subtotal * pct / 100).round();
    final afterDiscount = subtotal - discount;
    final tva = _tva ? (afterDiscount * 0.19).round() : 0;
    final total = afterDiscount + tva;

    return Scaffold(
      appBar: AppBar(title: const Text('Estimate')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          const Text(
            'Work out a clear price for the client before you start.',
            style: TextStyle(fontSize: 13.5, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          _field(_hours, 'Labor time', 'hours'),
          _field(_rate, 'Hourly rate', 'DZD / h'),
          _field(_parts, 'Parts cost', 'DZD'),
          _field(_discount, 'Discount', '%'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add TVA 19%'),
            subtitle: const Text('For registered garages that invoice'),
            value: _tva,
            onChanged: (v) => setState(() => _tva = v),
          ),
          const SizedBox(height: 8),
          InfoCard(
            child: Column(
              children: [
                _row('Labor', labor),
                _row('Parts', parts),
                if (discount > 0) _row('Discount (${pct.toStringAsFixed(0)}%)', discount, minus: true),
                if (_tva) _row('TVA 19%', tva),
                const Divider(height: 20),
                _row('Total', total, bold: true),
              ],
            ),
          ),
          const SizedBox(height: 4),
          InfoCard(
            child: SelectableText(
              'Estimate: labor ${formatDzd(labor)} DZD + parts ${formatDzd(parts)} DZD'
              '${discount > 0 ? ' - discount ${formatDzd(discount)} DZD' : ''}'
              '${_tva ? ' + TVA ${formatDzd(tva)} DZD' : ''}'
              ' = ${formatDzd(total)} DZD. Long-press to copy and send it to the client.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
