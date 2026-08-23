const fs = require('fs');

fs.mkdirSync('lib/config', { recursive: true });
fs.writeFileSync(
  'lib/config/supabase_config.dart',
  `class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String publishableKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String anonKey = publishableKey;
}
`,
);
