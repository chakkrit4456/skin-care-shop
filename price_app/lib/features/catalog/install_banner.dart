import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/pwa_install.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Compact install control beside the cart. Android downloads an APK.
/// iOS installs as a home-screen PWA.
class InstallAppButton extends StatelessWidget {
  const InstallAppButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || isStandalonePwa) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: t(context, 'install_title'),
      offset: const Offset(0, 40),
      icon: const Icon(Icons.download_rounded, size: 22),
      onSelected: (value) {
        if (value == 'ios') {
          showInstallGuide(context, ios: true);
        } else {
          downloadAndroidApk();
          showMessage(context, t(context, 'install_apk_started'));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'android',
          height: 40,
          child: _MenuLine(Icons.android, t(context, 'install_android')),
        ),
        PopupMenuItem(
          value: 'ios',
          height: 40,
          child: _MenuLine(Icons.phone_iphone, t(context, 'install_ios')),
        ),
      ],
    );
  }

}

class _MenuLine extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuLine(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: brandGreenDark),
        const SizedBox(width: 10),
        Text(label),
      ]);
}

Future<void> showInstallGuide(BuildContext context, {required bool ios}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: t(context, 'cancel'),
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, __) => Center(
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _InstallGuide(ios: ios),
        ),
      ),
    ),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

class _InstallGuide extends StatelessWidget {
  final bool ios;
  const _InstallGuide({required this.ios});

  @override
  Widget build(BuildContext context) {
    final steps = ios
        ? ['ios_step_safari', 'ios_step_share', 'ios_step_add', 'ios_step_confirm']
        : ['android_step_chrome', 'android_step_menu', 'android_step_install'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(ios ? Icons.phone_iphone : Icons.android, color: brandGreenDark),
          const SizedBox(width: 10),
          Expanded(child: Text(t(context, ios ? 'install_ios_title' : 'install_android_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 6),
        Text(t(context, ios ? 'install_ios_note' : 'install_android_note'), style: const TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 16),
        for (var i = 0; i < steps.length; i++)
          Entrance(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: brandGreenLight, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: brandGreenDark)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(t(context, steps[i]), style: const TextStyle(fontSize: 15))),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(t(context, 'got_it'))),
      ]),
    );
  }
}
