import 'package:dart_frog/dart_frog.dart';
import 'package:project_backend/supabase_client.dart';
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

  final userId = context.request.uri.queryParameters['user_id'];
  if (userId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing required field: user_id'},
    );
  }

  try {
    final followers = await supabase.from('follow').select('''
      following_user_id,
      user:following_user_id (
        id_users,
        username,
        
        user_profile(
           full_name
        )
        )
  ''').eq('followed_user_id', userId);

    return Response.json(
      body: {
        'user_id': userId,
        'followers': followers,
      },
    );
  } catch (e) {
    print(e.toString());
    return Response.json(
      statusCode: 500,
      body: {
        'error': 'An error occurred while fetching followers ${e.toString()}'
      },
    );
  }
}
