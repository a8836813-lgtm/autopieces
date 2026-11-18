import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../data/vehicles.dart';
import '../models/search_query.dart';
import '../theme.dart';
import 'stock_edit_screen.dart';

/// Shop owner: add a part to the stock by its serial number.
///
/// If the serial number is already in the catalog the part is found and the
/// owner goes straight to quantity and price. Otherwise the owner describes the
/// new part and which vehicles it fits.
class AddPartScreen extends StatefulWidget {
  const AddPartScreen({super.key});

  @override
  State<AddPartScreen> createState() => _AddPartScreenState();
}

class _AddPartScreenState extends State<AddPartScreen> {
  static const _categories = [
    'Brakes', 'Tires', 'Rims', 'Engine', 'Battery', 'Filters',
    'Suspension', 'Electrical', 'Body', 'Other',
  ];

  final _serial = TextEditingController();
  final _name = TextEditingController();
  String _category = _categories.first;
  VehicleType _type = VehicleType.car;
  VehicleBrand? _brand;
  String? _model;
  String? _error;

  @override
  void dispose() {
    _serial.dispose();
    _name.dispose();
    super.dispose();
  }

  Part? get _found => Repo.instance.partBySerial(_serial.text);

  bool get _serialOk => SearchQuery.normalizeSerial(_serial.text).length >= 4;

  void _continue() {
    final error = SearchQuery.validateSerial(_serial.text);
    if (error != null || !_serialOk) {
      setState(() => _error = error ?? 'Enter the part serial number');
      return;
    }

    final existing = _found;
    if (existing != null) {
      _openStock(existing);
      return;
    }

    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give the part a name');
      return;
    }

    final brand = _brand;
    final fitments = brand == null ? <Fitment>[] : [Fitment(brand.id, _model)];
    final fits = brand == null
        ? (_type == VehicleType.car ? 'Most cars' : 'Most trucks')
        : (_model == null ? brand.name : '${brand.name} $_model');

    final part = Repo.instance.addPart(
      name: _name.text,
      serial: _serial.text,
      category: _category,
      fits: fits,
      fitments: fitments,
    );
    _openStock(part);
  }

  void _openStock(Part part) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => StockEditScreen(part: part)),
    );
  }

  InputDecoration _decoration(String label, {String? hint, String? error}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
    );
  }

  @override
  Widget build(BuildContext context) {
    final found = _serialOk ? _found : null;
    final brands = brandsFor(_type);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add a part',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Type the serial number printed on the part or its box. Spaces and dashes do not matter.',
              style: TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _serial,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() => _error = null),
              decoration: _decoration(
                'Serial number',
                hint: 'e.g. 5Q0 615 301',
                error: (found == null) ? _error : null,
              ),
            ),
            const SizedBox(height: 14),
            if (found != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.teal),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Found in the catalog',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      found.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Serial ${found.oem} · ${found.fits}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              )
            else if (_serialOk) ...[
              const Text(
                'New part: describe it',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                onChanged: (_) => setState(() => _error = null),
                decoration: _decoration(
                  'Part name',
                  hint: 'e.g. Front brake disc 288 mm',
                  error: _error,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: _decoration('Category'),
                items: [
                  for (final c in _categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 14),
              const Text(
                'Fits (optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<VehicleType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: VehicleType.car,
                      icon: Icon(Icons.directions_car_outlined),
                      label: Text('Cars')),
                  ButtonSegment(
                      value: VehicleType.truck,
                      icon: Icon(Icons.local_shipping_outlined),
                      label: Text('Trucks')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _brand = null;
                  _model = null;
                }),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<VehicleBrand?>(
                value: _brand,
                isExpanded: true,
                decoration: _decoration('Brand (leave empty if universal)'),
                items: [
                  const DropdownMenuItem<VehicleBrand?>(
                      value: null, child: Text('Universal')),
                  for (final b in brands)
                    DropdownMenuItem<VehicleBrand?>(
                        value: b, child: Text(b.name)),
                ],
                onChanged: (b) => setState(() {
                  _brand = b;
                  _model = null;
                }),
              ),
              if (_brand != null) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  value: _model,
                  isExpanded: true,
                  decoration: _decoration('Model'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('All models')),
                    for (final m in _brand!.models)
                      DropdownMenuItem<String?>(value: m, child: Text(m)),
                  ],
                  onChanged: (m) => setState(() => _model = m),
                ),
              ],
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _continue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  found != null
                      ? 'Set quantity and price'
                      : 'Continue to quantity and price',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
