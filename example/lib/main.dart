import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jsonata_flutter/jsonata_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jsonata Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: JsonataDemo(),
    );
  }
}

class JsonataDemo extends StatefulWidget {
  const JsonataDemo({super.key});

  @override
  State<JsonataDemo> createState() => _JsonataDemoState();
}

class _JsonataDemoState extends State<JsonataDemo> {
  late Jsonata jsonata;
  String _result = '';
  String _prettyJson = '';

  @override
  void initState() {
    super.initState();
    const data = r'''
    {
      "products": [
        {
          "name": "Product 1",
          "price": 10.99,
          "category": "Category A",
          "quantity": 5
        },
        {
          "name": "Product 2",
          "price": 5.99,
          "category": "Category B",
          "quantity": 10
        },
        {
          "name": "Product 3",
          "price": 7.99,
          "category": "Category A",
          "quantity": 8
        },
        {
          "name": "Product 4",
          "price": 12.99,
          "category": "Category C",
          "quantity": 3
        }
      ]
    }
    ''';
    jsonata = Jsonata(data: data);

    final encoder = JsonEncoder.withIndent('  ');
    _prettyJson = encoder.convert(jsonDecode(data));
  }

  Future<void> _evaluateExpression(String expression) async {
    final result = await jsonata.evaluate(expression: expression);
    setState(() {
      _result = result.isError ? 'Error: ${result.error}' : '${result.data}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jsonata Flutter Demo'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                'JSON Data:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Container(
                height: 200,
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 50,
                        child: Center(
                          child: Text(
                            _prettyJson,
                            style: TextStyle(
                                fontFamily: 'monospace', fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Get product names'),
                onPressed: () => _evaluateExpression(r'$.products.(name)'),
              ),
              ElevatedButton(
                child: Text('Get products in "Category A"'),
                onPressed: () =>
                    _evaluateExpression(r'$.products[category = "Category A"]'),
              ),
              ElevatedButton(
                child: Text('Get total value of all products'),
                onPressed: () =>
                    _evaluateExpression(r'$.products.(price * quantity)^(sum)'),
              ),
              ElevatedButton(
                child: Text('Get average price of products'),
                onPressed: () => _evaluateExpression(r'$.products.price^(avg)'),
              ),
              ElevatedButton(
                child: Text('Transform products'),
                onPressed: () => _evaluateExpression(r'''
                  $.products.({
                    "productName": name,
                    "totalValue": price * quantity,
                    "isExpensive": price > 10
                  })
                '''),
              ),
              SizedBox(height: 20),
              Text(
                'Result:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Text(_result),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
