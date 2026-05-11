import 'package:dart_frog/dart_frog.dart';
import '../../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final users = await supabase.from('user').select('id_users');
    final posts = await supabase.from('post').select('id_post');

    return Response.json(
      statusCode: 200,
      body: {
        'data': {
          'total_users': users.length,
          'total_posts': posts.length,
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
