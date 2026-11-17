import 'package:material_ui/material_ui.dart';

import '../data/vehicles.dart';
import '../models/search_query.dart';
import '../theme.dart';
import 'brand_logo.dart';

/// Part serial number + Cars/Trucks + brand grid + model chips.
/// Calls [onSearch] with a [SearchQuery] when the user taps the button.
class VehicleSearchPanel extends StatefulWidget {
  final void Function(SearchQuery query) onSearch;
  const VehicleSearchPanel({super.key, required this.onSearch});

  @override
  State<VehicleSearchPanel> createState() => _VehicleSearchPanelState();
}

class _VehicleSearchPanelState extends State<VehicleSearchPanel> {
  static const _collapsedCount = 8;

  final _serial = TextEditingController();
  VehicleType _type = VehicleType.car;
  VehicleBrand? _brand;
  String? _model;
  bool _showAll = false;
  String? _serialError;

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  void _setType(VehicleType t) {
    if (t == _type) return;
    setState(() {
      _type = t;
      _brand = null;
      _model = null;
      _showAll = false;
    });
  }

  void _pickBrand(VehicleBrand b) {
    setState(() {
      if (_brand == b) {
        _brand = null;
      } else {
        _brand = b;
      }
      _model = null;
    });
  }

  void _submit() {
    final error = SearchQuery.validateSerial(_serial.text);
    setState(() => _serialError = error);
    if (error != null) return;

    final query = SearchQuery(
      type: _type,
      brand: _brand,
      model: _model,
      serialRaw: _serial.text.trim(),
    );
    if (query.isEmpty) {
      setState(() =>
          _serialError = 'Type a part number or choose a brand to search');
      return;
    }
    FocusScope.of(context).unfocus();
    widget.onSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final brands = brandsFor(_type);
    final visible = _showAll ? brands : brands.take(_collapsedCount).toList();
    final preview = SearchQuery(
      type: _type,
      brand: _brand,
      model: _model,
      serialRaw: _serial.text,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Part serial number'),
        TextField(
          controller: _serial,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(),
          onChanged: (_) => setState(() => _serialError = null),
          decoration: InputDecoration(
            hintText: 'e.g. 1K0 698 151 A',
            helperText: 'Serial numbers are universal: works for any brand.',
            errorText: _serialError,
            prefixIcon:
                const Icon(Icons.pin_outlined, color: AppColors.muted),
            suffixIcon: _serial.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _serial.clear();
                      _serialError = null;
                    }),
                  ),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.teal),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const _Label('Vehicle'),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<VehicleType>(
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
            onSelectionChanged: (s) => _setType(s.first),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 8,
          childAspectRatio: 0.78,
          children: [
            for (final b in visible)
              _BrandTile(
                brand: b,
                selected: b == _brand,
                onTap: () => _pickBrand(b),
              ),
          ],
        ),
        if (brands.length > _collapsedCount)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showAll = !_showAll),
              icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more),
              label: Text(_showAll
                  ? 'Show fewer brands'
                  : 'Show all ${brands.length} brands'),
            ),
          ),
        if (_brand != null) ...[
          const SizedBox(height: 12),
          _Label('${_brand!.name} models'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('All models'),
                selected: _model == null,
                onSelected: (_) => setState(() => _model = null),
              ),
              for (final m in _brand!.models)
                ChoiceChip(
                  label: Text(m),
                  selected: _model == m,
                  onSelected: (_) => setState(() => _model = m),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        if (!preview.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(preview.description,
                style: const TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.search),
            label: const Text('Search parts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.muted)),
    );
  }
}

class _BrandTile extends StatelessWidget {
  final VehicleBrand brand;
  final bool selected;
  final VoidCallback onTap;

  const _BrandTile({
    required this.brand,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? AppColors.greenBg : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.teal : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            BrandLogo(brand: brand, size: 54),
            const SizedBox(height: 6),
            Text(
              brand.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
