import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/studio_state.dart';
import 'theme.dart';
import 'widgets/app_shell.dart';

void main() {
  runApp(const PassportPhotoStudioApp());
}

class PassportPhotoStudioApp extends StatelessWidget {
  const PassportPhotoStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudioState(),
      child: MaterialApp(
        title: 'Passport Photo Studio',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AppShell(),
      ),
    );
  }
}
