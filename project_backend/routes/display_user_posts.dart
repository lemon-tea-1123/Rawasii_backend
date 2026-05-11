import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;

  if (method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final supabase = context.read<SupabaseClient>();

  // Note: Make sure your frontend is sending ?id_users=... and not ?user_id=...
  final idUser = context.request.uri.queryParameters['id_users'];

  if (idUser == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'User ID is required'},
    );
  }

  // Pagination
  final pagePosts = int.tryParse(
        context.request.uri.queryParameters['page'] ?? '1',
      ) ??
      1;
  const limitPagePosts = 10;
  final offset = (pagePosts - 1) * limitPagePosts;

  try {
    final postData = await supabase
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
        // 🔥 FIX 1: You MUST have an order when using range in Supabase!
        .order('created_at', ascending: false)
        // 🔥 FIX 2: Range is inclusive, so this correctly gets 10 items
        .range(offset, offset + limitPagePosts - 1);

    return Response.json(
      statusCode: 200,
      body: postData,
    );
  } catch (e) {
    // 🔥 FIX 3: Better error logging so you can see the EXACT Supabase error
    print('❌ SUPABASE FETCH POSTS ERROR: $e');

    // If it's a PostgrestException, extract the helpful message
    String errorMessage = 'Failed to fetch posts';
    if (e.toString().contains('PostgrestException')) {
      // This tries to grab the actual hint from Supabase (e.g., "missing foreign key")
      errorMessage = 'Database error: ${e.toString()}';
    }

    return Response.json(
      statusCode: 500,
      body: {'error': errorMessage},
    );
  }
}
