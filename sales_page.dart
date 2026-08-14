import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  List<Product> products = [];
  List<Sale> sales = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedProducts = await NovaStorage.getProducts();
    final loadedSales = await NovaStorage.getSales();

    if (!mounted) return;

    setState(() {
      products = loadedProducts;
      sales = loadedSales;
      loading = false;
    });
  }

  Future<void> _newSale() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewSalePage(
          products: products,
        ),
      ),
    );

    await _loadData();
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
          onPressed: _newSale,
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('بيع جديد'),
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : sales.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد مبيعات حتى الآن',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.builder(
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
                            'الإجمالي: ${sale.total.toStringAsFixed(0)} دج\n'
                            'الخصم: ${sale.discountAmount.toStringAsFixed(0)} دج\n'
                            'الربح: ${sale.profit.toStringAsFixed(0)} دج',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class NewSalePage extends StatefulWidget {
  final List<Product> products;

  const NewSalePage({
    super.key,
    required this.products,
  });

  @override
  State<NewSalePage> createState() => _NewSalePageState();
}

class _NewSalePageState extends State<NewSalePage> {
  final List<SaleItem> cart = [];

  DiscountType discountType = DiscountType.amount;

  final TextEditingController discountController =
      TextEditingController();

  final TextEditingController paidController =
      TextEditingController();

  String customerId = '';

  double get subtotal {
    return cart.fold(
      0,
      (sum, item) => sum + item.total,
    );
  }

  double get discountValue {
    return double.tryParse(
          discountController.text.trim(),
        ) ??
        0;
  }

  double get discountAmount {
    return Discount(
      type: discountType,
      value: discountValue,
    ).calculate(subtotal);
  }

  double get total {
    return subtotal - discountAmount;
  }

  double get paid {
    return double.tryParse(
          paidController.text.trim(),
        ) ??
        0;
  }

  double get remaining {
    final value = total - paid;
    return value < 0 ? 0 : value;
  }

  double get profit {
    return cart.fold(
          0,
          (sum, item) => sum + item.grossProfit,
        ) -
        discountAmount;
  }

  void _addProduct() {
    if (widget.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا توجد منتجات. أضف منتجات أولًا.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر المنتج'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];

                return ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    'سعر البيع: ${product.price.toStringAsFixed(0)} دج\n'
                    'المتوفر: ${product.quantity}',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _selectQuantity(product);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _selectQuantity(Product product) {
    final controller = TextEditingController(
      text: '1',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product.name),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'الكمية',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final quantity = int.tryParse(
                  controller.text.trim(),
                );

                if (quantity == null ||
                    quantity <= 0) {
                  return;
                }

                if (quantity > product.quantity) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'الكمية المطلوبة غير متوفرة',
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  cart.add(
                    SaleItem(
                      productId: product.id,
                      productName: product.name,
                      quantity: quantity,
                      price: product.price,
                      purchasePrice:
                          product.purchasePrice,
                      size: product.size,
                      color: product.color,
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSale() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'أضف منتجًا واحدًا على الأقل',
          ),
        ),
      );
      return;
    }

    if (discountValue < 0) {
      return;
    }

    if (paid < 0) {
      return;
    }

    if (paid > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'المبلغ المدفوع أكبر من إجمالي البيع',
          ),
        ),
      );
      return;
    }

    final allProducts =
        await NovaStorage.getProducts();

    for (final item in cart) {
      final index = allProducts.indexWhere(
        (product) => product.id == item.productId,
      );

      if (index >= 0) {
        allProducts[index].quantity -=
            item.quantity;
      }
    }

    await NovaStorage.saveProducts(allProducts);

    final sale = Sale(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      date: DateTime.now().toIso8601String(),
      customerId: customerId,
      items: List.from(cart),
      discount: Discount(
        type: discountType,
        value: discountValue,
      ),
      paid: paid,
    );

    final allSales = await NovaStorage.getSales();

    allSales.add(sale);

    await NovaStorage.saveSales(allSales);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حفظ عملية البيع بنجاح',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    discountController.dispose();
    paidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'بيع جديد',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'المنتجات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (cart.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'لم تتم إضافة أي منتج',
                    ),
                  ),
                ),
              ),

            ...cart.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final item = entry.value;

                return Card(
                  child: ListTile(
                    title: Text(
                      item.productName,
                    ),
                    subtitle: Text(
                      '${item.quantity} × '
                      '${item.price.toStringAsFixed(0)} دج\n'
                      'المقاس: ${item.size} | '
                      'اللون: ${item.color}',
                    ),
                    trailing: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          '${item.total.toStringAsFixed(0)} دج',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              cart.removeAt(index);
                            });
                          },
                          child: const Icon(
                            Icons.delete_outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: const Text(
                'إضافة منتج',
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'الخصم',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<DiscountType>(
              value: discountType,
              decoration: const InputDecoration(
                labelText: 'نوع الخصم',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: DiscountType.amount,
                  child: Text('مبلغ بالدينار'),
                ),
                DropdownMenuItem(
                  value: DiscountType.percentage,
                  child: Text('نسبة مئوية %'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  discountType = value;
                });
              },
            ),

            const SizedBox(height: 10),

            TextField(
              controller: discountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText:
                    discountType ==
                            DiscountType.percentage
                        ? 'نسبة الخصم'
                        : 'قيمة الخصم',
                suffixText:
                    discountType ==
                            DiscountType.percentage
                        ? '%'
                        : 'دج',
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'الدفع',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: paidController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                suffixText: 'دج',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _summaryRow(
                      'المجموع قبل الخصم',
                      subtotal,
                    ),
                    _summaryRow(
                      'قيمة الخصم',
                      discountAmount,
                    ),
                    const Divider(),
                    _summaryRow(
                      'المبلغ النهائي',
                      total,
                      bold: true,
                    ),
                    _summaryRow(
                      'المدفوع',
                      paid,
                    ),
                    _summaryRow(
                      'الباقي',
                      remaining,
                      bold: true,
                    ),
                    const Divider(),
                    _summaryRow(
                      'الربح',
                      profit,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 55,
              child: FilledButton.icon(
                onPressed: _saveSale,
                icon: const Icon(
                  Icons.check,
                ),
                label: const Text(
                  'حفظ البيع',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String title,
    double value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: bold ? 17 : 15,
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} دج',
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: bold ? 17 : 15,
            ),
          ),
        ],
      ),
    );
  }
}
