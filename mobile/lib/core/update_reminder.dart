import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Play determines availability for this account, device and release track.
/// Never delays startup or interrupts a puzzle if the check finishes late.
class UpdateReminder {
  static const channel = MethodChannel('arrownova/updates');
  bool _checked = false;

  Future<void> check(
    BuildContext context, {
    required bool Function() ready,
  }) async {
    if (_checked || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _checked = true;
    int? version;
    try {
      version = await channel
          .invokeMethod<int>('check')
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      return; // Offline, unsupported install, or unavailable Play services.
    }
    if (version == null ||
        !context.mounted ||
        !ready() ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    unawaited(_markShown(version));
    final update = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        icon: const Icon(Icons.system_update_rounded),
        title: const Text('A new update is ready!'),
        content: const Text(
          'Update ArrowNova for the latest features, improvements and fixes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (update != true || !context.mounted) return;
    var opened = false;
    for (final address in [
      'market://details?id=com.epitomehub.arrownova',
      'https://play.google.com/store/apps/details?id=com.epitomehub.arrownova',
    ]) {
      try {
        opened = await launchUrl(
          Uri.parse(address),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        opened = false;
      }
      if (opened) break;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open Google Play and search for ArrowNova to update.'),
        ),
      );
    }
  }

  Future<void> _markShown(int version) async {
    try {
      await channel.invokeMethod<void>('shown', {'version': version});
    } catch (_) {
      // A reminder preference must never affect game progress.
    }
  }
}
