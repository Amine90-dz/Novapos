import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  List<Sale> sales = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    final result = await NovaStorage.getSales();

    if (!mounted) return;

    setState(() {
      sales = result;
      loading = false;
    });
  }

  Future<void> _openNewSale() async {
    final sale = await Navigator.push<Sale>(
      context,
      MaterialPageRoute(
        builder: (_) => const NewSalePage(),
      ),
    );

    if (sale != null) {
      await _loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المبيعات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openNewSale,
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('بيع جديد'),
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : sales.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh: _loadSales,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: sales.length,
                      itemBuilder: (context, index) {
                        final sale = sales[index];

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.receipt_long),
                            ),
                            title: Text(
                              'بيع رقم ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'التاريخ: ${sale.date}\n'
                              'الإجمالي: '
                              '${sale.total.toStringAsFixed(0)} دج\n'
                              'الربح: '
                              '${sale.profit.toStringAsFixed(0)} دج',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.point_of_sale_outlined,
            size: 80,
          ),
          const SizedBox(height: 15),
          const Text(
            'لا توجد مبيعات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openNewSale,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('إضافة أول عملية بيع'),
          ),
        ],
      ),
    );
  }
}

class NewSalePage extends StatefulWidget {
  const NewSalePage({super.key});

  @override
  State<NewSalePage> createState() => _NewSalePageState();
}

class _NewSalePageState extends State<NewSalePage> {
  List<Product> products = [];
  List<SaleItem> items = [];

  bool loading = true;
  bool saving = false;

  final TextEditingController paidController =
      TextEditingController();

  final TextEditingController discountController =
      TextEditingController();

  DiscountType discountType = DiscountType.amount;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    paidController.dispose();
    discountController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final result = await NovaStorage.getProducts();

    if (!mounted) return;

    setState(() {
      products = result;
      loading = false;
    });
  }

  Product? _findProduct(String id) {
    for (final product in products) {
      if (product.id == id) {
        return product;
      }
    }

    return null;
  }

  double get subtotal {
    return items.fold(
      0,
      (sum, item) => sum + item.total,
    );
  }

  double get purchaseTotal {
    return items.fold(
      0,
      (sum, item) => sum + item.purchaseTotal,
    );
  }

  double get discountValue {
    final value = double.tryParse(
          discountController.text.trim(),
        ) ??
        0;

    if (discountType == DiscountType.percentage) {
      return subtotal * value / 100;
    }

    return value > subtotal ? subtotal : value;
  }

  double get total {
    final result = subtotal - discountValue;
    return result < 0 ? 0 : result;
  }

  double get profit {
    return total - purchaseTotal;
  }

  double get paid {
    return double.tryParse(
          paidController.text.trim(),
        ) ??
        0;
  }

  double get remaining {
    final result = total - paid;
    return result < 0 ? 0 : result;
  }

  Future<void> _chooseProduct() async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا توجد منتجات في المخزون',
          ),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'اختر المنتج',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                     
