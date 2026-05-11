import 'package:dart_frog/dart_frog.dart';
import '../../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final userId = int.tryParse(id);
  if (userId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Invalid user ID'},
    );
  }

  try {
    // Basic user info
    final user = await supabase
        .from('user')
        .select(
            'id_users, username, email, validation, status, created_at, followers_count, following_count')
        .eq('id_users', userId)
        .single();

    // User profile (full_name, bio, image...)
    final profileResult = await supabase
        .from('user_profile')
        .select(
            'full_name, expertise, biography, specialties, profile_image_url')
        .eq('user_id', userId)
        .maybeSingle();

    // Posts count
    final postsResult =
        await supabase.from('post').select('id_post').eq('user_id', userId);

    // Comments count
    final commentsResult = await supabase
        .from('comment')
        .select('id_comments')
        .eq('user_id', userId);

    // Visits count
    final visitsResult =
        await supabase.from('visit').select('id_visit').eq('user_id', userId);

    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'user': {
          ...user,
          'profile': profileResult,
          'stats': {
            'posts_count': postsResult.length,
            'comments_count': commentsResult.length,
            'visits_count': visitsResult.length,
          }
        }
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
