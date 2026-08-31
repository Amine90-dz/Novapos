import 'package:flutter/material.dart';

import 'storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String version = '1.0.0';


  Future<void> _confirmClearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف جميع البيانات'),
            content: const Text(
              'سيتم حذف كل المنتجات والزبائن والموردين والمبيعات '
              'نهائيًا. هل أنت متأكد؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف كل شيء'),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    await NovaStorage.clearAllData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف جميع البيانات')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الإعدادات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('عن التطبيق'),
                subtitle: Text('NOVAPOS — الإصدار $version'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'حذف جميع البيانات',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text(
                  'يحذف المنتجات، الزبائن، الموردين، والمبيعات نهائيًا',
                ),
                onTap: _confirmClearData,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
