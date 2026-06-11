import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads Supabase credentials from the bundled .env file.
/// Keep real keys out of source control.
class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('YOUR_PROJECT') &&
      !anonKey.contains('YOUR_ANON_KEY');
}
