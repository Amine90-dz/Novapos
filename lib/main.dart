import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';
import 'theme.dart';
import 'products_page.dart';
import 'sales_page.dart';
import 'inventory_page.dart';
import 'reports_page.dart';
import 'colors_sizes_page.dart';
import 'customers_page.dart';
import 'suppliers_page.dart';
import 'debts_page.dart';
import 'settings_page.dart';

void main() {
  runApp(const NovaPOSApp());
}

class NovaPOSApp extends StatelessWidget {
  const NovaPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: kBrandColor,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOVAPOS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: kBrandDark,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kBrandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kBrandColor,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: kBrandColor.withValues(alpha: 0.08),
          selectedColor: kBrandColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Color color;
  final WidgetBuilder builder;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.builder,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  double todaySales = 0;
  int lowStockCount = 0;
  double totalDebts = 0;

  static const int lowStockThreshold = 5;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final sales = await NovaStorage.getSales();
    final products = await NovaStorage.getProducts();
    final customers = await NovaStorage.getCustomers();
    final suppliers = await NovaStorage.getSuppliers();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayTotal = sales.where((sale) {
      final date = DateTime.tryParse(sale.date);
      return date != null && date.isAfter(todayStart);
    }).fold<double>(0, (sum, sale) => sum + sale.total);

    final lowStock =
        products.where((p) => p.quantity <= lowStockThreshold).length;

    final customerDebts =
        customers.fold<double>(0, (sum, c) => sum + c.debt);
    final supplierDebts =
        suppliers.fold<double>(0, (sum, s) => sum + s.debt);

    if (!mounted) return;

    setState(() {
      todaySales = todayTotal;
      lowStockCount = lowStock;
      totalDebts = customerDebts + supplierDebts;
      loading = false;
    });
  }

  List<_MenuItem> get _menuItems => [
        _MenuItem(
          icon: Icons.point_of_sale,
          title: 'المبيعات',
          color: const Color(0xFF0D9488),
          builder: (_) => const SalesPage(),
        ),
        _MenuItem(
          icon: Icons.inventory_2,
          title: 'المخزون',
          color: const Color(0xFF2563EB),
          builder: (_) => const InventoryPage(),
        ),
        _MenuItem(
          icon: Icons.checkroom,
          title: 'المنتجات',
          color: const Color(0xFF7C3AED),
          builder: (_) => const ProductsPage(),
        ),
        _MenuItem(
          icon: Icons.bar_chart,
          title: 'التقارير',
          color: const Color(0xFFDB2777),
          builder: (_) => const ReportsPage(),
        ),
        _MenuItem(
          icon: Icons.palette,
          title: 'الألوان والمقاسات',
          color: const Color(0xFFD97706),
          builder: (_) => const ColorsSizesPage(),
        ),
        _MenuItem(
          icon: Icons.people,
          title: 'الزبائن',
          color: const Color(0xFF0EA5E9),
          builder: (_) => const CustomersPage(),
        ),
        _MenuItem(
          icon: Icons.account_balance_wallet,
          title: 'ديون الزبائن',
          color: const Color(0xFFDC2626),
          builder: (_) => const CustomerDebtsPage(),
        ),
        _MenuItem(
          icon: Icons.local_shipping,
          title: 'الموردون',
          color: const Color(0xFF16A34A),
          builder: (_) => const SuppliersPage(),
        ),
        _MenuItem(
          icon: Icons.money_off,
          title: 'ديون الموردين',
          color: const Color(0xFFEA580C),
          builder: (_) => const SupplierDebtsPage(),
        ),
        _MenuItem(
          icon: Icons.settings,
          title: 'الإعدادات',
          color: const Color(0xFF475569),
          builder: (_) => const SettingsPage(),
        ),
      ];

  Future<void> _openPage(WidgetBuilder builder) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: builder),
    );
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // تصميم متجاوب: عدد الأعمدة يزداد كلما اتسعت الشاشة
    int crossAxisCount;
    if (screenWidth < 640) {
      crossAxisCount = 2;
    } else if (screenWidth < 960) {
      crossAxisCount = 3;
    } else if (screenWidth < 1280) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 5;
    }

    // عرض أقصى للمحتوى حتى لا تتمدد البطاقات بشكل مبعثر على الشاشات
    // العريضة (ويندوز/الحواسيب)
    const double maxContentWidth = 1000;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _loadStats,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: kBrandDark,
                foregroundColor: Colors.white,
                pinned: true,
                expandedHeight: 150,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 20,
                    bottom: 16,
                  ),
                  title: const Text(
                    'NOVAPOS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kBrandDark, kBrandColor],
                      ),
                    ),
                    child: const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: 20,
                          bottom: 50,
                        ),
                        child: Text(
                          'نظام إدارة المبيعات والمخزون',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: loading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'مبيعات اليوم',
                                    value:
                                        '${todaySales.toStringAsFixed(0)} دج',
                                    icon: Icons.trending_up,
                                    color: kBrandColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    label: 'مخزون منخفض',
                                    value: '$lowStockCount',
                                    icon: Icons.warning_amber_rounded,
                                    color: lowStockCount > 0
                                        ? const Color(0xFFDC2626)
                                        : kBrandColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    label: 'إجمالي الديون',
                                    value:
                                        '${totalDebts.toStringAsFixed(0)} دج',
                                    icon: Icons
                                        .account_balance_wallet_outlined,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'الوصول السريع',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.15,
                        ),
                        itemCount: _menuItems.length,
                        itemBuilder: (context, index) {
                          final item = _menuItems[index];
                          return _MenuCard(
                            icon: item.icon,
                            title: item.title,
                            color: item.color,
                            onTap: () => _openPage(item.builder),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
