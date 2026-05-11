import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod; // ← fix import

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final idUser = context.request.uri.queryParameters['id_users'];
  if (idUser == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'User ID is required'},
    );
  }

  final supabase = context.read<SupabaseClient>(); // ← fix

  try {
    final data = await supabase.from('notification').select('''
          type,
          post_id,
          comment_id,
          is_read,
          created_at,
          visit_id,
          comment_visit_id,
          user:sender_id (
            username,
            user_profile (
              full_name,
              profile_image_url
            )
          )
        ''').eq('user_id', idUser).order('created_at', ascending: false);

    return Response.json(body: data);
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
