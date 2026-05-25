import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/workshop_provider.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(const BengkelProApp());
}

class BengkelProApp extends StatelessWidget {
  const BengkelProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkshopProvider()),
      ],
      child: MaterialApp(
        title: 'Bengkel Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const DashboardPage(),
      ),
    );
  }
}
