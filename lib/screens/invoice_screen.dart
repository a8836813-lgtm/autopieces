import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';

/// Mechanic: invoice for a finished job (labour + parts, paid or not).
class InvoiceScreen extends StatefulWidget {
  final JobRequest job;

  const InvoiceScreen({super.key, required this.job});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  late final TextEditingController _labour = TextEditingController(
    text: (widget.job.labourCost ?? widget.job.price).toString(),
  );
  late final TextEditingController _parts =
      TextEditingController(text: widget.job.partsCost.toString());
  late bool _paid = widget.job.paid;

  @override
  void dispose() {
    _labour.dispose();
    _parts.dispose();
    super.dispose();
  }

  static int _n(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  int get _total => _n(_labour) + _n(_parts);

  DateTime get _date => widget.job.completedAt ?? DateTime.now();

  void _save() {
    Repo.instance.saveInvoice(widget.job, labour: _n(_labour), parts: _n(_parts));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Invoice saved')));
  }

  Future<void> _copy() async {
    _save();
    final j = widget.job;
    final text = [
      'INVOICE ${j.invoiceNo}',
      'Date: ${formatDate(_date)}',
      'From: ${Repo.myMechanicName}',
      'To: ${j.clientName}',
      'Car: ${j.car}',
      'Work: ${j.problem}',
      '',
      'Labour: ${formatDzd(_n(_labour))} DZD',
      'Parts: ${formatDzd(_n(_parts))} DZD',
      'TOTAL: ${formatDzd(_total)} DZD',
      _paid ? 'PAID' : 'NOT PAID YET',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice text copied. Paste it in a message.')),
    );
  }

  Widget _amountField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: '$label (DZD)',
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(j.invoiceNo,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _row('Date', formatDate(_date)),
                  _row('From', Repo.myMechanicName),
                  _row('To', j.clientName),
                  _row('Car', j.car),
                  _row('Work', j.problem),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _amountField(_labour, 'Labour'),
            _amountField(_parts, 'Parts'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('Total',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${formatDzd(_total)} DZD',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Client has paid'),
              value: _paid,
              onChanged: (v) {
                setState(() => _paid = v);
                Repo.instance.setJobPaid(j, v);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy text'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
