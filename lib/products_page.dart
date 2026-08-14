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
          onPressed: _openAddProduct,
          icon: const Icon(Icons.add),
          label: const Text('إضافة منتج'),
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
                              'السعر: ${product.price.toStringAsFixed(0)} دج\n'
                              'المقاس: ${product.size}  |  '
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
  late final TextEditingController priceController;
  late final TextEditingController quantityController;

  String selectedSize = 'M';
  String selectedColor = 'أسود';

  bool saving = false;

  final List<String> sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
  ];

  final List<String> colors = [
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
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    final name = nameController.text.trim();
    final price = double.tryParse(
      priceController.text.trim(),
    );
    final quantity = int.tryParse(
      quantityController.text.trim(),
    );

    if (name.isEmpty ||
        price == null ||
        quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إدخال اسم المنتج والسعر والكمية بشكل صحيح',
          ),
        ),
      );
      return;
    }

    if (price < 0 || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'السعر والكمية لا يمكن أن يكونا سالبين',
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
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'السعر',
                suffixText: 'دج',
                prefixIcon: Icon(
                  Icons.attach_money,
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
                prefixIcon: Icon(Icons.numbers),
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
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
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
