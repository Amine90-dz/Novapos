import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  List<Supplier> suppliers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final result = await NovaStorage.getSuppliers();

    if (!mounted) return;

    setState(() {
      suppliers = result;
      loading = false;
    });
  }

  Future<void> _openAddSupplier() async {
    final supplier = await Navigator.push<Supplier>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddSupplierPage(),
      ),
    );

    if (supplier != null) {
      await _loadSuppliers();
    }
  }

  Future<void> _openEditSupplier(Supplier supplier) async {
    final updated = await Navigator.push<Supplier>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSupplierPage(supplier: supplier),
      ),
    );

    if (updated != null) {
      await _loadSuppliers();
    }
  }

  Future<void> _confirmDelete(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف المورد'),
            content: Text('هل تريد حذف "${supplier.name}"؟'),
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

    suppliers.removeWhere((item) => item.id == supplier.id);
    await NovaStorage.saveSuppliers(suppliers);

    if (!mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المورد')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الموردون',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddSupplier,
          icon: const Icon(Icons.add),
          label: const Text('إضافة مورد'),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : suppliers.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh: _loadSuppliers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: suppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = suppliers[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: supplier.debt > 0
                                  ? Colors.orange.shade100
                                  : null,
                              child: const Icon(Icons.local_shipping),
                            ),
                            title: Text(
                              supplier.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${supplier.phone}\n'
                              'المستحق له: '
                              '${supplier.debt.toStringAsFixed(0)} دج',
                            ),
                            isThreeLine: true,
                            onTap: () => _openEditSupplier(supplier),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(supplier),
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
          const Icon(Icons.local_shipping_outlined, size: 80),
          const SizedBox(height: 15),
          const Text(
            'لا يوجد موردون',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openAddSupplier,
            icon: const Icon(Icons.add),
            label: const Text('إضافة أول مورد'),
          ),
        ],
      ),
    );
  }
}

class AddSupplierPage extends StatefulWidget {
  final Supplier? supplier;

  const AddSupplierPage({super.key, this.supplier});

  @override
  State<AddSupplierPage> createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends State<AddSupplierPage> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController debtController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.supplier?.name ?? '',
    );
    phoneController = TextEditingController(
      text: widget.supplier?.phone ?? '',
    );
    debtController = TextEditingController(
      text: widget.supplier != null
          ? widget.supplier!.debt.toStringAsFixed(0)
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
        const SnackBar(content: Text('الرجاء إدخال اسم المورد')),
      );
      return;
    }

    final suppliers = await NovaStorage.getSuppliers();

    final supplier = Supplier(
      id: widget.supplier?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phone: phoneController.text.trim(),
      debt: double.tryParse(debtController.text.trim()) ?? 0,
    );

    final index = suppliers.indexWhere((item) => item.id == supplier.id);

    if (index == -1) {
      suppliers.add(supplier);
    } else {
      suppliers[index] = supplier;
    }

    await NovaStorage.saveSuppliers(suppliers);

    if (!mounted) return;
    Navigator.pop(context, supplier);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplier != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'تعديل مورد' : 'إضافة مورد'),
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
                decoration: const InputDecoration(
                  labelText: 'المستحق له حالياً',
                ),
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
