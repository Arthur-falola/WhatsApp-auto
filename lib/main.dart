import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auto_reply_service.dart';
import 'services/background_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundService();
  await AutoReplyService().init();
  runApp(const WhatsAutoApp());
}

class WhatsAutoApp extends StatelessWidget {
  const WhatsAutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'WhatsAuto',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF25D366),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF075E54),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF25D366),
            foregroundColor: Colors.white,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF25D366),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  final AutoReplyService _service = AutoReplyService();
  bool _isServiceRunning = false;

  bool get isServiceRunning => _isServiceRunning;
  AutoReplyService get autoReplyService => _service;

  Future<void> refresh() async {
    _isServiceRunning = await BackgroundServiceManager.isRunning();
    notifyListeners();
  }

  Future<void> toggleService() async {
    if (_isServiceRunning) {
      await BackgroundServiceManager.stop();
      await _service.setActive(false);
    } else {
      await BackgroundServiceManager.start();
      await _service.setActive(true);
    }
    _isServiceRunning = !_isServiceRunning;
    notifyListeners();
  }

  Future<void> setMode(String mode) async {
    await _service.setMode(mode);
    notifyListeners();
  }

  String get currentMode => _service.mode;
}
