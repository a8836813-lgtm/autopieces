import 'package:material_ui/material_ui.dart';

import '../data/vehicles.dart';
import '../models/search_query.dart';
import '../theme.dart';
import 'brand_logo.dart';

/// Compact card for the client home: pick Cars/Trucks, tap a brand logo, or
/// type a part serial number. Everything else (all brands, models) opens the
/// full vehicle search through [onOpenFull].
class VehicleQuickSearch extends StatefulWidget {
  /// Called when the user submits a serial number from this card.
  final void Function(SearchQuery query) onSearch;

  /// Opens the full vehicle search. [brand] is the brand that was tapped,
  /// or null for the "All brands" button.
  final void Function(VehicleBrand? brand, VehicleType type) onOpenFull;

  const VehicleQuickSearch({
    super.key,
    required this.onSearch,
    required this.onOpenFull,
  });

  @override
  State<VehicleQuickSearch> createState() => _VehicleQuickSearchState();
}

class _VehicleQuickSearchState extends State<VehicleQuickSearch> {
  static const _shown = 8;

  final _serial = TextEditingController();
  VehicleType _type = VehicleType.car;
  String? _error;

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  void _submitSerial() {
    final error = SearchQuery.validateSerial(_serial.text);
    final normalized = SearchQuery.normalizeSerial(_serial.text);
    if (error != null || normalized.isEmpty) {
      setState(() => _error = error ?? 'Type a part serial number');
      return;
    }
    FocusScope.of(context).unfocus();
    widget.onSearch(SearchQuery(type: _type, serialRaw: _serial.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final brands = brandsFor(_type).take(_shown).toList();
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return Container(
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
            children: [
              const Expanded(
                child: Text(
                  'Search by vehicle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              ChoiceChip(
                label: const Text('Cars'),
                selected: _type == VehicleType.car,
                onSelected: (_) => setState(() => _type = VehicleType.car),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Trucks'),
                selected: _type == VehicleType.truck,
                onSelected: (_) => setState(() => _type = VehicleType.truck),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: brands.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                if (i == brands.length) {
                  return _MoreTile(
                    onTap: () => widget.onOpenFull(null, _type),
                  );
                }
                final b = brands[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => widget.onOpenFull(b, _type),
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      children: [
                        BrandLogo(brand: b, size: 48),
                        const SizedBox(height: 4),
                        Text(
                          b.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serial,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitSerial(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: 'Part serial number, e.g. 5Q0 615 301',
              errorText: _error,
              prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.muted),
              suffixIcon: IconButton(
                tooltip: 'Search by serial number',
                icon: const Icon(Icons.search),
                onPressed: _submitSerial,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: border,
              enabledBorder: border,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: const SizedBox(
        width: 64,
        child: Column(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(Icons.apps, color: AppColors.teal),
              ),
            ),
            SizedBox(height: 4),
            Text('All brands', style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
