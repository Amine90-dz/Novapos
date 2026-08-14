import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NovaPosApp());
}

class NovaPosApp extends StatelessWidget {
  const NovaPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOVAPOS',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorSchemeSeed: Colors.indigo,
      ),
      home: const HomePage(),
    );
  }
}

class Product {
  String id;
  String name;
  double price;
  int quantity;
  String size;
  String color;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.size,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'size': size,
      'color': color,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'].toString(),
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      size: json['size'].toString(),
      color: json['color'].toString(),
    );
  }
}

class ProductStorage {
  static const String key = 'novapos_products';

  static Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();

    final data = products
        .map((product) => product.toJson())
        .toList();

    await prefs.setString(key, jsonEncode(data));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    ProductsPage(),
    SalesPage(),
    InventoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: pages[currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'المنتجات',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'المبيعات',
            ),
            NavigationDestination(
              icon: Icon(Icons.warehouse_outlined),
              selectedIcon: Icon(Icons.warehouse),
              label: 'المخزون',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NOVAPOS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Product>>(
        future: ProductStorage.loadProducts(),
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];

          final totalQuantity = products.fold<int>(
            0,
            (sum, product) => sum + product.quantity,
          );

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'مرحبًا بك في NOVAPOS',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'المنتجات',
                        value: '${products.length}',
                        icon: Icons.inventory_2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'الكمية',
                        value: '$totalQuantity',
                        icon: Icons.numbers,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                const Text(
                  'الوصول السريع',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _QuickButton(
                  title: 'إضافة منتج جديد',
                  icon: Icons.add_box,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddProductPage(),
                      ),
                    );
                  },
                ),
                _QuickButton(
                  title: 'عرض المنتجات',
                  icon: Icons.list_alt,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 35),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_back_ios_new, size: 18),
        onTap: onTap,
      ),
    );
  }
}

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
    load();
  }

  Future<void> load() async {
    final result = await ProductStorage.loadProducts();

    if (!mounted) return;

    setState(() {
      products = result;
      loading = false;
    });
  }

  Future<void> deleteProduct(Product product) async {
    products.removeWhere((p) => p.id == product.id);

    await ProductStorage.saveProducts(products);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف المنتج'),
      ),
    );
  }

  Future<void> openAddProduct() async {
    final result = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddProductPage(),
      ),
    );

    if (result != null) {
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المنتجات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddProduct,
        icon: const Icon(Icons.add),
        label: const Text('إضافة منتج'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? Center(
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
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: openAddProduct,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة أول منتج'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];

                      return Card(
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
                            'المقاس: ${product.size}  |  اللون: ${product.color}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final confirm =
                                  await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('حذف المنتج'),
                                  content: const Text(
                                    'هل تريد حذف هذا المنتج؟',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('إلغاء'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('حذف'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await deleteProduct(product);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();

  String selectedSize = 'M';
  String selectedColor = 'أسود';

  final sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
  ];

  final colors = [
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

  bool saving = false;

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> saveProduct() async {
    if (nameController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول'),
        ),
      );
      return;
    }

    final price =
        double.tryParse(priceController.text.trim());

    final quantity =
        int.tryParse(quantityController.text.trim());

    if (price == null || quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('السعر والكمية يجب أن يكونا أرقامًا'),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final products = await ProductStorage.loadProducts();

    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      price: price,
      quantity: quantity,
      size: selectedSize,
      color: selectedColor,
    );

    products.add(product);

    await ProductStorage.saveProducts(products);

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت إضافة المنتج بنجاح'),
      ),
    );

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة منتج'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'اسم المنتج',
              prefixIcon: Icon(Icons.shopping_bag_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'السعر',
              suffixText: 'دج',
              prefixIcon: Icon(Icons.attach_money),
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
              prefixIcon: Icon(Icons.straighten),
              border: OutlineInputBorder(),
            ),
            items: sizes
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text(size),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedSize = value;
                });
              }
            },
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: selectedColor,
            decoration: const InputDecoration(
              labelText: 'اختر اللون',
              prefixIcon: Icon(Icons.palette_outlined),
              border: OutlineInputBorder(),
            ),
            items: colors
                .map(
                  (color) => DropdownMenuItem(
                    value: color,
                    child: Text(color),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedColor = value;
                });
              }
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: saving ? null : saveProduct,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                saving ? 'جارٍ الحفظ...' : 'حفظ المنتج',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale, size: 80),
            SizedBox(height: 15),
            Text(
              'قسم المبيعات',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('سيتم تطوير الفواتير والمبيعات هنا'),
          ],
        ),
      ),
    );
  }
}

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزون'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Product>>(
        future: ProductStorage.loadProducts(),
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد بيانات للمخزون',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.warehouse),
                  title: Text(product.name),
                  subtitle: Text(
                    'المقاس: ${product.size} | اللون: ${product.color}',
                  ),
                  trailing: Text(
                    '${product.quantity}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.store),
            title: Text('إعدادات المتجر'),
            subtitle: Text('إدارة معلومات المتجر'),
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('اللغة'),
            subtitle: Text('العربية'),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('حول NOVAPOS'),
            subtitle: Text('نظام إدارة المبيعات والمخزون'),
          ),
        ],
      ),
    );
  }
}
