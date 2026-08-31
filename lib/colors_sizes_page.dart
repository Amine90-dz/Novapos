import 'package:flutter/material.dart';

import 'storage.dart';

class ColorsSizesPage extends StatefulWidget {
  const ColorsSizesPage({super.key});

  @override
  State<ColorsSizesPage> createState() => _ColorsSizesPageState();
}

class _ColorsSizesPageState extends State<ColorsSizesPage> {
  List<String> colors = [];
  List<String> sizes = [];
  bool loading = true;

  final colorController = TextEditingController();
  final sizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    colorController.dispose();
    sizeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loadedColors = await NovaStorage.getColors();
    final loadedSizes = await NovaStorage.getSizes();

    if (!mounted) return;

    setState(() {
      colors = loadedColors;
      sizes = loadedSizes;
      loading = false;
    });
  }

  Future<void> _addColor() async {
    final value = colorController.text.trim();
    if (value.isEmpty || colors.contains(value)) return;

    colors.add(value);
    await NovaStorage.saveColors(colors);
    colorController.clear();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _removeColor(String value) async {
    colors.remove(value);
    await NovaStorage.saveColors(colors);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _addSize() async {
    final value = sizeController.text.trim();
    if (value.isEmpty || sizes.contains(value)) return;

    sizes.add(value);
    await NovaStorage.saveSizes(sizes);
    sizeController.clear();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _removeSize(String value) async {
    sizes.remove(value);
    await NovaStorage.saveSizes(sizes);

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الألوان والمقاسات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'الألوان',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: colorController,
                          decoration: const InputDecoration(
                            labelText: 'إضافة لون',
                          ),
                          onSubmitted: (_) => _addColor(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: _addColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: colors
                        .map(
                          (color) => Chip(
                            label: Text(color),
                            onDeleted: () => _removeColor(color),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'المقاسات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sizeController,
                          decoration: const InputDecoration(
                            labelText: 'إضافة مقاس',
                          ),
                          onSubmitted: (_) => _addSize(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: _addSize,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sizes
                        .map(
                          (size) => Chip(
                            label: Text(size),
                            onDeleted: () => _removeSize(size),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
      ),
    );
  }
}
