import 'package:dart_frog/dart_frog.dart';
import 'package:project_backend/supabase_client.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method; //http request

  if (method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }
  final supabase = context.read<SupabaseClient>();
  //pagination(page number)
  final pagePosts = int.tryParse(
        context.request.uri.queryParameters['page'] ?? '1',
      ) ??
      1;
  //number of posts per page
  const limitPagePosts = 10;
  //calculate the offset for the query
  final offset = (pagePosts - 1) * limitPagePosts;
  final userId = context.request.uri.queryParameters['user_id'];
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
           ),
           user(
              username,
              user_profile(
                  full_name,
                  profile_image_url

              )
           )
           ''')
        .order('created_at', ascending: false)
        // the pagination (posts per page)
        .range(offset, offset + limitPagePosts - 1);

    // .order('created_at',ascending: false);
    return Response.json(
      body: postData,
    );
  } catch (e) {
    print('POST ERROR : $e');
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
