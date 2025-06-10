import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'jsonata_core.dart';
import 'jsonata_result.dart';

class Jsonata {
  late JavascriptRuntime _js;
  String? _data;
  bool _isReady = false;

  Jsonata({
    String? data,
    Map<String, dynamic>? functions,
  }) {
    _js = getJavascriptRuntime(forceJavascriptCoreOnAndroid: false);
    _data = data;

    if (functions != null) {
      _addFunctions(functions);
    }
  }

  Future<void> _initialize() async {
    if (_isReady) return;

    try {
      _js.evaluate(jsonAtaJS);
      _isReady = true;
    } catch (e) {
      throw JsonataError('Initialization failed', e);
    }
  }

  void _addFunctions(Map<String, dynamic> functions) {
    functions.forEach((name, fn) {
      _js.evaluate('''
        jsonata.registerFunction("$name", $fn);
      ''');
    });
  }

  String _cleanExpression(String expression) {
    final cleanExp = expression
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' ')
        .replaceAll(r"'", r'"');

    return cleanExp;
  }

  Future<JsonataResult> evaluate({
    required String expression,
    String? data,
  }) async {
    await _initialize();

    final sourceData = data ?? _data;
    if (sourceData == null) {
      return JsonataResult.error(JsonataError('No data provided'));
    }

    try {
      final cleanExpression = _cleanExpression(expression);
      String code = '''
        (async function() {
          try {
            var data = $sourceData;
            var expr = jsonata('$cleanExpression');
            var result = await expr.evaluate(data);
            return result === undefined ? null : result;
          } catch (err) {
            throw {
              message: err.message,
              code: err.code,
              position: err.position,
              token: err.token
            };
          }
        })();
      ''';

      final jsResult = await _js.evaluateAsync(code);
      _js.executePendingJob();
      final result = await _js.handlePromise(jsResult);

      final parsedResult = jsonDecode(result.stringResult);

      return JsonataResult.success(parsedResult);
    } catch (e) {
      return JsonataResult.error(e);
    }
  }

  Future<bool> validateExpression(String expression) async {
    final result = await evaluate(expression: expression, data: '{}');
    return result.isSuccess;
  }

  void dispose() {
    _js.dispose();
  }
}
