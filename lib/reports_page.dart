import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

enum _ReportRange { today, week, month, all }

class _ReportsPageState extends State<ReportsPage> {
  List<Sale> sales = [];
  bool loading = true;
  _ReportRange range = _ReportRange.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await NovaStorage.getSales();

    if (!mounted) return;

    setState(() {
      sales = result;
      loading = false;
    });
  }

  List<Sale> get _filteredSales {
    if (range == _ReportRange.all) return sales;

    final now = DateTime.now();
    DateTime cutoff;

    switch (range) {
      case _ReportRange.today:
        cutoff = DateTime(now.year, now.month, now.day);
        break;
      case _ReportRange.week:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case _ReportRange.month:
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case _ReportRange.all:
        cutoff = DateTime(2000);
        break;
    }

    return sales.where((sale) {
      final date = DateTime.tryParse(sale.date);
      if (date == null) return true;
      return date.isAfter(cutoff);
    }).toList();
  }

  Map<String, int> get _topProducts {
    final counts = <String, int>{};

    for (final sale in _filteredSales) {
      for (final item in sale.items) {
        counts[item.productName] =
            (counts[item.productName] ?? 0) + item.quantity;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {for (final e in sorted.take(5)) e.key: e.value};
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSales;

    final totalSales = filtered.fold<double>(0, (sum, s) => sum + s.total);
    final totalProfit = filtered.fold<double>(0, (sum, s) => sum + s.profit);
    final totalRemaining =
        filtered.fold<double>(0, (sum, s) => sum + s.remaining);
    final count = filtered.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'التقارير',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : sales.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد مبيعات بعد',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _rangeChip('اليوم', _ReportRange.today),
                            _rangeChip('آخر أسبوع', _ReportRange.week),
                            _rangeChip('آخر شهر', _ReportRange.month),
                            _rangeChip('الكل', _ReportRange.all),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              'عدد المبيعات',
                              '$count',
                              Icons.receipt_long_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statCard(
                              'إجمالي المبيعات',
                              '${totalSales.toStringAsFixed(0)} دج',
                              Icons.point_of_sale_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              'صافي الربح',
                              '${totalProfit.toStringAsFixed(0)} دج',
                              Icons.trending_up,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statCard(
                              'مبالغ متبقية',
                              '${totalRemaining.toStringAsFixed(0)} دج',
                              Icons.hourglass_bottom_outlined,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_topProducts.isNotEmpty) ...[
                        const Text(
                          'الأكثر مبيعًا',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Column(
                            children: _topProducts.entries
                                .map(
                                  (entry) => ListTile(
                                    title: Text(entry.key),
                                    trailing: Text('${entry.value} قطعة'),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _rangeChip(String label, _ReportRange value) {
    final selected = range == value;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => range = value),
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
