import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';
import 'products_page.dart';
import 'theme.dart';

enum _ProductFilter { all, bestSelling, lowStock }


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

  final TextEditingController searchController =
      TextEditingController();

  DiscountType discountType =
      DiscountType.amount;

  static const int lowStockThreshold = 5;

  _ProductFilter filter = _ProductFilter.all;
  String searchQuery = '';
  Map<String, int> soldCounts = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSoldCounts();
  }

  @override
  void dispose() {
    paidController.dispose();
    discountController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSoldCounts() async {
    final sales = await NovaStorage.getSales();
    final counts = <String, int>{};

    for (final sale in sales) {
      for (final item in sale.items) {
        counts[item.productId] =
            (counts[item.productId] ?? 0) + item.quantity;
      }
    }

    if (!mounted) return;

    setState(() {
      soldCounts = counts;
    });
  }

  List<Product> get filteredProducts {
    var result = products;

    if (filter == _ProductFilter.lowStock) {
      result =
          result.where((p) => p.quantity <= lowStockThreshold).toList();
    } else if (filter == _ProductFilter.bestSelling) {
      result = result.where((p) => (soldCounts[p.id] ?? 0) > 0).toList()
        ..sort(
          (a, b) => (soldCounts[b.id] ?? 0).compareTo(soldCounts[a.id] ?? 0),
        );
    }

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim();
      result = result
          .where(
            (p) =>
                p.name.contains(query) ||
                p.id.contains(query),
          )
          .toList();
    }

    return result;
  }

  Future<void> _loadProducts() async {
    final result = await NovaStorage.getProducts();

    if (!mounted) return;

    setState(() {
      products = result;
      loading = false;
    });
  }

  Future<void> _openAddProduct() async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddProductPage(),
      ),
    );

    if (product != null) {
      await _loadProducts();
    }
  }

  Future<void> _openEditProduct(Product product) async {
    final updated = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductPage(product: product),
      ),
    );

    if (updated != null) {
      await _loadProducts();
    }
  }

  Future<void> _openAddStock() async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد منتجات بعد، أضف منتجًا أولًا'),
        ),
      );
      return;
    }

    final selectedProduct = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'اختر المنتج',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text('${product.quantity}'),
                            ),
                            title: Text(product.name),
                            onTap: () => Navigator.pop(context, product),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedProduct == null || !mounted) return;

    final controller = TextEditingController();
    final addedQuantity = await showDialog<int>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('إضافة كمية: ${selectedProduct.name}'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'الكمية المضافة'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(controller.text.trim());
                  Navigator.pop(context, value);
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
        );
      },
    );

    if (addedQuantity == null || addedQuantity <= 0) return;

    selectedProduct.quantity += addedQuantity;
    await NovaStorage.saveProducts(products);

    if (!mounted) return;
    await _loadProducts();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة $addedQuantity إلى "${selectedProduct.name}"'),
      ),
    );
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

  Future<void> _openCheckoutDialog() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف منتجًا واحدًا على الأقل')),
      );
      return;
    }

    if (paidController.text.trim().isEmpty) {
      paidController.text = total.toStringAsFixed(0);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('إتمام البيع'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text('الإجمالي قبل الخصم'),
                          const Spacer(),
                          Text('${subtotal.toStringAsFixed(0)} دج'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: discountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'الخصم',
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<DiscountType>(
                            value: discountType,
                            items: const [
                              DropdownMenuItem(
                                value: DiscountType.amount,
                                child: Text('دج'),
                              ),
                              DropdownMenuItem(
                                value: DiscountType.percentage,
                                child: Text('%'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => discountType = value);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'الإجمالي بعد الخصم',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            '${total.toStringAsFixed(0)} دج',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: paidController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'المبلغ المدفوع',
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('المتبقي'),
                          const Spacer(),
                          Text('${remaining.toStringAsFixed(0)} دج'),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('تأكيد البيع'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      await _saveSale();
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth < 700) {
      crossAxisCount = 2;
    } else if (screenWidth < 1000) {
      crossAxisCount = 3;
    } else if (screenWidth < 1300) {
      crossAxisCount = 4;
    } else if (screenWidth < 1650) {
      crossAxisCount = 5;
    } else {
      crossAxisCount = 6;
    }

    final isWide = screenWidth >= 900;
    final visibleProducts = filteredProducts;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'نقطة البيع',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  // منطقة المنتجات (تظهر أولاً في RTL = يمين الشاشة)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: searchController,
                            onChanged: (value) {
                              setState(() => searchQuery = value);
                            },
                            decoration: const InputDecoration(
                              hintText: 'بحث بالاسم أو الباركود',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _FilterChip(
                                label: 'الكل',
                                selected: filter == _ProductFilter.all,
                                onTap: () => setState(
                                  () => filter = _ProductFilter.all,
                                ),
                              ),
                              _FilterChip(
                                label: 'الأكثر مبيعًا',
                                selected:
                                    filter == _ProductFilter.bestSelling,
                                onTap: () => setState(
                                  () => filter = _ProductFilter.bestSelling,
                                ),
                              ),
                              _FilterChip(
                                label: 'منخفض المخزون',
                                selected: filter == _ProductFilter.lowStock,
                                onTap: () => setState(
                                  () => filter = _ProductFilter.lowStock,
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: _openAddStock,
                                icon: const Icon(Icons.add_box_outlined),
                                label: const Text('إضافة كمية'),
                              ),
                              FilledButton.icon(
                                onPressed: _openAddProduct,
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة منتج'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: visibleProducts.isEmpty
                                ? const Center(
                                    child: Text(
                                      'لا توجد منتجات مطابقة',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.82,
                                    ),
                                    itemCount: visibleProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = visibleProducts[index];
                                      return _ProductGridCard(
                                        product: product,
                                        inCart: _quantityInCart(product.id),
                                        onAdd: () =>
                                            _addProductToSale(product),
                                        onEdit: () =>
                                            _openEditProduct(product),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // لوحة السلة (تظهر ثانياً في RTL = يسار الشاشة)
                  if (isWide)
                    Container(
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: _CartPanel(
                        items: items,
                        subtotal: subtotal,
                        total: total,
                        saving: saving,
                        onIncrease: _increaseItem,
                        onDecrease: _decreaseItem,
                        onRemove: _removeItem,
                        onCheckout: _openCheckoutDialog,
                      ),
                    ),
                ],
              ),
        floatingActionButton: isWide
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.85,
                        child: _CartPanel(
                          items: items,
                          subtotal: subtotal,
                          total: total,
                          saving: saving,
                          onIncrease: _increaseItem,
                          onDecrease: _decreaseItem,
                          onRemove: _removeItem,
                          onCheckout: _openCheckoutDialog,
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: Text('السلة (${items.length})'),
              ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final int inCart;
  final VoidCallback onAdd;
  final VoidCallback onEdit;

  const _ProductGridCard({
    required this.product,
    required this.inCart,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final available = product.quantity - inCart;
    final outOfStock = available <= 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: kBrandColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: kBrandColor,
                    size: 20,
                  ),
                  const Spacer(),
                  if (outOfStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBD5DA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'نفد المخزون',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB91C3C),
                        ),
                      ),
                    )
                  else
                    Text(
                      '$available متوفر',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.id,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '${product.price.toStringAsFixed(0)} دج',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.add_circle,
                    size: 20,
                    color: outOfStock ? Colors.grey : kBrandColor,
                  ),
                  onPressed: outOfStock ? null : onAdd,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  final List<SaleItem> items;
  final double subtotal;
  final double total;
  final bool saving;
  final void Function(int) onIncrease;
  final void Function(int) onDecrease;
  final void Function(int) onRemove;
  final VoidCallback onCheckout;

  const _CartPanel({
    required this.items,
    required this.subtotal,
    required this.total,
    required this.saving,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'السلة فارغة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اختر منتجًا لإضافته للبيع',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => onRemove(index),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    Text(
                                      '${item.total.toStringAsFixed(0)} دج',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 18,
                                ),
                                onPressed: () => onDecrease(index),
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                ),
                                onPressed: () => onIncrease(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      'الإجمالي',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${total.toStringAsFixed(0)} دج',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: kBrandColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: (items.isEmpty || saving) ? null : onCheckout,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.payment),
                  label: const Text('إتمام البيع'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
