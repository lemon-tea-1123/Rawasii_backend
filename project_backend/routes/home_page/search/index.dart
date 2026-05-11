import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final word = context.request.uri.queryParameters['word'];
  if (word == null || word.trim().isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Search query is required'},
    );
  }

  final supabase = context.read<SupabaseClient>();
  final q = word.trim().toLowerCase();

  try {
    // ── Query both tables in parallel ─────────────────────────────────────
    final results = await Future.wait([
      // 1. Posts — search title, description, localisation,
      //            historical_period, heritage_type
      supabase
          .from('post')
          .select('''
            id_post,
            title,
            description,
            localisation,
            historical_period,
            heritage_type,
            created_at,
            reaction_count,
            comment_count,
            user_id,
            image ( image_path ),
            reaction ( user_id ),
            user:user_id (
              username,
              user_profile ( full_name, profile_image_url )
            )
          ''')
          .or(
            'title.ilike.%$q%,'
            'description.ilike.%$q%,'
            'localisation.ilike.%$q%,'
            'historical_period.ilike.%$q%,'
            'heritage_type.ilike.%$q%',
          )
          .order('created_at', ascending: false)
          .limit(30),

      // 2. Users — search username and full_name (via user_profile join)
      supabase.from('user').select('''
            id_users,
            username,
            user_profile ( full_name, profile_image_url )
            
          ''').ilike('username', '%$q%').limit(20),
    ]);

    return Response.json(body: {
      'posts': results[0],
      'users': results[1],
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
