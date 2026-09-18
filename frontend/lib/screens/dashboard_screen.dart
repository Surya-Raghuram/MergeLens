import 'package:flutter/material.dart';
import 'package:frontend/models/review_report.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/studio/studio_shell.dart';
import 'package:frontend/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> _launchGitHubAppInstall() async {
    final Uri url =
        Uri.parse('https://github.com/apps/mergelens-studio/installations/new');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not open GitHub. Check your App URL.')),
      );
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReviewReport>>(
      stream: _supabaseService.streamReviewReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Unable to load dashboard: ${snapshot.error}'),
            ),
          );
        }

        final reports = snapshot.data ?? const <ReviewReport>[];

        return StudioShell(
          reports: reports,
          onConnectRepository: _launchGitHubAppInstall,
          onLogout: _logout,
        );
      },
    );
  }
}
