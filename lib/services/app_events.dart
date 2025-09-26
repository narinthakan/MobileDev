import 'dart:async';

/// Lightweight application events used to notify pages of changes that should
/// be reflected in real-time across open views (in addition to PocketBase
/// realtime). This avoids waiting for the server realtime when fast UI
/// feedback is desired.
class AppEvents {
  AppEvents._();

  static final StreamController<String> _productDeletedController = StreamController<String>.broadcast();

  /// Stream of deleted product ids (as String)
  static Stream<String> get onProductDeleted => _productDeletedController.stream;

  /// Notify listeners that a product with [id] was deleted.
  static void notifyProductDeleted(String id) {
    try {
      _productDeletedController.add(id);
    } catch (_) {}
  }

  /// Close controllers when the app shuts down (optional)
  static Future<void> dispose() async {
    await _productDeletedController.close();
  }
}
