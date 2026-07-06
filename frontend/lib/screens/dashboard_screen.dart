import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/supabase_service.dart';
import 'package:frontend/models/review_report.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  ReviewReport? _selectedReport;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B), // Slate 800
        title: Text(
          '🔍 MergeLens // Engineering Control Center',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<ReviewReport>>(
        stream: _supabaseService.streamReviewReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading dashboard stats: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final reports = snapshot.data ?? [];

          return Row(
            children: [
              // Left Column: PR Activity Feed
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFF334155), width: 1)),
                  ),
                  child: ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final isSelected = _selectedReport?.id == report.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        tileColor: isSelected ? const Color(0xFF334155) : Colors.transparent,
                        title: Text(
                          '${report.repoName} [PR #${report.prNumber}]',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Status: ${report.status.toUpperCase()} • ${report.createdAt.toLocal().toString().substring(0, 16)}',
                          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                        onTap: () {
                          setState(() {
                            _selectedReport = report;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),

              // Right Column: Architectural Analysis Deep-Dive
              Expanded(
                flex: 3,
                child: _selectedReport == null
                    ? Center(
                        child: Text(
                          'Select a Pull Request report to review structural analysis details.',
                          style: GoogleFonts.inter(color: Colors.grey[500]),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: ListView(
                          children: [
                            Text(
                              'PR #${_selectedReport!.prNumber} Analysis Detail',
                              style: GoogleFonts.jetBrainsMono(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Card(
                              color: const Color(0xFF1E293B),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Architectural Summary', style: GoogleFonts.inter(fontSize: 16, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(_selectedReport!.fileChangesSummary, style: GoogleFonts.inter(color: Colors.white, height: 1.5)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('Automated Line Comments', style: GoogleFonts.jetBrainsMono(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ..._selectedReport!.structuralComments.map((comment) {
                              return Card(
                                color: const Color(0xFF1E293B),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurple,
                                    child: Text('${comment['line'] ?? 0}', style: const TextStyle(color: Colors.white)),
                                  ),
                                  title: Text(comment['comment'] ?? '', style: GoogleFonts.inter(color: Colors.white70)),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}