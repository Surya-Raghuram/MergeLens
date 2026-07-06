import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/login_screen.dart'; // We will create this next

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://igccgemeztudfkbouzva.supabase.co', 
    publishableKey: 'sb_publishable_9cVji3rPVPjFe5zRrGJOIA_0afYwx-Z', 
  );

  runApp(const MergeLensApp());
}

class MergeLensApp extends StatelessWidget {
  const MergeLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MergeLens Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      // Check if the user is already logged in on boot
      home: Supabase.instance.client.auth.currentSession == null
          ? const LoginScreen()
          : const DashboardScreen(),
    );
  }
}