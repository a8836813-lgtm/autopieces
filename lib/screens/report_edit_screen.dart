import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';

/// Mechanic: write a new repair report (problem, diagnosis, work, parts, cost).
class ReportEditScreen extends StatefulWidget {
  /// When set, the screen edits this report instead of writing a new one.
  final RepairReport? existing;

  const ReportEditScreen({super.key, this.existing});

  @override
  State<ReportEditScreen> createState() => _ReportEditScreenState();
}

class _ReportEditScreenState extends State<ReportEditScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _car = TextEditingController();
  final _problem = TextEditingController();
  final _diagnosis = TextEditingController();
  final _work = TextEditingController();
  final _parts = TextEditingController();
  final _cost = TextEditingController();

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    if (r != null) {
      _title.text = r.title;
      _car.text = r.car;
      _problem.text = r.problem;
      _diagnosis.text = r.diagnosis;
      _work.text = r.workDone;
      _parts.text = r.parts;
      _cost.text = r.cost.toString();
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _car, _problem, _diagnosis, _work, _parts, _cost]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  void _publish() {
    if (!_form.currentState!.validate()) return;
    final digits = _cost.text.replaceAll(RegExp(r'[^0-9]'), '');
    final old = widget.existing;
    if (old != null) {
      Repo.instance.updateReport(
        old,
        old.copyWith(
          title: _title.text.trim(),
          car: _car.text.trim(),
          problem: _problem.text.trim(),
          diagnosis: _diagnosis.text.trim(),
          workDone: _work.text.trim(),
          parts: _parts.text.trim(),
          cost: int.parse(digits),
        ),
      );
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Report updated')),
      );
      return;
    }
    Repo.instance.addReport(
      RepairReport(
        mechanicName: Repo.myMechanicName,
        title: _title.text.trim(),
        car: _car.text.trim(),
        problem: _problem.text.trim(),
        diagnosis: _diagnosis.text.trim(),
        workDone: _work.text.trim(),
        parts: _parts.text.trim(),
        cost: int.parse(digits),
      ),
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Report published')),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    int lines = 1,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: lines,
        keyboardType: type,
        validator: validator ?? (v) => _required(v, label),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: lines > 1,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? 'Edit repair report' : 'New repair report',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text(
                'Clients will find this report when they search for the same problem.',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              _field(_title, 'Title',
                  hint: 'e.g. Grinding noise on braking'),
              _field(_car, 'Car', hint: 'e.g. VW Golf 7 · 2016'),
              _field(_problem, 'Problem',
                  hint: 'What did the customer report?', lines: 3),
              _field(_diagnosis, 'Diagnosis',
                  hint: 'What was the cause?', lines: 3),
              _field(_work, 'Work done', lines: 3),
              _field(
                _parts,
                'Parts used (optional)',
                hint: 'e.g. front discs 5Q0615301, pads 5Q0698151',
                lines: 2,
                validator: (_) => null,
              ),
              _field(
                _cost,
                'Labor and parts cost (DZD)',
                type: TextInputType.number,
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  final n = int.tryParse(digits);
                  if (n == null || n <= 0) return 'Enter the cost in DZD';
                  return null;
                },
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _publish,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _editing ? 'Save changes' : 'Publish report',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
