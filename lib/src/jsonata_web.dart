import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:developer';

import 'jsonata_core.dart';
import 'jsonata_result.dart';

@JS('jsonata')
external _JsonataExpression _jsonata(String expression);

@JS()
@staticInterop
class _JsonataExpression {
  external factory _JsonataExpression();
}

extension _JsonataExpressionExt on _JsonataExpression {
  external JSPromise<JSAny> evaluate(JSAny input);
}

@JS('eval')
external String? _jsEval(String code);

/// Bind to JS's `JSON.parse` function, which returns a JS object/array.
@JS('JSON.parse')
external JSAny? jsJsonParse(String jsonString);

@JS('Object.keys')
external JSArray jsObjectKeys(JSObject obj);

@JS('Reflect.get')
external JSAny jsGetProperty(JSObject obj, String key);

class Jsonata {
  bool _isReady = false;
  String? _data;

  Jsonata({String? data, Map<String, dynamic>? functions}) {
    _data = data;
    if (functions != null) {
      _addFunctions(functions);
    }
  }

  Future<void> _initialize() async {
    if (_isReady) return;
    try {
      _jsEval(jsonAtaJS);
      _isReady = true;
    } catch (e) {
      throw JsonataError('Initialization failed', e);
    }
  }

  void _addFunctions(Map<String, dynamic> functions) {
    functions.forEach((name, fnSource) {
      final code = 'jsonata.registerFunction("$name", $fnSource);';
      _jsEval(code);
    });
  }

  String _cleanExpression(String expression) {
    return expression
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' ')
        .replaceAll("'", '"');
  }

  Future<JsonataResult> evaluate({required String expression, String? data}) async {
    await _initialize();

    final sourceData = data ?? _data;
    if (sourceData == null) {
      return JsonataResult.error(JsonataError('No data provided'));
    }

    try {
      final cleanExpression = _cleanExpression(expression);
      final parsedData = tryParseJsonToJsObject(sourceData);
      final exprObj = _jsonata(cleanExpression);
      if (parsedData != null) {
        final future = exprObj.evaluate(parsedData).toDart;
        final result = await future;

        return JsonataResult.success(_convertJsToDart(result));
      } else {
        return JsonataResult.error(JsonataError('Failed to pars the data'));
      }
    } catch (e) {
      return JsonataResult.error(JsonataError('Evaluation failed: $e', e));
    }
  }

  Future<bool> validateExpression(String expression) async {
    final result = await evaluate(expression: expression, data: '{}');
    return result.isSuccess;
  }

  void dispose() {}

  /// Tries to parse [raw] as JSON in Dart.
  /// If valid, returns the JS object/array via `JSON.parse`.
  /// If invalid, returns the original string.
  ///
  /// Note: We avoid `dynamic` by using `Object?`.
  JSAny? tryParseJsonToJsObject(String raw) {
    final Object decoded = json.decode(raw) as Object;
    final String reencoded = json.encode(decoded);
    return jsJsonParse(reencoded);
  }

  Object? _convertJsToDart(JSAny? jsValue) {
    if (jsValue == null) return null;

    // Convert primitives directly
    if (jsValue is JSString) return jsValue.toDart;
    if (jsValue is bool) return jsValue;
    if (jsValue is num) return jsValue;
    if (jsValue is String) return jsValue;

    // Convert JSArray to List
    if (jsValue is JSArray) {
      return jsValue.toDart.map(_convertJsToDart).toList();
    }

    // Convert JSObject to Map<String, dynamic>
    if (jsValue is JSObject) {
      final Map<String, dynamic> dartMap = {};
      final jsKeys = jsObjectKeys(jsValue).toDart;
      for (final key in jsKeys) {
        if (key is String) {
          dartMap[key as String] = _convertJsToDart(jsGetProperty(jsValue, key as String));
        } else {
          log("Something went wrong the keys cannot be none string");
        }
      }
      return dartMap;
    }

    return jsValue;
  }
}
