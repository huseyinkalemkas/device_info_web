import 'dart:js_interop';

@JS('Reflect.get')
external JSAny? reflectGet(JSObject target, JSAny property);

@JS('Reflect.has')
external JSBoolean reflectHas(JSObject target, JSAny property);

String? jsString(JSObject object, String name) {
  final value = reflectGet(object, name.toJS);
  if (value.isA<JSString>()) {
    return (value as JSString).toDart;
  }
  return null;
}

double? jsDouble(JSAny? value) {
  if (value == null || value.isUndefined || value.isNull) return null;
  if (value.isA<JSNumber>()) return (value as JSNumber).toDartDouble;
  return null;
}

bool jsHas(JSObject object, String name) {
  return reflectHas(object, name.toJS).toDart;
}
