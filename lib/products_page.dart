import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Product> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final result = await NovaStorage.getProducts();

    if (!mounted) return;

    setState(() {
      products = result;
      loading = false;
    });
  }

  Future<void> _deleteProduct(Product product) async {
    products.removeWhere((item) => item.id == product.id);

    await NovaStorage.saveProducts(products);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف المنتج'),
      ),
    );
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

  // يفتح قائمة منبثقة بخيارين: إضافة منتج جديد، أو إضافة كمية لمنتج موجود
  Future<void> _openAddMenu() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.add_box_outlined),
                  title: const Text('إضافة منتج جديد'),
                  onTap: () {
                    Navigator.pop(context);
                    _openAddProduct();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('إضافة كمية لمنتج موجود'),
                  onTap: () {
                    Navigator.pop(context);
                    _openAddStock();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // يفتح قائمة اختيار منتج موجود، ثم مربع حوار لإدخال الكمية المضافة
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
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
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                      ),
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
                            subtitle: Text(
                              'المقاس: ${product.size} | '
                              'اللون: ${product.color}',
                            ),
                            onTap: () {
                              Navigator.pop(context, product);
                            },
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

    if (selectedProduct == null) return;
    if (!mounted) return;

    final addedQuantity = await _askQuantityToAdd(selectedProduct);
    if (addedQuantity == null || addedQuantity <= 0) return;

    selectedProduct.quantity += addedQuantity;
    await NovaStorage.saveProducts(products);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تمت إضافة $addedQuantity إلى "${selectedProduct.name}"',
        ),
      ),
    );
  }

  // مربع حوار بسيط لإدخال الكمية المراد إضافتها للمخزون
  Future<int?> _askQuantityToAdd(Product product) async {
    final controller = TextEditingController();

    return showDialog<int>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('إضافة كمية: ${product.name}'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'الكمية المضافة',
              ),
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
  }

  Future<void> _openEditProduct(Product product) async {
    final updatedProduct = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductPage(
          product: product,
        ),
      ),
    );

    if (updatedProduct != null) {
      await _loadProducts();
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المنتج'),
          content: Text(
            'هل تريد حذف "${product.name}"؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteProduct(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المنتجات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddMenu,
          icon: const Icon(Icons.add),
          label: const Text('إضافة'),
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : products.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                '${product.quantity}',
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'سعر البيع: '
                              '${product.price.toStringAsFixed(0)} دج\n'
                              'سعر الشراء: '
                              '${product.purchasePrice.toStringAsFixed(0)} دج\n'
                              'المقاس: ${product.size} | '
                              'اللون: ${product.color}',
                            ),
                            isThreeLine: true,
                            onTap: () {
                              _openEditProduct(product);
                            },
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                              ),
                              onPressed: () {
                                _confirmDelete(product);
                              },
                            ),
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
            Icons.inventory_2_outlined,
            size: 80,
          ),
          const SizedBox(height: 15),
          const Text(
            'لا توجد منتجات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openAddProduct,
            icon: const Icon(Icons.add),
            label: const Text('إضافة أول منتج'),
          ),
        ],
      ),
    );
  }
}

class AddProductPage extends StatefulWidget {
  final Product? product;

  const AddProductPage({
    super.key,
    this.product,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  late final TextEditingController nameController;
  late final TextEditingController purchasePriceController;
  late final TextEditingController priceController;
  late final TextEditingController quantityController;

  String selectedSize = 'M';
  String selectedColor = 'أسود';

  bool saving = false;

  List<String> sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
  ];

  List<String> colors = [
    'أسود',
    'أبيض',
    'أزرق',
    'أحمر',
    'أخضر',
    'رمادي',
    'بني',
    'بيج',
    'كحلي',
  ];

  bool get editing => widget.product != null;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    nameController = TextEditingController(
      text: product?.name ?? '',
    );

    purchasePriceController = TextEditingController(
      text: product == null
          ? ''
          : product.purchasePrice.toStringAsFixed(0),
    );

    priceController = TextEditingController(
      text: product == null
          ? ''
          : product.price.toStringAsFixed(0),
    );

    quantityController = TextEditingController(
      text: product == null
          ? ''
          : product.quantity.toString(),
    );

    if (product != null) {
      selectedSize = sizes.contains(product.size)
          ? product.size
          : sizes.first;

      selectedColor = colors.contains(product.color)
          ? product.color
          : colors.first;
    }

    _loadCustomSizesColors();
  }

