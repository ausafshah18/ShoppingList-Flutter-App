import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'dart:convert';
// to convert map to json and vice versa
import 'package:shopping_list/models/grocery_item.dart';

import 'package:http/http.dart' as http;
// as http tells flutter that all the content that is provided by the package should be bundled into http

import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  // we'll show loading initially tell we fetch items in a second or two. Once we get data we'll set it to false
  String? _error;
  // means the value of _error is String if not null

  @override
  void initState() {
    // initState is used to do initialization work.
    super.initState();
    // when we open app _loadItems() launches and sends get request to get list data
    _loadItems();
    // Basically we do GET Request only when we load the list screen and not again when we add new item. When we add new item , since we know its details we pass it over to this screen and add to list
    // Basically we did this optimization of not sending GET request upon item addition so as to avoid redundancy
  }

  void _loadItems() async {
    final url = Uri.https(
        'flutter-prep-5aa55-default-rtdb.firebaseio.com', 'shopping_list.json');
    try {
      // it will try to run the below code of function _loadItems() but if there is some error like 404 on response og GET req it goes to catch block
      final response = await http.get(url);
      // GET request

      if (response.statusCode >= 400) {
        setState(() {
          // incase of error , we won't get any response and the status will be >= 400
          _error = 'Failed to fetch data, please try again later.';
        });
      }

      if (response.body == 'null') {
        // means if no items in the list
        setState(() {
          _isLoading = false;
        });
        return;
        // we returned so that non of below _loadItems() executes
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      // in response we get a Map having unique keys and then Maps as values for these keys. The inner Maps will have string keys and dynamic values like string,int
      // basically decode json to map
      final List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        // basically we are checking which category title matches the title of category being sent by firebase. We have sent firebase title of category and not the category object, thats why this
        loadedItems.add(
          GroceryItem(
            id: item.key,
            // item.key is the auto-generated unique id provided by firebase
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
            // Basically we fetch the data and make a new GroceryItem() object
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (errr) {
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https('flutter-prep-5aa55-default-rtdb.firebaseio.com',
        'shopping_list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet.'),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
        // widget to show loading
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            // listTile is used here instead of row as it is optimized for showing list items
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Grocieries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
