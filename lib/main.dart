import 'package:flutter/material.dart';

void main() {
  runApp(const NovaPOSApp());
}

class NovaPOSApp extends StatelessWidget {
  const NovaPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOVAPOS',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'نظام إدارة المبيعات والمخزون',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'مرحبًا بك في NOVAPOS',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _MenuCard(
                    icon: Icons.point_of_sale,
                    title: 'المبيعات',
                    onTap: () {},
                  ),
                  _MenuCard(
                    icon: Icons.inventory_2,
                    title: 'المخزون',
                    onTap: () {},
                  ),
                  _MenuCard(
                    icon: Icons.checkroom,
                    title: 'المنتجات',
                    onTap: () {},
                  ),
                  _MenuCard(
                    icon: Icons.bar_chart,
                    title: 'التقارير',
                    onTap: () {},
                  ),
                  _MenuCard(
                    icon: Icons.palette,
                    title: 'الألوان والمقاسات',
                    onTap: () {},
                  ),
                  _MenuCard(
                    icon: Icons.settings,
                    title: 'الإعدادات',
                    onTap: () {},
                  ),
                ],
              ),
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
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
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
