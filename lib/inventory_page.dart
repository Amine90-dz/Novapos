import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<Product> products = [];
  bool loading = true;
  static const int lowStockThreshold = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await NovaStorage.getProducts();

    if (!mounted) return;

    setState(() {
      products = result..sort((a, b) => a.quantity.compareTo(b.quantity));
      loading = false;
    });
  }

  Future<void> _adjustQuantity(Product product, int delta) async {
    final newQuantity = product.quantity + delta;
    if (newQuantity < 0) return;

    product.quantity = newQuantity;
    await NovaStorage.saveProducts(products);

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = products.fold<int>(0, (sum, p) => sum + p.quantity);
    final totalValue = products.fold<double>(
      0,
      (sum, p) => sum + (p.quantity * p.purchasePrice),
    );
    final lowStock =
        products.where((p) => p.quantity <= lowStockThreshold).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المخزون',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : products.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد منتجات في المخزون',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                'عدد القطع',
                                '$totalItems',
                                Icons.inventory_2_outlined,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _statCard(
                                'قيمة المخزون',
                                '${totalValue.toStringAsFixed(0)} دج',
                                Icons.payments_outlined,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _statCard(
                                'مخزون منخفض',
                                '$lowStock',
                                Icons.warning_amber_outlined,
                                highlight: lowStock > 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              final isLow =
                                  product.quantity <= lowStockThreshold;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isLow
                                        ? Colors.red.shade100
                                        : Colors.green.shade100,
                                    child: Text('${product.quantity}'),
                                  ),
                                  title: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'المقاس: ${product.size} | '
                                    'اللون: ${product.color}'
                                    '${isLow ? '\nمخزون منخفض' : ''}',
                                  ),
                                  isThreeLine: isLow,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed: () =>
                                            _adjustQuantity(product, -1),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        onPressed: () =>
                                            _adjustQuantity(product, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon, {
    bool highlight = false,
  }) {
    return Card(
      color: highlight ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: highlight ? Colors.red : null),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
