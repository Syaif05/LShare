// lib/shared/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final Widget? leading;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showBackButton = true,
    this.leading,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: showBackButton,
        surfaceTintColor: Colors.transparent,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
