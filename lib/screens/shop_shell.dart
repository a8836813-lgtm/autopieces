import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../data/scan_mode.dart';
import '../services/chat_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/mechanic_widgets.dart';
import '../widgets/pill.dart';
import '../widgets/review_widgets.dart';
import 'add_part_screen.dart';
import 'auth/home_router.dart';
import 'messages_screen.dart';
import 'restock_screen.dart';
import 'scan_screen.dart';
import 'shop_info_screen.dart';
import 'stock_edit_screen.dart';

enum _StockFilter { all, low, out, fresh, used }

enum _StockSort { name, priceLow, priceHigh, quantity }

/// Shop-owner mode: dashboard, stock, orders, insights and shop settings.
class ShopShell extends StatefulWidget {
  const ShopShell({super.key});

  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  int _tab = 0;
  _StockFilter _filter = _StockFilter.all;
  _StockSort _sort = _StockSort.name;
  String _orderFilter = 'Pending';
  final _stockSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    final me = ChatIdentity.current();
    if (me != null) ChatService.instance.start(me, this);
  }

  @override
  void dispose() {
    ChatService.instance.stop(this);
    _stockSearch.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers

  void _go(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _scan() => _go(const ScanScreen(mode: ScanMode.shop));

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  // ------------------------------------------------------------------- home

  Widget _homeTab(Repo repo) {
    final shop = repo.shopById(Repo.myShopId);
    final items = repo.stockOfShop(Repo.myShopId);
    final pending = repo.pendingOrdersCount;
    final out = repo.outOfStockItems.length;
    final low = repo.lowStockItems.length;
    final thisWeek = repo.weekSales;
    final lastWeek = repo.lastWeekSales;
    final top = repo.topSelling(limit: 3);

    String change;
    if (lastWeek == 0) {
      change = thisWeek == 0 ? 'No sales yet' : 'First week with sales';
    } else {
      final pct = ((thisWeek - lastWeek) * 100 / lastWeek).round();
      change = '${pct >= 0 ? '+' : ''}$pct% vs last week';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          '${_greeting()},',
          style: const TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        Text(
          shop.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        InfoCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 11,
                color: repo.shopOpen ? AppColors.green : AppColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repo.shopOpen ? 'Shop is open' : 'Shop is closed',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      repo.shopHours,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: repo.shopOpen, onChanged: repo.setShopOpen),
            ],
          ),
        ),
        if (pending > 0)
          InfoCard(
            onTap: () => setState(() {
              _orderFilter = 'Pending';
              _tab = 2;
            }),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined,
                    color: AppColors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$pending reservation${pending == 1 ? '' : 's'} waiting for you to confirm',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        if (out + low > 0)
          InfoCard(
            onTap: () => _go(const RestockScreen()),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$out out of stock, $low running low. Tap to restock.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            StatTile(
              icon: Icons.point_of_sale,
              value: '${formatDzd(repo.todaySales)} DZD',
              label: 'Sold today',
              color: AppColors.orange,
            ),
            StatTile(
              icon: Icons.inventory_2_outlined,
              value: '${formatDzd(repo.stockValue)} DZD',
              label: 'Stock value',
            ),
            StatTile(
              icon: Icons.category_outlined,
              value: '${items.length}',
              label: 'Parts listed',
            ),
            StatTile(
              icon: Icons.receipt_long_outlined,
              value: '$pending',
              label: 'Pending orders',
              color: AppColors.green,
            ),
          ],
        ),
        const SizedBox(height: 14),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales, last 7 days',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatDzd(thisWeek)} DZD · $change',
                style: TextStyle(
                  fontSize: 13,
                  color: thisWeek >= lastWeek
                      ? AppColors.green
                      : AppColors.danger,
                ),
              ),
              const SizedBox(height: 14),
              WeekBars(values: repo.weeklySales()),
            ],
          ),
        ),
        const SectionLabel('Quick actions'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            QuickAction(
              icon: Icons.center_focus_strong_outlined,
              label: 'Scan a part',
              color: AppColors.orange,
              onTap: _scan,
            ),
            QuickAction(
              icon: Icons.pin_outlined,
              label: 'Add a part',
              onTap: () => _go(const AddPartScreen()),
            ),
            QuickAction(
              icon: Icons.sell_outlined,
              label: 'Update prices',
              onTap: _priceDialog,
            ),
            QuickAction(
              icon: Icons.local_shipping_outlined,
              label: 'Restock list',
              onTap: () => _go(const RestockScreen()),
            ),
            QuickAction(
              icon: Icons.receipt_long_outlined,
              label: 'Orders',
              onTap: () => setState(() => _tab = 2),
            ),
            QuickAction(
              icon: Icons.storefront_outlined,
              label: 'Shop info',
              onTap: () => _go(const ShopInfoScreen()),
            ),
          ],
        ),
        SectionLabel('Best sellers', trailing: 'all time'),
        if (top.isEmpty)
          const InfoCard(
            child: Text(
              'No sale recorded yet.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        for (var i = 0; i < top.length; i++)
          InfoCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.chipBg,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(top[i].key)),
                Text(
                  '${top[i].value} sold',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        const SectionLabel('Recent activity'),
        if (repo.activity.isEmpty)
          const InfoCard(
            child: Text(
              'Your stock changes and orders will show here.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        for (final a in repo.activity.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(Icons.circle, size: 7, color: AppColors.teal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(a.text, style: const TextStyle(fontSize: 13.5)),
                ),
                const SizedBox(width: 8),
                Text(
                  _ago(a.time),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ stock

  Future<void> _priceDialog() async {
    final repo = Repo.instance;
    final categories = {
      for (final s in repo.stockOfShop(Repo.myShopId))
        repo.partById(s.partId).category,
    }.toList()
      ..sort();
    String? category;
    final percent = TextEditingController(text: '5');
    var raise = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Update prices'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Which parts?'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('All parts'),
                      selected: category == null,
                      onSelected: (_) => setLocal(() => category = null),
                    ),
                    for (final c in categories)
                      ChoiceChip(
                        label: Text(c),
                        selected: category == c,
                        onSelected: (_) => setLocal(() => category = c),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Raise')),
                    ButtonSegment(value: false, label: Text('Lower')),
                  ],
                  selected: {raise},
                  onSelectionChanged: (v) => setLocal(() => raise = v.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: percent,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Percent',
                    suffixText: '%',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    final value = double.tryParse(percent.text.replaceAll(',', '.').trim());
    percent.dispose();
    if (ok != true || value == null || value <= 0 || !mounted) return;
    final changed = repo.bulkPriceChange(
      category: category,
      percent: raise ? value : -value,
    );
    _toast(changed == 0
        ? 'No part matched'
        : 'Updated $changed price${changed == 1 ? '' : 's'}');
  }

  List<StockItem> _filteredStock(Repo repo) {
    final q = _stockSearch.text.trim().toLowerCase();
    final list = repo.stockOfShop(Repo.myShopId).where((s) {
      final part = repo.partById(s.partId);
      final okFilter = switch (_filter) {
        _StockFilter.all => true,
        _StockFilter.low =>
          s.quantity > 0 && s.quantity <= repo.lowStockLimit,
        _StockFilter.out => s.quantity <= 0,
        _StockFilter.fresh => s.condition == 'New',
        _StockFilter.used => s.condition == 'Used',
      };
      if (!okFilter) return false;
      if (q.isEmpty) return true;
      return '${part.name} ${part.oem} ${part.category}'
          .toLowerCase()
          .contains(q);
    }).toList();
    switch (_sort) {
      case _StockSort.name:
        list.sort((a, b) => repo
            .partById(a.partId)
            .name
            .compareTo(repo.partById(b.partId).name));
      case _StockSort.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
      case _StockSort.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
      case _StockSort.quantity:
        list.sort((a, b) => a.quantity.compareTo(b.quantity));
    }
    return list;
  }

  String _filterLabel(_StockFilter f) => switch (f) {
        _StockFilter.all => 'All',
        _StockFilter.low => 'Low',
        _StockFilter.out => 'Out of stock',
        _StockFilter.fresh => 'New',
        _StockFilter.used => 'Used',
      };

  Widget _stockTab(Repo repo) {
    final all = repo.stockOfShop(Repo.myShopId);
    final units = all.fold<int>(0, (a, s) => a + s.quantity);
    final items = _filteredStock(repo);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.category_outlined,
                value: '${all.length}',
                label: 'Parts listed',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.layers_outlined,
                value: '$units',
                label: 'Units in stock',
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stockSearch,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search name, serial or category',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
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
            ),
            PopupMenuButton<_StockSort>(
              tooltip: 'Sort',
              icon: const Icon(Icons.sort),
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: _StockSort.name, child: Text('Name')),
                PopupMenuItem(
                  value: _StockSort.priceLow,
                  child: Text('Price, low to high'),
                ),
                PopupMenuItem(
                  value: _StockSort.priceHigh,
                  child: Text('Price, high to low'),
                ),
                PopupMenuItem(
                  value: _StockSort.quantity,
                  child: Text('Quantity, fewest first'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in _StockFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filterLabel(f)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _go(const AddPartScreen()),
          icon: const Icon(Icons.pin_outlined),
          label: const Text('Add a part by serial number'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No part matches. Change the filter or add a part.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        for (final s in items) _stockCard(repo, s),
      ],
    );
  }

  Widget _stockCard(Repo repo, StockItem s) {
    final part = repo.partById(s.partId);
    final out = s.quantity <= 0;
    final low = !out && s.quantity <= repo.lowStockLimit;
    return InfoCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
      onTap: () => _go(StockEditScreen(part: part)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  part.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (v) {
                  if (v == 'edit') _go(StockEditScreen(part: part));
                  if (v == 'remove') _confirmRemove(repo, s, part);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit price')),
                  PopupMenuItem(value: 'remove', child: Text('Remove')),
                ],
              ),
            ],
          ),
          Text(
            'Serial ${part.oem} · ${part.category}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Pill(text: s.condition),
              const SizedBox(width: 6),
              if (out)
                const Pill(
                  text: 'Out of stock',
                  color: AppColors.danger,
                  background: AppColors.dangerBg,
                )
              else if (low)
                const Pill(
                  text: 'Low stock',
                  color: AppColors.warn,
                  background: AppColors.warnBg,
                ),
              const Spacer(),
              Text(
                '${formatDzd(s.price)} DZD',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Quantity', style: TextStyle(color: AppColors.muted)),
              const Spacer(),
              IconButton.outlined(
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove one',
                onPressed: s.quantity > 0 ? () => repo.adjustStock(s, -1) : null,
                icon: const Icon(Icons.remove, size: 18),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${s.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.outlined(
                visualDensity: VisualDensity.compact,
                tooltip: 'Add one',
                onPressed: () => repo.adjustStock(s, 1),
                icon: const Icon(Icons.add, size: 18),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(Repo repo, StockItem s, Part part) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from stock?'),
        content: Text('${part.name} will disappear from client search.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      repo.removeStock(s);
      _toast('Removed ${part.name}');
    }
  }

  // ----------------------------------------------------------------- orders

  Widget _ordersTab(Repo repo) {
    final all = repo.shopReservations();
    List<Reservation> by(String status) =>
        all.where((r) => r.status == status).toList();
    final list = by(_orderFilter);
    final pendingValue =
        by('Pending').fold<int>(0, (a, r) => a + r.item.stock.price);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          pendingValue > 0
              ? '${formatDzd(pendingValue)} DZD waiting to be confirmed.'
              : 'Clients reserve parts here. Confirm, then mark picked up.',
          style: const TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final f in const [
              'Pending',
              'Confirmed',
              'Completed',
              'Cancelled',
            ])
              ChoiceChip(
                label: Text('$f (${by(f).length})'),
                selected: _orderFilter == f,
                onSelected: (_) => setState(() => _orderFilter = f),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'Nothing here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        for (final r in list) _orderCard(repo, r),
      ],
    );
  }

  Widget _orderCard(Repo repo, Reservation r) {
    final enough = r.item.stock.quantity > 0;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.item.part.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${formatDzd(r.item.stock.price)} DZD',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${r.clientName} · ${_ago(r.createdAt)}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (r.isActive && !enough) ...[
            const SizedBox(height: 6),
            const Text(
              'You are out of stock for this part.',
              style: TextStyle(fontSize: 13, color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 10),
          if (r.status == 'Pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      repo.declineReservation(r);
                      _toast('Reservation declined');
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: enough
                        ? () {
                            repo.confirmReservation(r);
                            _toast('Confirmed. The client can come to pick it up.');
                          }
                        : null,
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            )
          else if (r.status == 'Confirmed')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => repo.declineReservation(r),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      repo.completeReservation(r);
                      _toast('Sale recorded: ${formatDzd(r.item.stock.price)} DZD');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                    ),
                    child: const Text('Picked up'),
                  ),
                ),
              ],
            )
          else if (r.status == 'Completed')
            Row(
              children: [
                const Icon(Icons.check_circle, size: 18, color: AppColors.green),
                const SizedBox(width: 6),
                Text(
                  'Sale recorded',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Cancelled',
              style: TextStyle(color: AppColors.muted),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- insights

  Future<void> _replyDialog(Repo repo, Review r) async {
    final controller = TextEditingController(text: repo.replyTo(r) ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reply to ${r.author}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Thank the client or answer politely',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Post reply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text != null) repo.setReviewReply(r, text);
  }

  Widget _insightsTab(Repo repo) {
    final views = repo.viewsByShop[Repo.myShopId] ?? 0;
    final calls = repo.callsByShop[Repo.myShopId] ?? 0;
    final reserved = repo.reservationsCountFor(Repo.myShopId);
    final reviews = repo.reviewsFor(Repo.myShopId);
    final avg = repo.averageStars(Repo.myShopId);
    final restock = [...repo.outOfStockItems, ...repo.lowStockItems];
    final top = repo.topSelling();
    final conversion = views == 0 ? 0.0 : reserved / views;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        const Text(
          'How clients interact with your shop.',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.visibility_outlined,
                value: '$views',
                label: 'Page views',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.call_outlined,
                value: '$calls',
                label: 'Calls',
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.receipt_long_outlined,
                value: '$reserved',
                label: 'Reservations',
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.star_outline,
                value: avg == null ? '-' : avg.toStringAsFixed(1),
                label: 'Rating',
                color: AppColors.star,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        InfoCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RateGauge(
                value: conversion,
                label: 'Views to orders',
                color: AppColors.orange,
              ),
              RateGauge(
                value: repo.stockOfShop(Repo.myShopId).isEmpty
                    ? 0
                    : 1 -
                        (restock.length /
                            repo.stockOfShop(Repo.myShopId).length),
                label: 'Well stocked',
                color: AppColors.green,
              ),
            ],
          ),
        ),
        const SectionLabel('Best sellers'),
        if (top.isEmpty)
          const Text(
            'No sale recorded yet.',
            style: TextStyle(color: AppColors.muted),
          ),
        for (final t in top)
          InfoCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text(t.key)),
                Text(
                  '${t.value} sold',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        SectionLabel('To restock', trailing: '${restock.length} parts'),
        if (restock.isEmpty)
          const Text(
            'Nothing running low.',
            style: TextStyle(color: AppColors.muted),
          ),
        for (final s in restock.take(4))
          InfoCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(repo.partById(s.partId).name),
              subtitle: Text(stockLabel(s.quantity)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _go(StockEditScreen(part: repo.partById(s.partId))),
            ),
          ),
        if (restock.isNotEmpty)
          TextButton(
            onPressed: () => _go(const RestockScreen()),
            child: const Text('Open the full restock list'),
          ),
        SectionLabel('Client reviews', trailing: '${reviews.length}'),
        if (reviews.isEmpty)
          const Text(
            'No review yet.',
            style: TextStyle(color: AppColors.muted),
          ),
        for (final r in reviews) ...[
          ReviewTile(review: r),
          if (repo.replyTo(r) != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 18, bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.greenBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Your reply: ${repo.replyTo(r)}',
                style: const TextStyle(fontSize: 13.5, height: 1.35),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _replyDialog(repo, r),
              icon: const Icon(Icons.reply, size: 18),
              label: Text(repo.replyTo(r) == null ? 'Reply' : 'Edit reply'),
            ),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------- shop (tab)

  Widget _shopTab(Repo repo) {
    final shop = repo.shopById(Repo.myShopId);
    final phone = repo.shopPhoneOf(shop);
    final avg = repo.averageStars(Repo.myShopId) ?? shop.rating;

    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.muted),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: const TextStyle(height: 1.3))),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        InfoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.teal,
                    child: Icon(Icons.storefront_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          shop.type,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Pill(
                    text: repo.shopOpen ? 'Open' : 'Closed',
                    color: repo.shopOpen ? AppColors.green : AppColors.danger,
                    background:
                        repo.shopOpen ? AppColors.greenBg : AppColors.dangerBg,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StarRow(stars: avg, size: 18),
                  const SizedBox(width: 8),
                  Text(avg.toStringAsFixed(1)),
                ],
              ),
              row(Icons.schedule, repo.shopHours),
              row(Icons.call_outlined, phone),
              row(Icons.info_outline, repo.shopAbout),
              row(
                Icons.local_shipping_outlined,
                repo.shopDelivers ? 'Delivery available' : 'No delivery',
              ),
              row(Icons.payments_outlined, repo.shopPayments.join(', ')),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _go(const ShopInfoScreen()),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit shop information'),
                ),
              ),
            ],
          ),
        ),
        const SectionLabel('Stock settings'),
        InfoCard(
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Low-stock limit',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'A part is "low" at this quantity or fewer',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                tooltip: 'Lower',
                onPressed: repo.lowStockLimit > 0
                    ? () => repo.setLowStockLimit(repo.lowStockLimit - 1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${repo.lowStockLimit}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Raise',
                onPressed: () => repo.setLowStockLimit(repo.lowStockLimit + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        InfoCard(
          onTap: _priceDialog,
          child: const Row(
            children: [
              Icon(Icons.sell_outlined, color: AppColors.teal),
              SizedBox(width: 12),
              Expanded(child: Text('Update prices in bulk')),
              Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
        InfoCard(
          onTap: () => _go(const RestockScreen()),
          child: const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: AppColors.teal),
              SizedBox(width: 12),
              Expanded(child: Text('Restock list for your supplier')),
              Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => logoutToRoleSelect(context),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.warn,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    final shop = repo.shopById(Repo.myShopId);
    const titles = ['Shop mode', 'Stock', 'Orders', 'Insights', 'My shop'];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tab == 0 ? '${shop.name} · Shop mode' : titles[_tab],
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: const [MessagesAction()],
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) => switch (_tab) {
          0 => _homeTab(repo),
          1 => _stockTab(repo),
          2 => _ordersTab(repo),
          3 => _insightsTab(repo),
          _ => _shopTab(repo),
        },
      ),
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: _scan,
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Scan a part'),
            )
          : null,
      bottomNavigationBar: ListenableBuilder(
        listenable: repo,
        builder: (context, _) => NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: repo.pendingOrdersCount > 0,
              label: Text('${repo.pendingOrdersCount}'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: const Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'My shop',
          ),
        ],
      ),
      ),
    );
  }
}
