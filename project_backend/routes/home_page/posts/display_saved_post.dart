import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

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

  final supabase = context.read<SupabaseClient>();
  final pagePosts = int.tryParse(
        context.request.uri.queryParameters['page'] ?? '1',
      ) ??
      1;
  const limitPagePosts = 10;
  final offset = (pagePosts - 1) * limitPagePosts;

  try {
    // ── join through post table — image is linked to post not save_post ──
    final savePostData = await supabase
        .from('save_post')
        .select('''
          id_save_post,
          user_id,
          post:post_id (
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
            image (
              id_image,
              image_path
            ),
            user:user_id (
              username,
              user_profile (
                full_name,
                profile_image_url
              )
            )
          )
        ''')
        .eq('user_id', idUser)
        .range(offset, offset + limitPagePosts - 1)
        .order('created_at', ascending: false);

    return Response.json(body: savePostData);
  } catch (e) {
    print('SAVED POSTS ERROR: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Failed to fetch saved posts $e'},
    );
  }
}
