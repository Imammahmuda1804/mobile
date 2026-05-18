import 'package:flutter/material.dart';

class AppScreenScaffold extends StatelessWidget {
  const AppScreenScaffold({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth = 720,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
