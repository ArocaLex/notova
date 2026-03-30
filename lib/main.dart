import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'viewmodel/auth_viewmodel.dart';
import 'viewmodel/calendar_viewmodel.dart';
import 'viewmodel/task_viewmodel.dart';
import 'viewmodel/user_viewmodel.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => TasksViewModel()),
        ChangeNotifierProvider(create: (_) => CalendarViewModel()),
      ],
      child: const NotovaApp(),
    ),
  );
}

class NotovaApp extends StatelessWidget {
  const NotovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF15111D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B2CBF),
          brightness: Brightness.dark,
        ),
        fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.manrope(color: const Color(0xFFE8DFF1)),
          bodyMedium: GoogleFonts.manrope(color: const Color(0xFFE8DFF1)),
          bodySmall: GoogleFonts.manrope(color: const Color(0xFFE8DFF1)),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
