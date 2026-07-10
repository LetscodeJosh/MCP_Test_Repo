import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    Provider<ApiService>(
      create: (_) => ApiService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIMS MCP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF5856D6),
        scaffoldBackgroundColor: const Color(0xFF121214),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5856D6),
          secondary: Color(0xFF30D158),
          surface: Color(0xFF1C1C1E),
          background: Color(0xFF121214),
          error: Color(0xFFFF453A),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF2F2F7)),
          bodyMedium: TextStyle(color: Color(0xFF8E8E93)),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
