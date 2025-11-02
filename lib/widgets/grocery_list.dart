// grocery_list.dart (ESSENTIAL PATTERN)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  late Future<List<GroceryItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
      'shopping-list-app-840ca-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    final res = await http.get(url);
    debugPrint('GET ${url.toString()} -> ${res.statusCode} ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    if (res.body == 'null' || res.body.trim().isEmpty) {
      return []; // empty DB
    }

    final data = json.decode(res.body) as Map<String, dynamic>;
    final List<GroceryItem> loaded = [];
    data.forEach((id, value) {
      final category = categories.entries
          .firstWhere((e) => e.value.title == value['category'])
          .value;
      loaded.add(
        GroceryItem(
          id: id,
          name: value['name'],
          quantity: value['quantity'],
          category: category,
        ),
      );
    });
    return loaded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const NewItem()),
              );
              setState(() {
                _itemsFuture = _loadItems();
              });
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<GroceryItem>>(
        future: _itemsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load items:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No items yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              return Dismissible(
                key: ValueKey(item.id),
                onDismissed: (_) async {
                  final url = Uri.https(
                    'shopping-list-app-840ca-default-rtdb.firebaseio.com',
                    'shopping-list/${item.id}.json',
                  );
                  final del = await http.delete(url);
                  debugPrint('DELETE ${url.toString()} -> ${del.statusCode}');
                },
                child: ListTile(
                  title: Text(item.name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: item.category.color,
                  ),
                  trailing: Text(item.quantity.toString()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
