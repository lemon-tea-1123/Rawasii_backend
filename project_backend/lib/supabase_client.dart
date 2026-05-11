import 'dart:io';
import 'package:supabase/supabase.dart';

late final SupabaseClient supabase;

void initSupabase() {
  final url = Platform.environment['SUPABASE_URL']!;
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY']!;
  
  supabase = SupabaseClient(
    url,
    key,
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );
}
