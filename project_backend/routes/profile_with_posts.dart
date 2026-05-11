import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not alloçoo kkk* wed'},
    );
  }

  final idUser = context.request.uri.queryParameters['id_users'];
  if (idUser == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'User ID is required'},
    );
  }

  final supabase = context.read<SupabaseClient>();

  // pagination
  final page =
      int.tryParse(context.request.uri.queryParameters['page'] ?? '1') ?? 1;
  const limit = 10;
  final offset = (page - 1) * limit;

  try {
    // ── run both queries in parallel ─────────────────────────────────────
    final results = await Future.wait([
      // query 1 — user info
      supabase.from('user').select('''
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
          ''').eq('id_users', idUser).single(),

      // query 2 — user posts
      supabase
          .from('post')
          .select('''
            id_post,
            user_id,
            title,
            description,
            localisation,
            historical_period,
            heritage_type,
            views_count,
            share_count,
            comment_count,
            reaction_count,
            created_at,
            updated_at,
            image(
              id_image,
              image_path
            )
          ''')
          .eq('user_id', idUser)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1),
    ]);

    final userData = results[0] as Map<String, dynamic>;
    final postsData = results[1] as List<dynamic>;

    // ── add id_users to user data since select doesn't return it ─────────
    userData['id_users'] = idUser;

    return Response.json(
      body: {
        'user': userData,
        'posts': postsData,
        'page': page,
        'count': postsData.length,
      },
    );
  } catch (e) {
    print('PROFILE WITH POSTS ERROR: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
