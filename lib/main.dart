import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const L200App());
}

class L200App extends StatelessWidget {
  const L200App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'L200 Sport',
      theme: AppTheme.dark,
      home: const DashboardScreen(),
    );
  }
}
