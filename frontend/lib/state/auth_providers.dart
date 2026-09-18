import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

final authSessionProvider = StreamProvider<Session?>((ref) {
  return _supabase.auth.onAuthStateChange.map((data) => data.session);
});
