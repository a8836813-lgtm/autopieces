import 'package:material_ui/material_ui.dart';

import '../models/search_query.dart';
import '../widgets/vehicle_search_panel.dart';
import '../widgets/futuristic.dart';

/// Full-screen search by serial number and/or vehicle.
///
/// Open it and wait for the result:
///   final q = await Navigator.push<SearchQuery>(context,
///       MaterialPageRoute(builder: (_) => const VehicleSearchScreen()));
///   if (q != null) { /* open your results screen with q */ }
///
/// Or pass [onSearch] to handle it directly.
class VehicleSearchScreen extends StatelessWidget {
  final void Function(SearchQuery query)? onSearch;
  const VehicleSearchScreen({super.key, this.onSearch});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Find a part')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: VehicleSearchPanel(
            onSearch: onSearch ?? (q) => Navigator.of(context).pop(q),
          ),
        ),
      ),
    );
  }
}
