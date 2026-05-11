import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.delete) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'error': 'Method not allowed'},
    );
  }

  final commentId = request.uri.queryParameters['comment_id'];

  if (commentId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'error': 'comment_id is required'},
    );
  }

  final commentIdInt = int.tryParse(commentId);
  if (commentIdInt == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'error': 'Invalid comment_id'},
    );
  }

  try {
    await supabase.from('comment').delete().eq('id_comments', commentIdInt);

    return Response.json(
      body: {'success': true, 'message': 'Comment deleted successfully'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'error': e.toString()},
    );
  }
}