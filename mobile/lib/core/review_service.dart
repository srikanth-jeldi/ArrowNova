import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewService {
  ReviewService({
    Future<bool> Function()? available,
    Future<void> Function()? request,
  }) : _available = available ?? InAppReview.instance.isAvailable,
       _request = request ?? InAppReview.instance.requestReview;
  static final instance = ReviewService();
  final Future<bool> Function() _available;
  final Future<void> Function() _request;

  /// Caller never waits for this: store UI availability must not gate gameplay.
  Future<void> requestIfCurrent(bool Function() isCurrent) async {
    if (kIsWeb || !isCurrent()) return;
    try {
      if (!await _available().timeout(const Duration(seconds: 1)) ||
          !isCurrent()) {
        return;
      }
      await _request().timeout(const Duration(seconds: 10));
    } catch (_) {
      // Unsupported device, store quota, offline or plugin failure: keep playing.
    }
  }
}
