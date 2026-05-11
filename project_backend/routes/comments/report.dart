import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'error': 'Method not allowed'},
    );
  }

  try {
    final body = await request.json() as Map<String, dynamic>;

    final commentId = body['comment_id'] as int?;
    final userId = body['user_id'] as int?;

    if (commentId == null || userId == null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'error': 'comment_id and user_id are required'},
      );
    }

    final existingReport = await supabase
        .from('reports')
        .select()
        .eq('comment_id', commentId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingReport != null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'error': 'You already reported this comment'},
      );
    }

    await supabase.from('reports').insert({
      'user_id': userId,
      'post_id': null,
      'comment_id': commentId,
      'reason': null,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });

    return Response.json(
      body: {'success': true, 'message': 'Comment reported successfully'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'error': e.toString()},
    );
  }
}