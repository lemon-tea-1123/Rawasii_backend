import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_auth/dart_frog_auth.dart';
import 'supabase_client.dart';

Middleware authMiddleware() {
  return bearerAuthentication<Map<String, dynamic>>(
    authenticator: (context, token) async {
      try {
        print('DEBUG token reçu: ${token.substring(0, 20)}...');
        final user = await supabase.auth.getUser(token);
        print('DEBUG user: ${user.user}');
        if (user.user == null) return null;

        final userData = await supabase
            .from('user')
            .select('id_users, username, email, validation')
            .eq('email', user.user!.email!)
            .single();

        print('DEBUG userData: $userData');
        if (userData['validation'] == false) return null;

        return Map<String, dynamic>.from(userData);
      } catch (e) {
        print('DEBUG auth error: $e');
        return null;
      }
    },
  );
}
