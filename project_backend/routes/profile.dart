// profile.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod; // ← change import

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

  // ✅ get from context — same instance as middleware
  final supabase = context.read<SupabaseClient>();

  try {
    final userData = await supabase.from('user').select('''
      username,
      email,
      followers_count,
      following_count,
      user_profile(
        full_name,
        expertise,
        biography,
        specialties,
        profile_image_url
      )
    ''').eq('id_users', idUser).single();
    print('tesssts');

    return Response.json(body: userData);
  } catch (e) {
    print('PROFILE ERROR: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
