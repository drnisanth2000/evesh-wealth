import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// Captures the browser `beforeinstallprompt` event so we can show
/// a custom "Install eVesh" banner at an appropriate moment.
///
/// Only active on web; all methods are no-ops on other platforms.
///
/// Usage:
///   PwaService.instance.initialize();
///   if (PwaService.instance.canInstall) {
///     await PwaService.instance.promptInstall();
///   }
class PwaService {
  PwaService._();
  static final PwaService instance = PwaService._();

  bool _canInstall = false;
  bool get canInstall => _canInstall && kIsWeb;

  final _installableController = StreamController<bool>.broadcast();
  Stream<bool> get onInstallabilityChanged => _installableController.stream;

  html.Event? _deferredPrompt;

  void initialize() {
    if (!kIsWeb) return;

    html.window.addEventListener('beforeinstallprompt', (html.Event event) {
      event.preventDefault();
      _deferredPrompt = event;
      _canInstall = true;
      _installableController.add(true);
    });

    html.window.addEventListener('appinstalled', (html.Event _) {
      _canInstall = false;
      _deferredPrompt = null;
      _installableController.add(false);
    });
  }

  /// Show the browser's native install prompt.
  /// Returns true if the user accepted.
  Future<bool> promptInstall() async {
    if (!kIsWeb || !_canInstall || _deferredPrompt == null) return false;

    // Cast to dynamic and call prompt() / userChoice
    final prompt = _deferredPrompt! as dynamic;
    // ignore: avoid_dynamic_calls
    prompt.prompt();

    try {
      // ignore: avoid_dynamic_calls
      final result = await (prompt.userChoice as Future);
      // ignore: avoid_dynamic_calls
      final outcome = (result as dynamic).outcome as String;
      _deferredPrompt = null;
      _canInstall = false;
      _installableController.add(false);
      return outcome == 'accepted';
    } catch (_) {
      return false;
    }
  }

  /// Returns true if running as an installed PWA in standalone mode.
  bool get isStandalone {
    if (!kIsWeb) return false;
    return html.window.matchMedia('(display-mode: standalone)').matches;
  }

  void dispose() {
    _installableController.close();
  }
}
