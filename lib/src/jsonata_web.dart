import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

// Import your JSONata code, error, and result classes
import 'jsonata_core.dart';
import 'jsonata_result.dart';

class Jsonata {
  bool _isReady = false;
  String? _data;

  /// If you need to pass custom functions, you can do so here,
  /// but each 'fn' must be JavaScript code (as a string) in this approach.
  Jsonata({
    String? data,
    Map<String, dynamic>? functions,
  }) {
    _data = data;
    if (functions != null) {
      _addFunctions(functions);
    }
  }

  /// Initialize the JSONata engine by evaluating the jsonAtaJS source.
  Future<void> _initialize() async {
    if (_isReady) return;

    try {
      // Evaluate the entire JSONata script in the JS context.
      js.context.callMethod('eval', [jsonAtaJS]);
      _isReady = true;
    } catch (e) {
      throw JsonataError('Initialization failed', e);
    }
  }

  /// (Optional) Register additional JS functions into JSONata.
  /// NOTE: This only works if `fn` is a valid JavaScript function as a string.
  void _addFunctions(Map<String, dynamic> functions) {
    functions.forEach((name, fn) {
      // E.g. fn might be "function(x) { return x + 1; }"
      final code = '''
        jsonata.registerFunction("$name", $fn);
      ''';
      js.context.callMethod('eval', [code]);
    });
  }

  /// Identical to your original _cleanExpression method
  /// to handle newline, spacing, and single-quote replacements.
  String _cleanExpression(String expression) {
    final cleanExp = expression
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' ')
        .replaceAll("'", '"');

    return cleanExp;
  }

  /// Main evaluate method:
  /// 1. Ensures JSONata is initialized.
  /// 2. Creates an async JS function that calls jsonata(...).evaluate(...).
  /// 3. Converts the returned Promise to a Dart Future via promiseToFuture.
  Future<JsonataResult> evaluate({
    required String expression,
    String? data,
  }) async {
    // Make sure we've loaded the JS code
    await _initialize();

    final sourceData = data ?? _data;
    if (sourceData == null) {
      return JsonataResult.error(JsonataError('No data provided'));
    }

    try {
      final cleanExpression = _cleanExpression(expression);

      // This JS snippet is an async IIFE that returns a promise
      final code = '''
                (function() {
                  return new Promise(async (resolve, reject) => {
                    try {
                      var data = $sourceData;
                      var expr = jsonata('$cleanExpression');
                      var result = await expr.evaluate(data);
                      resolve(result === undefined ? null : result);
                    } catch (err) {
                      reject({
                        message: err.message,
                        code: err.code,
                        position: err.position,
                        token: err.token
                      });
                    }
                  });
                })()
              ''';

      // Create a Completer to handle the async result
      final Completer<JsonataResult> completer = Completer<JsonataResult>();

      // Evaluate the JavaScript code
      final promise = js.context.callMethod('eval', [code]);

      if (promise != null && promise is js.JsObject) {
        promise.callMethod('then', [
          (result) {
            completer.complete(JsonataResult.success(result));
          },
          (error) {
            completer.complete(JsonataResult.error(JsonataError(error.toString())));
          }
        ]);
      } else {
        completer.complete(JsonataResult.error(JsonataError('Invalid JavaScript execution result')));
      }

      return completer.future;
    } catch (e) {
      // If the JS threw an error, or anything else went wrong
      return Future.value(JsonataResult.error(JsonataError(e.toString())));
    }
  }

  /// Validate an expression by evaluating it against empty data.
  Future<bool> validateExpression(String expression) async {
    final result = await evaluate(expression: expression, data: '{}');
    return result.isSuccess;
  }

  /// For parity with the original code; not really needed in Web.
  void dispose() {
    // No-op on Web. If you want to do anything else, do it here.
  }
}