  // يدمج الألوان والمقاسات المخصّصة (من صفحة "الألوان والمقاسات")
  // مع القوائم الافتراضية
  Future<void> _loadCustomSizesColors() async {
    final customSizes = await NovaStorage.getSizes();
    final customColors = await NovaStorage.getColors();

    if (!mounted) return;

    setState(() {
      for (final size in customSizes) {
        if (!sizes.contains(size)) sizes.add(size);
      }
      for (final color in customColors) {
        if (!colors.contains(color)) colors.add(color);
      }

      final product = widget.product;
      if (product != null) {
        selectedSize = sizes.contains(product.size)
            ? product.size
            : sizes.first;
        selectedColor = colors.contains(product.color)
            ? product.color
            : colors.first;
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    purchasePriceController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    final name = nameController.text.trim();

    final purchasePrice = double.tryParse(
      purchasePriceController.text.trim(),
    );

    final price = double.tryParse(
      priceController.text.trim(),
    );

    final quantity = int.tryParse(
      quantityController.text.trim(),
    );

    if (name.isEmpty ||
        purchasePrice == null ||
        price == null ||
        quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إدخال اسم المنتج وسعر الشراء وسعر البيع والكمية بشكل صحيح',
          ),
        ),
      );
      return;
    }

    if (purchasePrice < 0 ||
        price < 0 ||
        quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الأسعار والكمية لا يمكن أن تكون سالبة',
          ),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final products = await NovaStorage.getProducts();

    final Product product;

    if (editing) {
      product = widget.product!;

      product.name = name;
      product.purchasePrice = purchasePrice;
      product.price = price;
      product.quantity = quantity;
      product.size = selectedSize;
      product.color = selectedColor;

      final index = products.indexWhere(
        (item) => item.id == product.id,
      );

      if (index >= 0) {
        products[index] = product;
      } else {
        products.add(product);
      }
    } else {
      product = Product(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        name: name,
        purchasePrice: purchasePrice,
        price: price,
        quantity: quantity,
        size: selectedSize,
        color: selectedColor,
      );

      products.add(product);
    }

    await NovaStorage.saveProducts(products);

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          editing
              ? 'تم تعديل المنتج بنجاح'
              : 'تمت إضافة المنتج بنجاح',
        ),
      ),
    );

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (!mounted) return;

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            editing
                ? 'تعديل المنتج'
                : 'إضافة منتج',
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج',
                prefixIcon: Icon(
                  Icons.shopping_bag_outlined,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: purchasePriceController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'سعر الشراء',
                suffixText: 'دج',
                prefixIcon: Icon(
                  Icons.shopping_cart_outlined,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'سعر البيع',
                suffixText: 'دج',
                prefixIcon: Icon(
                  Icons.sell_outlined,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الكمية',
                prefixIcon: Icon(
                  Icons.numbers,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedSize,
              decoration: const InputDecoration(
                labelText: 'اختر المقاس',
                prefixIcon: Icon(
                  Icons.straighten,
                ),
                border: OutlineInputBorder(),
              ),
              items: sizes.map((size) {
                return DropdownMenuItem<String>(
                  value: size,
                  child: Text(size),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedSize = value;
                });
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedColor,
              decoration: const InputDecoration(
                labelText: 'اختر اللون',
                prefixIcon: Icon(
                  Icons.palette_outlined,
                ),
                border: OutlineInputBorder(),
              ),
              items: colors.map((color) {
                return DropdownMenuItem<String>(
                  value: color,
                  child: Text(color),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedColor = value;
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 55,
              child: FilledButton.icon(
                onPressed: saving
                    ? null
                    : _saveProduct,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save,
                      ),
                label: Text(
                  saving
                      ? 'جارٍ الحفظ...'
                      : editing
                          ? 'حفظ التعديل'
                          : 'حفظ المنتج',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
