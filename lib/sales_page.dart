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
                              child: Icon(
                                Icons.receipt_long,
                              ),
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
            icon: const Icon(
              Icons.add_shopping_cart,
            ),
            label: const Text(
              'إضافة أول عملية بيع',
            ),
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

  DiscountType discountType =
      DiscountType.amount;

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

  int _quantityInCart(String productId) {
    return items
        .where(
          (item) => item.productId == productId,
        )
        .fold(
          0,
          (sum, item) => sum + item.quantity,
        );
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
    final value =
        double.tryParse(
          discountController.text.trim(),
        ) ??
        0;

    if (value < 0) {
      return 0;
    }

    if (discountType ==
        DiscountType.percentage) {
      if (value > 100) {
        return subtotal;
      }

      return subtotal * value / 100;
    }

    return value > subtotal ? subtotal : value;
  }

  double get total {
    final result =
        subtotal - discountValue;

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

    final selected =
        await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                      0.75,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'اختر المنتج',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder:
                          (context, index) {
                        final product =
                            products[index];

                        final alreadyInCart =
                            _quantityInCart(
                          product.id,
                        );

                        final available =
                            product.quantity -
                                alreadyInCart;

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              '$available',
                            ),
                          ),
                          title: Text(
                            product.name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'بيع: '
                            '${product.price.toStringAsFixed(0)} دج\n'
                            'شراء: '
                            '${product.purchasePrice.toStringAsFixed(0)} دج\n'
                            'المقاس: ${product.size} | '
                            'اللون: ${product.color}\n'
                            'المتاح: $available',
                          ),
                          isThreeLine: true,
                          enabled:
                              available > 0,
                          onTap: available > 0
                              ? () {
                                  Navigator.pop(
                                    context,
                                    product,
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    _addProductToSale(selected);
  }

  void _addProductToSale(
    Product product,
  ) {
    final existingIndex =
        items.indexWhere(
      (item) =>
          item.productId == product.id,
    );

    final alreadyInCart =
        _quantityInCart(product.id);

    if (alreadyInCart >=
        product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا توجد كمية إضافية من هذا المنتج',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (existingIndex >= 0) {
        final oldItem =
            items[existingIndex];

        items[existingIndex] =
            SaleItem(
          productId:
              oldItem.productId,
          productName:
              oldItem.productName,
          quantity:
              oldItem.quantity + 1,
          price: oldItem.price,
          purchasePrice:
              oldItem.purchasePrice,
          size: oldItem.size,
          color: oldItem.color,
        );
      } else {
        items.add(
          SaleItem(
            productId: product.id,
            productName: product.name,
            quantity: 1,
            price: product.price,
            purchasePrice:
                product.purchasePrice,
            size: product.size,
            color: product.color,
          ),
        );
      }
    });
  }

  void _increaseItem(int index) {
    final item = items[index];

    final product =
        _findProduct(item.productId);

    if (product == null) {
      return;
    }

    final available =
        product.quantity -
            _quantityInCart(
              product.id,
            );

    if (available <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'لا توجد كمية إضافية في المخزون',
          ),
        ),
      );
      return;
    }

    setState(() {
      items[index] = SaleItem(
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity + 1,
        price: item.price,
        purchasePrice:
            item.purchasePrice,
        size: item.size,
        color: item.color,
      );
    });
  }

  void _decreaseItem(int index) {
    final item = items[index];

    if (item.quantity <= 1) {
      setState(() {
        items.removeAt(index);
      });
      return;
    }

    setState(() {
      items[index] = SaleItem(
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity - 1,
        price: item.price,
        purchasePrice:
            item.purchasePrice,
        size: item.size,
        color: item.color,
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  Future<void> _saveSale() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'أضف منتجًا واحدًا على الأقل',
          ),
        ),
      );
      return;
    }

    if (paid < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'المبلغ المدفوع لا يمكن أن يكون سالبًا',
          ),
        ),
      );
      return;
    }

    if (paid > total) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'المبلغ المدفوع أكبر من إجمالي البيع',
          ),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final currentProducts =
        await NovaStorage.getProducts();

    for (final saleItem in items) {
      final index =
          currentProducts.indexWhere(
        (product) =>
            product.id ==
            saleItem.productId,
      );

      if (index < 0) {
        if (!mounted) return;

        setState(() {
          saving = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'المنتج "${saleItem.productName}" غير موجود',
            ),
          ),
        );

        return;
      }

      final product =
          currentProducts[index];

      if (saleItem.quantity >
          product.quantity) {
        if (!mounted) return;

        setState(() {
          saving = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'الكمية غير كافية للمنتج "${product.name}"',
            ),
          ),
        );

        return;
      }
    }

    for (final saleItem in items) {
      final index =
          currentProducts.indexWhere(
        (product) =>
            product.id ==
            saleItem.productId,
      );

      if (index >= 0) {
        currentProducts[index]
                .quantity -=
            saleItem.quantity;
      }
    }

    await NovaStorage.saveProducts(
      currentProducts,
    );

    final sales =
        await NovaStorage.getSales();

    final sale = Sale(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      date: _formatDateTime(
        DateTime.now(),
      ),
      customerId: '',
      items:
          List<SaleItem>.from(items),
      discount: Discount(
        type: discountType,
        value:
            double.tryParse(
                  discountController
                      .text
                      .trim(),
                ) ??
                0,
      ),
      paid: paid,
    );

    sales.add(sale);

    await NovaStorage.saveSales(
      sales,
    );

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'تم حفظ عملية البيع بنجاح',
        ),
      ),
    );

    await Future.delayed(
      const Duration(
        milliseconds: 400,
      ),
    );

    if (!mounted) return;

    Navigator.pop(
      context,
      sale,
    );
  }

  String _formatDateTime(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(
              2,
              '0',
            );

    final minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    return '$year/$month/$day - '
        '$hour:$minute';
  }

  Widget _summaryRow(
    String title,
    double value, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : null,
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} دج',
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'بيع جديد',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : ListView(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                children: [
                  SizedBox(
                    height: 55,
                    child:
                        FilledButton.icon(
                      onPressed: saving
                          ? null
                          : _chooseProduct,
                      icon: const Icon(
                        Icons
                            .add_shopping_cart,
                      ),
                      label: const Text(
                        'إضافة منتج للبيع',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  if (items.isEmpty)
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(24),
                        child: Column(
                          children: const [
                            Icon(
                              Icons
                                  .shopping_cart_outlined,
                              size: 60,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              'لم تتم إضافة أي منتج',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (items.isNotEmpty)
                    ...items
                        .asMap()
                        .entries
                        .map(
                      (entry) {
                        final index =
                            entry.key;
                        final item =
                            entry.value;

                        return Card(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 10,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(12),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons
                                          .shopping_bag_outlined,
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child:
                                          Text(
                                        item
                                            .productName,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize:
                                              17,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          saving
                                              ? null
                                              : () =>
                                                  _removeItem(
                                                    index,
                                                  ),
                                      icon:
                                          const Icon(
                                        Icons
                                            .delete_outline,
                                      ),
                                    ),
                                  ],
                                ),

                                Text(
                                  'المقاس: ${item.size} | '
                                  'اللون: ${item.color}',
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  'سعر البيع: '
                                  '${item.price.toStringAsFixed(0)} دج',
                                ),

                                Text(
                                  'سعر الشراء: '
                                  '${item.purchasePrice.toStringAsFixed(0)} دج',
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed:
                                              saving
                                                  ? null
                                                  : () =>
                                                      _decreaseItem(
                                                        index,
                                                      ),
                                          icon:
                                              const Icon(
                                            Icons
                                                .remove,
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                18,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed:
                                              saving
                                                  ? null
                                                  : () =>
                                                      _increaseItem(
                                                        index,
                                                      ),
                                          icon:
                                              const Icon(
                                            Icons
                                                .add,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${item.total.toStringAsFixed(0)} دج',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        fontSize:
                                            17,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(
                    height: 8,
                  ),

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .stretch,
                        children: [
                          const Text(
                            'الخصم',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 18,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child:
                                    TextField(
                                  controller:
                                      discountController,
                                  keyboardType:
                                      const TextInputType
                                          .numberWithOptions(
                                    decimal:
                                        true,
                                  ),
                                  onChanged:
                                      (_) {
                                    setState(
                                      () {},
                                    );
                                  },
                                  decoration:
                                      const InputDecoration(
                                    labelText:
                                        'قيمة الخصم',
                                    suffixText:
                                        'دج / %',
                                    border:
                                        OutlineInputBorder(),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              DropdownButton<
                                  DiscountType>(
                                value:
                                    discountType,
                                items: const [
                                  DropdownMenuItem(
                                    value:
                                        DiscountType
                                            .amount,
                                    child:
                                        Text(
                                      'مبلغ',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value:
                                        DiscountType
                                            .percentage,
                                    child:
                                        Text(
                                      'نسبة %',
                                    ),
                                  ),
                                ],
                                onChanged:
                                    (value) {
                                  if (value ==
                                      null) {
                                    return;
                                  }

                                  setState(
                                    () {
                                      discountType =
                                          value;
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(16),
                      child: Column(
                        children: [
                          _summaryRow(
                            'المجموع قبل الخصم',
                            subtotal,
                          ),
                          _summaryRow(
                            'الخصم',
                            discountValue,
                          ),
                          const Divider(),
                          _summaryRow(
                            'الإجمالي',
                            total,
                            bold: true,
                          ),
                          _summaryRow(
                            'تكلفة الشراء',
                            purchaseTotal,
                          ),
                          _summaryRow(
                            'الفائدة / الربح',
                            profit,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .stretch,
                        children: [
                          const Text(
                            'الدفع',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 18,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          TextField(
                            controller:
                                paidController,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                            ),
                            onChanged:
                                (_) {
                              setState(
                                () {},
                              );
                            },
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'المبلغ المدفوع',
                              suffixText:
                                  'دج',
                              prefixIcon:
                                  Icon(
                                Icons
                                    .payments_outlined,
                              ),
                              border:
                                  OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          _summaryRow(
                            'الباقي على الزبون',
                            remaining,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  SizedBox(
                    height: 55,
                    child:
                        FilledButton.icon(
                      onPressed: saving
                          ? null
                          : _saveSale,
                      icon: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Icon(
                              Icons.save,
                            ),
                      label: Text(
                        saving
                            ? 'جارٍ حفظ البيع...'
                            : 'حفظ عملية البيع',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
      ),
    );
  }
}
