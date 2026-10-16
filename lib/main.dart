import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/app_store.dart';
import 'pages/auth_pages.dart';
import 'pages/home_shell.dart';

void main() {
  runApp(const SigapApp());
}

class SigapApp extends StatelessWidget {
  const SigapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPNVJT SIGAP',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: ListenableBuilder(
        listenable: store,
        builder: (BuildContext context, Widget? _) {
          return store.currentUser == null ? const LoginPage() : const HomeShell();
        },
      ),
    );
  }
}
