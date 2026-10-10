import 'package:flutter/material.dart';

import 'core/feedback_service.dart';

/// Uses the same player, assets and volumes as gameplay.
class SoundCheck extends StatefulWidget {
  const SoundCheck({super.key, required this.haptics});
  final bool haptics;
  @override
  State<SoundCheck> createState() => _SoundCheckState();
}

class _SoundCheckState extends State<SoundCheck> with WidgetsBindingObserver {
  late final FeedbackService feedback;
  String status =
      'Use media volume. These previews play even when game sounds are off.';
  bool busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    feedback = FeedbackService(
      onError: (event, error) {
        if (mounted) setState(() => status = 'Playback error ($event): $error');
      },
    );
  }

  Future<void> preview(String event, String label) async {
    setState(() {
      busy = true;
      status = 'Preview: $label. Can you hear it?';
    });
    try {
      await feedback.stop();
      if (!mounted) return;
      await feedback.play(event, sound: true, haptics: widget.haptics);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) feedback.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Test sounds'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in const [
            ('clear', 'Arrow swipe'),
            ('blocked', 'Wrong arrow + heart'),
            ('lost', 'Last heart'),
            ('win', 'Victory applause'),
          ])
            ListTile(
              leading: const Icon(Icons.volume_up_outlined),
              title: Text(item.$2),
              enabled: !busy,
              onTap: () => preview(item.$1, item.$2),
            ),
          SelectableText(status),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}
