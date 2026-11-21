import 'package:material_ui/material_ui.dart';

import '../data/repo.dart';
import '../theme.dart';

/// Shop owner: edit hours, phone, description, delivery and payment methods.
class ShopInfoScreen extends StatefulWidget {
  const ShopInfoScreen({super.key});

  @override
  State<ShopInfoScreen> createState() => _ShopInfoScreenState();
}

class _ShopInfoScreenState extends State<ShopInfoScreen> {
  static const _paymentOptions = [
    'Cash',
    'CIB card',
    'Edahabia',
    'Bank transfer',
  ];

  late final TextEditingController _hours;
  late final TextEditingController _phone;
  late final TextEditingController _about;
  late bool _delivers;
  late final Set<String> _payments;

  @override
  void initState() {
    super.initState();
    final repo = Repo.instance;
    _hours = TextEditingController(text: repo.shopHours);
    _phone = TextEditingController(
      text: repo.shopPhone.isNotEmpty
          ? repo.shopPhone
          : repo.shopById(Repo.myShopId).phone,
    );
    _about = TextEditingController(text: repo.shopAbout);
    _delivers = repo.shopDelivers;
    _payments = {...repo.shopPayments};
  }

  @override
  void dispose() {
    _hours.dispose();
    _phone.dispose();
    _about.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) {
    OutlineInputBorder border() => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: border(),
      enabledBorder: border(),
    );
  }

  void _save() {
    Repo.instance.updateShopInfo(
      hours: _hours.text,
      phone: _phone.text,
      about: _about.text,
      delivers: _delivers,
      payments: _payments,
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Shop information saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop information')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          const Text(
            'Clients see this on your shop page.',
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _hours,
            decoration: _decoration(
              'Opening hours',
              hint: 'Example: Open until 19:00',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _decoration('Phone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _about,
            maxLines: 3,
            decoration: _decoration('About your shop'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Delivery available'),
            subtitle: const Text('Tell clients you can deliver parts'),
            value: _delivers,
            onChanged: (v) => setState(() => _delivers = v),
          ),
          const SizedBox(height: 4),
          const Text(
            'Payment methods',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final p in _paymentOptions)
                FilterChip(
                  label: Text(p),
                  selected: _payments.contains(p),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _payments.add(p);
                    } else if (_payments.length > 1) {
                      _payments.remove(p);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
