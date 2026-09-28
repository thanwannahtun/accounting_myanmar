import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfirmExitWrapper extends StatefulWidget {
  final Widget child;

  const ConfirmExitWrapper({super.key, required this.child});

  static ConfirmExitWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<ConfirmExitWrapperState>();
  }

  @override
  State<ConfirmExitWrapper> createState() => ConfirmExitWrapperState();
}

class ConfirmExitWrapperState extends State<ConfirmExitWrapper> {
  FutureOr<bool> Function()? _customPopHandler;

  void setCustomPopHandler(FutureOr<bool> Function()? handler) {
    _customPopHandler = handler;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_customPopHandler != null) {
          final handled = await _customPopHandler!();
          if (handled) return;
        }

        if (!context.mounted) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Exit App"),
              content: const Text(
                "Are you sure you want to exit Accounting Myanmar?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Oops, no"),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("See ya👋"),
                ),
              ],
            );
          },
        );

        if (shouldExit == true) {
          SystemNavigator.pop(); // Closes the app
        }
      },
      child: widget.child,
    );
  }
}
