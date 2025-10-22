import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: Replace with your actual Supabase project URL and anon key
  // Get these from: https://app.supabase.com/project/YOUR_PROJECT/settings/api
  static const String supabaseUrl = 'https://kyjnimuwkfrwcdbdgcyz.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5am5pbXV3a2Zyd2NkYmRnY3l6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExMTYzNzIsImV4cCI6MjA3NjY5MjM3Mn0.c8WIZiNcbOlvC0OqM9JHCwpvjiB8ev8UncAk-N_NFl0';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: false, // Set to true for debugging
    );
  }
}
