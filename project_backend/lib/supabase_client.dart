import 'package:dotenv/dotenv.dart';
import 'package:supabase/supabase.dart';

late final SupabaseClient supabase;

void initSupabase() {
  final env = DotEnv()..load();
  supabase = SupabaseClient(
    env['SUPABASE_URL']!,
    env['SUPABASE_SERVICE_ROLE_KEY']!,
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );
}
