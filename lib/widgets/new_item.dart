import 'package:flutter/material.dart';
import 'dart:convert';
// to convert Map to json and vice versa

import 'package:http/http.dart' as http;
// as http tells flutter that all the content that is provided by the package should be bundled into http

import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});
  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  // this GlobalKey is passed in the Form() in Key. It is used to run validators of TextFormFields
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;

  var _isSending = false;
  // to show loading screen once we click add item so that buttons get frozen and another request cant be made by user if he sees screen is holding

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      // return false if anyone of the validators in the Form() failed, else true. This function kicks in when we add the button to add item to list
      _formKey.currentState!.save();
      // save only happens if validation succeeds. When it runs then the onSave: of FormFields will run
      setState(() {
        _isSending = true;
      });
      final url = Uri.https('flutter-prep-5aa55-default-rtdb.firebaseio.com',
          'shopping_list.json');
      // Basically Uri is and object which has https and in there we paste the link we got from firebase, the second 'shopping_list.json' is a name that we ourselves gave, firebase will create a node of this name
      final response = await http.post(
        // we used async and response as after POST Request we get a response and that is a future object
        url,
        headers: {
          // we are making a post req to firebase,(sending data)
          'Content-type': 'application/json',
          // it will make firebase understand how the data that we are sending will be formatted
        },
        body: json.encode(
          {
            // basically in body we pass the data as json and in encode as a map and not as an object
            'name': _enteredName,
            'quantity': _enteredQuantity,
            'category': _selectedCategory.title,
          },
        ),
      );
      final Map<String, dynamic> resData = json.decode(response.body);
      // in response we get a Map having unique keys and then Maps as values for these keys. The inner Maps will have string keys and dynamic values like string,int

      if (!context.mounted) {
        return;
        // if the context changed after POST request. Means if the widget to which this context belongs is not part of the screen anymore then we we return
      }
      Navigator.of(context).pop(
        GroceryItem(
          id: resData['name'],
          name: _enteredName,
          quantity: _enteredQuantity,
          category: _selectedCategory,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  maxLength: 50,
                  decoration: const InputDecoration(
                    label: Text('Name'),
                  ),
                  validator: (value) {
                    // it validates the input. value contains the value entered in TextFomField
                    if (value == null ||
                        value.isEmpty ||
                        value.trim().length <= 1 ||
                        value.trim().length > 50) {
                      return 'Must be between 1 and 50 characters';
                    }
                    return null;
                    // return null means value is valid
                  },
                  onSaved: (value) {
                    _enteredName = value!;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          label: Text('Quantity'),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: _enteredQuantity.toString(),
                        validator: (value) {
                          // it validates the input. value contains the value entered in TextFomField
                          if (value == null ||
                              value.isEmpty ||
                              int.tryParse(value) == null ||
                              // tryParse tries to convert string to int
                              int.tryParse(value)! <= 0) {
                            return 'Must be a valid, positive number.';
                          }
                          return null;
                          // return null means value is valid
                        },
                        onSaved: (value) {
                          _enteredQuantity = int.parse(value!);
                          // the difference between parse and tryParse is that if parse fails to convert string to number it throws error, while as tryParse shows null
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: DropdownButtonFormField(
                          value: _selectedCategory,
                          items: [
                            for (final category in categories.entries)
                              DropdownMenuItem(
                                  value: category.value,
                                  // value is used so that we know which item is selected
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        color: category.value.color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(category.value.title),
                                    ],
                                  ))
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          }),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSending
                          ? null
                          : () {
                              // freezing the buttons till we get response of POST Request
                              _formKey.currentState!.reset();
                            },
                      child: const Text('Reset'),
                    ),
                    ElevatedButton(
                      onPressed: _isSending ? null : _saveItem,
                      child: _isSending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(),
                            )
                          : const Text('Add Item'),
                    )
                  ],
                )
              ],
            )),
      ),
    );
  }
}
