import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'error': 'Method not allowed'},
    );
  }

  final postId = request.uri.queryParameters['post_id'];

  if (postId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'error': 'post_id is required'},
    );
  }

  final postIdInt = int.tryParse(postId);
  if (postIdInt == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'error': 'Invalid post_id'},
    );
  }

  try {
    final comments = await supabase
        .from('comment')
        .select('*, user:user_id(*)')
        .eq('post_id', postIdInt)
        .order('created_at', ascending: false);

    return Response.json(
      body: {'success': true, 'comments': comments},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'error': e.toString()},
    );
  }
}