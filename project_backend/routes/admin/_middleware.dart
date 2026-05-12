import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';
import '../../lib/supabase_client.dart';
import '../../lib/auth_middleware.dart';

Handler middleware(Handler handler) {
  return (context) async {
    return authMiddleware().call(
      (context) async {
        final user = context.read<Map<String, dynamic>>();
        final userId = int.parse(user['id_users'].toString());
        print('DEBUG userId: $userId');
        try {
          final adminClient = SupabaseClient(
            Platform.environment['SUPABASE_URL']!,
            Platform.environment['SUPABASE_SERVICE_ROLE_KEY']!,
          );
          final isAdmin = await adminClient
              .from('admin')
              .select('id_admin')
              .eq('user_id', userId)
              .maybeSingle();
          print('DEBUG isAdmin result: $isAdmin');
          if (isAdmin == null) {
            return Response.json(
              statusCode: 403,
              body: {'error': 'Access denied - Admins only'},
            );
          }
          return handler(context);
        } catch (e) {
          print('DEBUG ERROR: $e');
          return Response.json(
            statusCode: 500,
            body: {'error': e.toString()},
          );
        }
      },
    )(context);
  };
}
