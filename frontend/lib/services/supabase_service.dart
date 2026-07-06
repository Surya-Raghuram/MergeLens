import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/models/review_report.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Stream active code review summaries for the live feed
  Stream<List<ReviewReport>> streamReviewReports() {
    return _client
        .from('review_reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => ReviewReport.fromJson(json)).toList());
  }

  // Optional: Update repository analysis settings directly from the dashboard
  Future<void> triggerManualReReview(String reportId) async {
    await _client
        .from('review_reports')
        .update({'status': 'queued'})
        .eq('id', reportId);
  }
}