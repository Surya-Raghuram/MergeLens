import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes (e.g., when GitHub redirects back)
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // User logged in successfully, push to dashboard!
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    });
  }

  Future<void> _signInWithGitHub() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'http://localhost:8080', // Update to your current local Flutter port!
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e', style: const TextStyle(color: Colors.white))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MergeLens Studio',
              style: GoogleFonts.jetBrainsMono(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Autonomous Code Review Architecture',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              onPressed: _signInWithGitHub,
              icon: const Icon(Icons.code, color: Colors.black), // Placeholder for GH logo
              label: const Text('Continue with GitHub', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}