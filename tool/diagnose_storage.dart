import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

const supabaseUrl = 'https://ilfbqykxkjructxunuxm.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsZmJxeWt4a2pydWN0eHVudXhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MTkyODMsImV4cCI6MjA4MzI5NTI4M30.b3_5GkLGUlQCQI_B8XOhLUoK4YboPNn-FyhQCInZpxo';

void main() async {
  print('Initializing Supabase...');
  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

  print('Attempting to list files in "images" bucket, path "stores"...');
  try {
    final List<FileObject> objects =
        await supabase.storage.from('images').list(path: 'stores');

    if (objects.isEmpty) {
      print('No files found in "images/stores".');
      // Try listing root of images
      print('Attempting to list root of "images" bucket...');
      final rootObjects = await supabase.storage.from('images').list();
      print('Found ${rootObjects.length} files in root:');
      for (var obj in rootObjects) {
        print('- ${obj.name}');
      }
    } else {
      print('Found ${objects.length} files in "images/stores":');
      for (var obj in objects) {
        print('- ${obj.name} (Size: ${obj.metadata?['size']})');

        // Try to fetch the first one
        final publicUrl =
            supabase.storage.from('images').getPublicUrl('stores/${obj.name}');
        print('  Checking Public URL: $publicUrl');

        try {
          final response = await http.get(Uri.parse(publicUrl));
          print('  HTTP Status: ${response.statusCode}');
        } catch (e) {
          print('  HTTP Error: $e');
        }
      }
    }
  } catch (e) {
    print('FATAL ERROR listing files: $e');
    print(
        'This usually means RLS Policies are blocking "Select" or the bucket name is wrong.');
  }
}
