library triton_note.util.fabric;

import 'dart:js';

class FabricCrashlytics {
  static log(String msg) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('log', [msg]);
  }

  static logException(String msg) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('logException', [msg]);
  }

  static crash(String msg) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('crash', [msg]);
  }

  static setBool(String key, bool value) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('setBool', [key, value]);
  }

  static setDouble(String key, double value) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('setDouble', [key, value]);
  }

  static setFloat(String key, double value) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('setFloat', [key, value]);
  }

  static setInt(String key, int value) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('setInt', [key, value]);
  }

  static setUserIdentifier(String value) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('setUserIdentifier', [value]);
  }

  static setUserName(String value) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('setUserName', [value]);
  }

  static setUserEmail(String value) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('setUserEmail', [value]);
  }
}

class FabricAnswers {
  static eventLogin({String method, bool success, Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventLogin', [
      new JsObject.jsify({"method": method, "success": success, "custom": custom})
    ]);
  }

  static eventSignUp({String method, bool success, Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventSignUp', [
      new JsObject.jsify({"method": method, "success": success, "custom": custom})
    ]);
  }

  static eventInvite({String method, Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventInvite', [
      new JsObject.jsify({"method": method, "custom": custom})
    ]);
  }

  static eventLevelStart({String levelName, Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventLevelStart', [
      new JsObject.jsify({"levelName": levelName, "custom": custom})
    ]);
  }

  static eventLevelEnd({String levelName, bool success, Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventLevelEnd', [
      new JsObject.jsify({"levelName": levelName, "success": success, "custom": custom})
    ]);
  }

  static eventPurchase(
      {int itemPrice,
      String currency,
      String itemName,
      String itemType,
      String itemId,
      bool success,
      Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventPurchase', [
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
  }

  static eventAddToCart(
      {int itemPrice, String currency, String itemName, String itemType, String itemId, Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventAddToCart', [
      new JsObject.jsify({
        "itemPrice": itemPrice,
        "currency": currency,
        "itemName": itemName,
        "itemType": itemType,
        "itemId": itemId,
        "custom": custom
      })
    ]);
  }

  static eventStartCheckout({int totalPrice, String currency, int itemCount, Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventStartCheckout', [
      new JsObject.jsify({"totalPrice": totalPrice, "currency": currency, "itemCount": itemCount, "custom": custom})
    ]);
  }

  static eventContentView({String contentName, String contentType, String contentId, Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventContentView', [
      new JsObject.jsify(
          {"contentName": contentName, "contentType": contentType, "contentId": contentId, "custom": custom})
    ]);
  }

  static eventSearch({String query, Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventSearch', [
      new JsObject.jsify({"query": query, "custom": custom})
    ]);
  }

  static eventShare(
      {String method, String contentName, String contentType, String contentId, Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventShare', [
      new JsObject.jsify({
        "method": method,
        "contentName": contentName,
        "contentType": contentType,
        "contentId": contentId,
        "custom": custom
      })
    ]);
  }

  static eventRating(
      {int rating, String contentName, String contentType, String contentId, Map<String, String> custom}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventRating', [
      new JsObject.jsify({
        "rating": rating,
        "contentName": contentName,
        "contentType": contentType,
        "itemType": contentId,
        "custom": custom
      })
    ]);
  }

  static eventCustom({String name, Map<String, String> attributes}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventCustom', [
      new JsObject.jsify({"name": name, "attributes": attributes})
    ]);
  }
}
