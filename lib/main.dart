import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const OrganizerApp(),
    ),
  );
}

class OrganizerApp extends StatelessWidget {
  const OrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'Органайзер',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(false),
      darkTheme: buildTheme(true),
      themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeShell(),
    );
  }
}
