import 'package:flutter_test/flutter_test.dart';
import 'package:jsonata_flutter/jsonata_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Jsonata jsonata;

  setUp(() {
    jsonata = Jsonata();
  });

  tearDown(() {
    jsonata.dispose();
  });

  group('Jsonata Expressions', () {
    test('Simple object access', () async {
      jsonata = Jsonata(data: '{"name": "John", "age": 30}');
      final result = await jsonata.evaluate(expression: r'$.name');
      expect(result.data, 'John');
    });

    test('Array filtering', () async {
      jsonata = Jsonata(data: '[1, 2, 3, 4, 5]');
      final result = await jsonata.evaluate(expression: r'$[$ >= 3]');
      expect(result.data, [3, 4, 5]);
    });

    test('Conditional expression', () async {
      jsonata = Jsonata(data: '{"price": 100, "quantity": 5}');
      final result = await jsonata.evaluate(
          expression: r'$.price >= 100 ? $.quantity * $.price : $.price');
      expect(result.data, 500);
    });

    test('String manipulation', () async {
      jsonata = Jsonata(data: '{"firstName": "John", "lastName": "Doe"}');
      final result =
          await jsonata.evaluate(expression: r'$.firstName & " " & $.lastName');
      expect(result.data, 'John Doe');
    });

    test('Nested object access', () async {
      jsonata = Jsonata(data: r'''
        {
          "name": "John",
          "address": {
            "street": "123 Main St",
            "city": "Anytown",
            "state": "CA",
            "zip": "12345"
          }
        }
      ''');
      final result = await jsonata.evaluate(expression: r'$.address.city');
      expect(result.data, 'Anytown');
    });

    test('Array mapping', () async {
      jsonata = Jsonata(data: r'''
        {
          "numbers": [1, 2, 3, 4, 5]
        }
      ''');
      final result = await jsonata.evaluate(expression: r'$.numbers.(10 * $)');
      expect(result.data, [10, 20, 30, 40, 50]);
    });

    test('Object transformation', () async {
      jsonata = Jsonata(data: r'''
        {
          "firstName": "John",
          "lastName": "Doe",
          "age": 30
        }
      ''');
      final result = await jsonata.evaluate(expression: r'''{
        "fullName": $.firstName & " " & $.lastName,
        "isAdult": $.age >= 18
      }''');
      expect(result.data, {"fullName": "John Doe", "isAdult": true});
    });
  });

  group('Error Handling', () {
    test('Invalid JSON data', () async {
      jsonata = Jsonata(data: 'invalid json');
      final result = await jsonata.evaluate(expression: r'$');
      expect(result.isError, true);
    });

    test('Invalid Jsonata expression', () async {
      jsonata = Jsonata(data: '{"name": "John"}');
      final result = await jsonata.evaluate(expression: r'$[');
      expect(result.isError, true);
    });

    test('Non-existent property access', () async {
      jsonata = Jsonata(data: '{"name": "John"}');
      final result = await jsonata.evaluate(expression: r'$.age');
      expect(result.data, null);
    });

    test('Division by zero', () async {
      jsonata = Jsonata(data: '{"value": 10}');
      final result = await jsonata.evaluate(expression: r'$.value / 0');
      expect(result.data, null);
    });
  });

  group('Function Registration', () {
    test('Custom function', () async {
      jsonata = Jsonata(
        data: '{"numbers": [1, 2, 3, 4, 5]}',
        functions: {
          'mySum': r'''
            function(array) {
              return array.reduce((acc, val) => acc + val, 0);
            }
          '''
        },
      );
      final result = await jsonata.evaluate(expression: r'$sum($.numbers)');
      expect(result.data, 15);
    });
  });

  group('Expression Validation', () {
    test('Valid expression', () async {
      final result = await jsonata.validateExpression(r'$.name');
      expect(result, true);
    });

    test('Invalid expression', () async {
      final result = await jsonata.validateExpression(r'$[');
      expect(result, false);
    });
  });
}
