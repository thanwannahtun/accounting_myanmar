import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfirmExitWrapper extends StatelessWidget {
  final Widget child;

  const ConfirmExitWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

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
                  child: const Text("No (I want to stay!)"),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Exit (Yes I am)"),
                ),
              ],
            );
          },
        );

        if (shouldExit == true) {
          SystemNavigator.pop(); // Closes the app
        }
      },
      child: child,
    );
  }
}
