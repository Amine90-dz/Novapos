import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class NovaStorage {
  static const String productsKey = 'novapos_products';
  static const String customersKey = 'novapos_customers';
  static const String suppliersKey = 'novapos_suppliers';
  static const String salesKey = 'novapos_sales';
  static const String colorsKey = 'novapos_colors';
  static const String sizesKey = 'novapos_sizes';

  static Future<List<Product>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(productsKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(data);

      return list
          .map(
            (item) => Product.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveProducts(
    List<Product> products,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = products
        .map((product) => product.toMap())
        .toList();

    await prefs.setString(
      productsKey,
      jsonEncode(data),
    );
  }

  static Future<List<Customer>> getCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(customersKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(data);

      return list
          .map(
            (item) => Customer.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomers(
    List<Customer> customers,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = customers
        .map((customer) => customer.toMap())
        .toList();

    await prefs.setString(
      customersKey,
      jsonEncode(data),
    );
  }

  static Future<List<Supplier>> getSuppliers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(suppliersKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(data);

      return list
          .map(
            (item) => Supplier.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSuppliers(
    List<Supplier> suppliers,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = suppliers
        .map((supplier) => supplier.toMap())
        .toList();

    await prefs.setString(
      suppliersKey,
      jsonEncode(data),
    );
  }

  static Future<List<Sale>> getSales() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(salesKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(data);

      return list
          .map(
            (item) => Sale.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSales(
    List<Sale> sales,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = sales
        .map((sale) => sale.toMap())
        .toList();

    await prefs.setString(
      salesKey,
      jsonEncode(data),
    );
  }

  static Future<List<String>> getColors() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(colorsKey) ?? [];
  }

  static Future<void> saveColors(List<String> colors) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(colorsKey, colors);
  }

  static Future<List<String>> getSizes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(sizesKey) ?? [];
  }

  static Future<void> saveSizes(List<String> sizes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(sizesKey, sizes);
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(productsKey);
    await prefs.remove(customersKey);
    await prefs.remove(suppliersKey);
    await prefs.remove(salesKey);
    await prefs.remove(colorsKey);
    await prefs.remove(sizesKey);
  }
}
