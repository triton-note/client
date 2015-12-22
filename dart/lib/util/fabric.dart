library triton_note.util.fabric;

import 'dart:js';

import 'package:logging/logging.dart';

final _logger = new Logger('Fabric');

_moduleMethod(moduleName, name, args) {
  final plugin = context['plugin'];
  if (plugin != null) {
    final fabric = plugin['Fabric'];
    if (fabric != null) {
      final module = fabric[moduleName];
      if (module != null) {
        module.callMethod(name, args);
        return;
      }
    }
  }
  _logger.info(() => "${moduleName}.${name}: $args");
}

class FabricCrashlytics {
  static _callMethod(name, args) => _moduleMethod('Crashlytics', name, args);

  static log(String msg) => _callMethod('log', [msg]);

  static logException(String msg) => _callMethod('logException', [msg]);

  static crash(String msg) => _callMethod('crash', [msg]);

  static setBool(String key, bool value) => _callMethod('setBool', [key, value]);

  static setDouble(String key, double value) => _callMethod('setDouble', [key, value]);

  static setFloat(String key, double value) => _callMethod('setFloat', [key, value]);

  static setInt(String key, int value) => _callMethod('setInt', [key, value]);

  static setUserIdentifier(String value) => _callMethod('setUserIdentifier', [value]);

  static setUserName(String value) => _callMethod('setUserName', [value]);

  static setUserEmail(String value) => _callMethod('setUserEmail', [value]);
}

class FabricAnswers {
  static _callMethod(name, args) => _moduleMethod('Answers', name, args);

  static eventLogin({String method, bool success, Map<String, String> custom}) => _callMethod('eventLogin', [
        new JsObject.jsify({"method": method, "success": success, "custom": custom})
      ]);

  static eventSignUp({String method, bool success, Map<String, String> custom}) => _callMethod('eventSignUp', [
        new JsObject.jsify({"method": method, "success": success, "custom": custom})
      ]);

  static eventInvite({String method, Map<String, String> custom}) => _callMethod('eventInvite', [
        new JsObject.jsify({"method": method, "custom": custom})
      ]);

  static eventLevelStart({String levelName, Map<String, String> custom}) => _callMethod('eventLevelStart', [
        new JsObject.jsify({"levelName": levelName, "custom": custom})
      ]);

  static eventLevelEnd({String levelName, bool success, Map<String, String> custom}) => _callMethod('eventLevelEnd', [
        new JsObject.jsify({"levelName": levelName, "success": success, "custom": custom})
      ]);

  static eventPurchase(
          {int itemPrice,
          String currency,
          String itemName,
          String itemType,
          String itemId,
          bool success,
          Map<String, String> custom}) =>
      _callMethod('eventPurchase', [
        new JsObject.jsify({
          "itemPrice": itemPrice,
          "currency": currency,
          "itemName": itemName,
          "itemType": itemType,
          "itemId": itemId,
          "success": success,
          "custom": custom
        })
      ]);

  static eventAddToCart(
          {int itemPrice,
          String currency,
          String itemName,
          String itemType,
          String itemId,
          Map<String, String> custom}) =>
      _callMethod('eventAddToCart', [
        new JsObject.jsify({
          "itemPrice": itemPrice,
          "currency": currency,
          "itemName": itemName,
          "itemType": itemType,
          "itemId": itemId,
          "custom": custom
        })
      ]);

  static eventStartCheckout({int totalPrice, String currency, int itemCount, Map<String, String> custom}) =>
      _callMethod('eventStartCheckout', [
        new JsObject.jsify({"totalPrice": totalPrice, "currency": currency, "itemCount": itemCount, "custom": custom})
      ]);

  static eventContentView({String contentName, String contentType, String contentId, Map<String, String> custom}) =>
      _callMethod('eventContentView', [
        new JsObject.jsify(
            {"contentName": contentName, "contentType": contentType, "contentId": contentId, "custom": custom})
      ]);

  static eventSearch({String query, Map<String, String> custom}) => _callMethod('eventSearch', [
        new JsObject.jsify({"query": query, "custom": custom})
      ]);

  static eventShare(
          {String method, String contentName, String contentType, String contentId, Map<String, String> custom}) =>
      _callMethod('eventShare', [
        new JsObject.jsify({
          "method": method,
          "contentName": contentName,
          "contentType": contentType,
          "contentId": contentId,
          "custom": custom
        })
      ]);

  static eventRating(
          {int rating, String contentName, String contentType, String contentId, Map<String, String> custom}) =>
      _callMethod('eventRating', [
        new JsObject.jsify({
          "rating": rating,
          "contentName": contentName,
          "contentType": contentType,
          "itemType": contentId,
          "custom": custom
        })
      ]);

  static eventCustom({String name, Map<String, String> attributes}) => _callMethod('eventCustom', [
        new JsObject.jsify({"name": name, "attributes": attributes})
      ]);
}
