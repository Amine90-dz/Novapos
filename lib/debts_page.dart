import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';

// ---------------- ديون الزبائن ----------------

class CustomerDebtsPage extends StatefulWidget {
  const CustomerDebtsPage({super.key});

  @override
  State<CustomerDebtsPage> createState() => _CustomerDebtsPageState();
}

class _CustomerDebtsPageState extends State<CustomerDebtsPage> {
  List<Customer> customers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await NovaStorage.getCustomers();

    if (!mounted) return;

    setState(() {
      customers = result.where((c) => c.debt > 0).toList()
        ..sort((a, b) => b.debt.compareTo(a.debt));
      loading = false;
    });
  }

  Future<void> _settle(Customer customer) async {
    final controller = TextEditingController();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تسديد دين: ${customer.name}'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'المبلغ المسدد',
                helperText:
                    'الدين الحالي: ${customer.debt.toStringAsFixed(0)} دج',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final value = double.tryParse(controller.text.trim());
                  Navigator.pop(context, value);
                },
                child: const Text('تسديد'),
              ),
            ],
          ),
        );
      },
    );

    if (amount == null || amount <= 0) return;

    final allCustomers = await NovaStorage.getCustomers();
    final index = allCustomers.indexWhere((c) => c.id == customer.id);
    if (index == -1) return;

    final newDebt = allCustomers[index].debt - amount;
    allCustomers[index].debt = newDebt < 0 ? 0 : newDebt;

    await NovaStorage.saveCustomers(allCustomers);

    if (!mounted) return;
    await _load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل التسديد')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = customers.fold<double>(0, (sum, c) => sum + c.debt);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'ديون الزبائن',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : customers.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد ديون على الزبائن',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.red.withValues(alpha: 0.08),
                        child: Text(
                          'إجمالي الديون: ${total.toStringAsFixed(0)} دج',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: customers.length,
                            itemBuilder: (context, index) {
                              final customer = customers[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(
                                    customer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(customer.phone),
                                  trailing: FilledButton(
                                    onPressed: () => _settle(customer),
                                    child: Text(
                                      '${customer.debt.toStringAsFixed(0)} دج',
                                    ),
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
}

// ---------------- ديون الموردين ----------------

class SupplierDebtsPage extends StatefulWidget {
  const SupplierDebtsPage({super.key});

  @override
  State<SupplierDebtsPage> createState() => _SupplierDebtsPageState();
}

class _SupplierDebtsPageState extends State<SupplierDebtsPage> {
  List<Supplier> suppliers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await NovaStorage.getSuppliers();

    if (!mounted) return;

    setState(() {
      suppliers = result.where((s) => s.debt > 0).toList()
        ..sort((a, b) => b.debt.compareTo(a.debt));
      loading = false;
    });
  }

  Future<void> _settle(Supplier supplier) async {
    final controller = TextEditingController();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تسديد للمورد: ${supplier.name}'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'المبلغ المسدد',
                helperText:
                    'المستحق له: ${supplier.debt.toStringAsFixed(0)} دج',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final value = double.tryParse(controller.text.trim());
                  Navigator.pop(context, value);
                },
                child: const Text('تسديد'),
              ),
            ],
          ),
        );
      },
    );

    if (amount == null || amount <= 0) return;

    final allSuppliers = await NovaStorage.getSuppliers();
    final index = allSuppliers.indexWhere((s) => s.id == supplier.id);
    if (index == -1) return;

    final newDebt = allSuppliers[index].debt - amount;
    allSuppliers[index].debt = newDebt < 0 ? 0 : newDebt;

    await NovaStorage.saveSuppliers(allSuppliers);

    if (!mounted) return;
    await _load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل التسديد')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = suppliers.fold<double>(0, (sum, s) => sum + s.debt);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'ديون الموردين',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : suppliers.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد ديون مستحقة للموردين',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.orange.withValues(alpha: 0.08),
                        child: Text(
                          'إجمالي المستحق للموردين: '
                          '${total.toStringAsFixed(0)} دج',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: suppliers.length,
                            itemBuilder: (context, index) {
                              final supplier = suppliers[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(
                                    supplier.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(supplier.phone),
                                  trailing: FilledButton(
                                    onPressed: () => _settle(supplier),
                                    child: Text(
                                      '${supplier.debt.toStringAsFixed(0)} دج',
                                    ),
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
}
