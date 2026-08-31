import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Customer> customers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final result = await NovaStorage.getCustomers();

    if (!mounted) return;

    setState(() {
      customers = result;
      loading = false;
    });
  }

  Future<void> _openAddCustomer() async {
    final customer = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCustomerPage(),
      ),
    );

    if (customer != null) {
      await _loadCustomers();
    }
  }

  Future<void> _openEditCustomer(Customer customer) async {
    final updated = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerPage(customer: customer),
      ),
    );

    if (updated != null) {
      await _loadCustomers();
    }
  }

  Future<void> _confirmDelete(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف الزبون'),
            content: Text('هل تريد حذف "${customer.name}"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    customers.removeWhere((item) => item.id == customer.id);
    await NovaStorage.saveCustomers(customers);

    if (!mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الزبون')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الزبائن',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddCustomer,
          icon: const Icon(Icons.add),
          label: const Text('إضافة زبون'),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : customers.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh: _loadCustomers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: customer.debt > 0
                                  ? Colors.red.shade100
                                  : null,
                              child: const Icon(Icons.person),
                            ),
                            title: Text(
                              customer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${customer.phone}\n'
                              'الدين: ${customer.debt.toStringAsFixed(0)} دج',
                            ),
                            isThreeLine: true,
                            onTap: () => _openEditCustomer(customer),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(customer),
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
          const Icon(Icons.people_outline, size: 80),
          const SizedBox(height: 15),
          const Text(
            'لا يوجد زبائن',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openAddCustomer,
            icon: const Icon(Icons.add),
            label: const Text('إضافة أول زبون'),
          ),
        ],
      ),
    );
  }
}

class AddCustomerPage extends StatefulWidget {
  final Customer? customer;

  const AddCustomerPage({super.key, this.customer});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController debtController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.customer?.name ?? '',
    );
    phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );
    debtController = TextEditingController(
      text: widget.customer != null
          ? widget.customer!.debt.toStringAsFixed(0)
          : '0',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    debtController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الزبون')),
      );
      return;
    }

    final customers = await NovaStorage.getCustomers();

    final customer = Customer(
      id: widget.customer?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phone: phoneController.text.trim(),
      debt: double.tryParse(debtController.text.trim()) ?? 0,
    );

    final index = customers.indexWhere((item) => item.id == customer.id);

    if (index == -1) {
      customers.add(customer);
    } else {
      customers[index] = customer;
    }

    await NovaStorage.saveCustomers(customers);

    if (!mounted) return;
    Navigator.pop(context, customer);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'تعديل زبون' : 'إضافة زبون'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'الهاتف'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: debtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الدين الحالي'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
