import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';

class _AppointmentDraft {
  final String service;
  final DateTime when;
  final String note;

  const _AppointmentDraft({
    required this.service,
    required this.when,
    required this.note,
  });
}

/// Bottom sheet to request an appointment with a mechanic (demo flow).
Future<void> showAppointmentSheet(
  BuildContext context,
  Mechanic mechanic, {
  String? presetService,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final draft = await showModalBottomSheet<_AppointmentDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (ctx) =>
        _AppointmentForm(mechanic: mechanic, presetService: presetService),
  );
  if (draft == null) return;
  Repo.instance.requestAppointment(
    mechanic: mechanic,
    service: draft.service,
    when: draft.when,
    note: draft.note,
  );
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'Request sent to ${mechanic.name} for ${formatDate(draft.when)} '
        'at ${formatTime(draft.when)}. They will confirm by phone.',
      ),
    ),
  );
}

class _AppointmentForm extends StatefulWidget {
  final Mechanic mechanic;
  final String? presetService;

  const _AppointmentForm({required this.mechanic, this.presetService});

  @override
  State<_AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<_AppointmentForm> {
  late String _service;
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _note = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final names = widget.mechanic.services.map((s) => s.name).toList();
    final preset = widget.presetService;
    _service = (preset != null && names.contains(preset))
        ? preset
        : (names.isNotEmpty ? names.first : 'General inspection');
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final when = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (!when.isAfter(DateTime.now())) {
      setState(() => _error = 'Pick a time in the future.');
      return;
    }
    Navigator.of(context).pop(
      _AppointmentDraft(
        service: _service,
        when: when,
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mechanic;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Request an appointment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              m.name,
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            const Text(
              'Service',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in m.services)
                  ChoiceChip(
                    label: Text(s.name),
                    selected: _service == s.name,
                    onSelected: (_) => setState(() => _service = s.name),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(formatDate(_date)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Describe the problem (optional)',
                hintText: 'e.g. grinding noise when braking',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Send request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
